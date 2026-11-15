import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import Vision

let a4Portrait = CGSize(width: 595.28, height: 841.89)
let a4LongToShort = a4Portrait.height / a4Portrait.width
let a4ShapeTolerance = 0.05
let edgeTrim = 0.006
let jpegQuality = 0.85
let textCheckMaxPixels: CGFloat = 1600
let minTextCharacters = 20

struct Options {
    var photos: [String] = []
    var clockwise: Int?
    var keepBackground = false
}

struct ToolError: Error, CustomStringConvertible {
    let description: String
}

func usage() -> Never {
    print("""
    usage: photo-to-pdf <photo>... [--rotate 0|90|180|270] [--keep-background]

    Writes <photo name>.pdf next to each photo: one A4 page, text upright,
    background cut away, paper made flat.

      --rotate N         turn every photo N degrees clockwise instead of guessing from the text
      --keep-background  keep the whole photo; use it when the paper is not found
    """)
    exit(2)
}

func parseOptions() -> Options {
    var options = Options()
    var args = CommandLine.arguments.dropFirst()
    while let arg = args.popFirst() {
        switch arg {
        case "--rotate":
            guard let value = args.popFirst().flatMap({ Int($0) }), [0, 90, 180, 270].contains(value) else { usage() }
            options.clockwise = value
        case "--keep-background":
            options.keepBackground = true
        case "-h", "--help":
            usage()
        default:
            if arg.hasPrefix("-") { usage() }
            options.photos.append(arg)
        }
    }
    if options.photos.isEmpty { usage() }
    return options
}

func loadAsDisplayed(_ path: String) throws -> CIImage {
    // Phone photos keep the sensor's pixel order plus an orientation tag; the thumbnail call is the ImageIO way to apply that tag.
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let width = props[kCGImagePropertyPixelWidth] as? Int,
          let height = props[kCGImagePropertyPixelHeight] as? Int,
          let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
              kCGImageSourceCreateThumbnailFromImageAlways: true,
              kCGImageSourceCreateThumbnailWithTransform: true,
              kCGImageSourceThumbnailMaxPixelSize: max(width, height),
          ] as CFDictionary)
    else { throw ToolError(description: "cannot read the photo") }
    return CIImage(cgImage: image)
}

// A rotation matrix built from an angle leaves tiny rounding errors, which add a one-pixel line at the edge.
func turned(_ image: CIImage, clockwise degrees: Int) -> CIImage {
    let w = image.extent.width
    let h = image.extent.height
    let transform: CGAffineTransform
    switch degrees {
    case 90: transform = CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: w)
    case 180: transform = CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: w, ty: h)
    case 270: transform = CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: h, ty: 0)
    default: return image
    }
    return image.transformed(by: transform)
}

// Vision's accurate text reader reads sideways and upside-down lines, and each line's topLeft -> topRight runs in
// reading order, so one pass gives the page direction. Its scores cannot: an upside-down page scores the same as an
// upright one, and the fast reader gives every line confidence 0.5.
func uprightTurn(_ image: CIImage, context: CIContext) throws -> (clockwise: Int, characters: Int) {
    let scale = min(1, textCheckMaxPixels / max(image.extent.width, image.extent.height))
    let small = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    guard let picture = context.createCGImage(small, from: small.extent) else {
        throw ToolError(description: "cannot prepare the text check")
    }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    try VNImageRequestHandler(cgImage: picture, options: [:]).perform([request])

    var dx = 0.0
    var dy = 0.0
    var characters = 0
    for line in request.results ?? [] {
        guard let count = line.topCandidates(1).first?.string.count else { continue }
        let x = Double(line.topRight.x - line.topLeft.x) * Double(picture.width)
        let y = Double(line.topRight.y - line.topLeft.y) * Double(picture.height)
        let length = hypot(x, y)
        guard length > 0 else { continue }
        dx += x / length * Double(count)
        dy += y / length * Double(count)
        characters += count
    }
    if characters < minTextCharacters { return (0, characters) }
    let readingAngle = atan2(dy, dx) * 180 / .pi
    let clockwise = (Int((readingAngle / 90).rounded()) * 90 + 360) % 360
    return (clockwise, characters)
}

func cutOutPaper(_ image: CIImage) throws -> (paper: CIImage, confidence: Float, share: Double) {
    let request = VNDetectDocumentSegmentationRequest()
    try VNImageRequestHandler(ciImage: image, options: [:]).perform([request])
    guard let found = request.results?.first else {
        throw ToolError(description: "no paper found in the photo; run again with --keep-background")
    }
    let w = image.extent.width
    let h = image.extent.height
    func pixel(_ p: CGPoint) -> CIVector { CIVector(x: p.x * w, y: p.y * h) }
    let flat = image.applyingFilter("CIPerspectiveCorrection", parameters: [
        "inputTopLeft": pixel(found.topLeft),
        "inputTopRight": pixel(found.topRight),
        "inputBottomLeft": pixel(found.bottomLeft),
        "inputBottomRight": pixel(found.bottomRight),
    ])
    // Paper edges curl, so the found outline can leave a thin strip of background.
    let e = flat.extent
    let kept = e.insetBy(dx: e.width * edgeTrim, dy: e.height * edgeTrim).integral
    let paper = flat.cropped(to: kept).transformed(by: CGAffineTransform(translationX: -kept.minX, y: -kept.minY))
    let share = Double(found.boundingBox.width * found.boundingBox.height)
    return (paper, found.confidence, share)
}

func isA4Shape(_ size: CGSize) -> Bool {
    let longToShort = max(size.width, size.height) / min(size.width, size.height)
    return abs(longToShort - a4LongToShort) / a4LongToShort <= a4ShapeTolerance
}

func writeA4PDF(_ image: CIImage, to url: URL, stretch: Bool, context: CIContext) throws {
    guard let rendered = context.createCGImage(image, from: image.extent) else {
        throw ToolError(description: "cannot render the page")
    }
    // Quartz embeds a JPEG as-is only when the CGImage comes straight from JPEG data; a decoded image is stored uncompressed (about 4x bigger).
    let jpegData = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(jpegData, "public.jpeg" as CFString, 1, nil) else {
        throw ToolError(description: "cannot make the JPEG")
    }
    CGImageDestinationAddImage(dest, rendered, [kCGImageDestinationLossyCompressionQuality: jpegQuality] as CFDictionary)
    guard CGImageDestinationFinalize(dest),
          let jpegSource = CGImageSourceCreateWithData(jpegData, nil),
          let jpeg = CGImageSourceCreateImageAtIndex(jpegSource, 0, nil)
    else { throw ToolError(description: "cannot make the JPEG") }

    let imageSize = CGSize(width: jpeg.width, height: jpeg.height)
    let portrait = imageSize.height >= imageSize.width
    var page = CGRect(origin: .zero, size: portrait ? a4Portrait : CGSize(width: a4Portrait.height, height: a4Portrait.width))
    let drawRect: CGRect
    if stretch {
        drawRect = page
    } else {
        let scale = min(page.width / imageSize.width, page.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        drawRect = CGRect(x: (page.width - size.width) / 2, y: (page.height - size.height) / 2,
                          width: size.width, height: size.height)
    }

    guard let pdf = CGContext(url as CFURL, mediaBox: &page, nil) else {
        throw ToolError(description: "cannot write \(url.path)")
    }
    pdf.beginPDFPage(nil)
    pdf.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    pdf.fill(page)
    pdf.interpolationQuality = .high
    pdf.draw(jpeg, in: drawRect)
    pdf.endPDFPage()
    pdf.closePDF()
}

func convert(_ path: String, options: Options, context: CIContext) throws -> String {
    let output = URL(fileURLWithPath: path).deletingPathExtension().appendingPathExtension("pdf")
    var notes: [String] = []

    let photo = try loadAsDisplayed(path)
    let clockwise: Int
    if let forced = options.clockwise {
        clockwise = forced
        notes.append("turned \(forced)° clockwise (--rotate)")
    } else {
        let check = try uprightTurn(photo, context: context)
        clockwise = check.clockwise
        if check.characters < minTextCharacters {
            notes.append("not turned: only \(check.characters) letters found, too few to tell which way is up")
        } else if clockwise == 0 {
            notes.append("already upright, from the direction of \(check.characters) letters")
        } else {
            notes.append("turned \(clockwise)° clockwise, from the direction of \(check.characters) letters")
        }
    }
    let upright = turned(photo, clockwise: clockwise)

    let page: CIImage
    let stretch: Bool
    if options.keepBackground {
        page = upright
        stretch = false
        notes.append("whole photo kept")
    } else {
        let cut = try cutOutPaper(upright)
        page = cut.paper
        stretch = isA4Shape(page.extent.size)
        notes.append(String(format: "paper found (confidence %.2f, %.0f%% of the photo)", cut.confidence, cut.share * 100))
        notes.append(stretch ? "A4 shape, fills the page" : "not A4 shape, placed on the page with white margins")
    }

    try writeA4PDF(page, to: output, stretch: stretch, context: context)
    return "\(path) -> \(output.path)\n  " + notes.joined(separator: "\n  ")
}

let options = parseOptions()
let context = CIContext()
var failed = false
for path in options.photos {
    do {
        print(try convert(path, options: options, context: context))
    } catch {
        FileHandle.standardError.write("\(path): \(error)\n".data(using: .utf8)!)
        failed = true
    }
}
exit(failed ? 1 : 0)
