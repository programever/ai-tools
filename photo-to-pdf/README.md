# photo-to-pdf

Turns phone photos of paper documents into PDF files that look like a scan.
Each photo becomes one PDF file with one A4 page. The tool:

1. Turns the photo so the text stands upright. It reads the text to know which way is up.
2. Finds the four corners of the paper and cuts away the table or floor around it.
3. Makes the paper flat and straight, even when the photo was taken at an angle.
4. Puts the paper on an A4 page. A sheet with the A4 shape fills the whole page. Any other shape (a receipt, a US
   Letter sheet) keeps its shape and gets white margins.

It reads HEIC, JPG and PNG photos. It uses only tools that come with macOS (Vision and Core Image), so it needs
nothing extra. It needs the Swift compiler, which comes with the Xcode command line tools.

## Use

```bash
~/Workspace/ai-tools/photo-to-pdf/photo-to-pdf ~/Downloads/IMG_8639.HEIC ~/Downloads/IMG_8640.HEIC
```

Writes `IMG_8639.pdf` and `IMG_8640.pdf` next to the photos. If a PDF with that name already exists, the tool
replaces it.

For each photo it prints what it did: how far it turned the photo, how sure it is that it found the paper, and how
much of the photo the paper covers. Read these lines. If the paper covers only a small part of the photo, the tool
may have found the wrong shape.

The first run builds the program into `.build/` inside this folder. It takes a few seconds. After you change
`photo-to-pdf.swift`, the next run builds it again by itself.

## Options

- `--rotate 90` turns every photo 90 degrees clockwise (also `0`, `180`, `270`), and the tool does not guess from the
  text. Use it when a page has almost no text, or when the guess was wrong.
- `--keep-background` keeps the whole photo and does not cut out the paper. Use it when the tool says
  "no paper found", or when it cut the wrong shape.

## Known limits

- Which way is up comes from the text. A photo with fewer than 20 letters is not turned. Use `--rotate`.
- The paper must stand out from what is around it. White paper on a white table may not be found.
- A curled or folded sheet is made straight only at its four corners. The middle can still look a little bent.
- The tool cuts a very thin strip (0.6%) from each edge of the paper. This removes the dark line that a curled edge
  leaves. Text that touches the paper's edge can lose a little.
