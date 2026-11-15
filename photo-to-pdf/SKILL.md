---
name: photo-to-pdf
description: Turn phone photos of paper documents (HEIC, JPG, PNG) into clean A4 PDF files that look scanned, using the local photo-to-pdf tool. It turns the text upright, cuts away the background and makes the paper flat. Use whenever Iker asks to make a PDF from a photo of a document, letter, form or receipt, or to "scan" a paper.
---

# photo-to-pdf

Run the tool, do not rewrite it:

```bash
~/Workspace/ai-tools/photo-to-pdf/photo-to-pdf <photo>... [--rotate 0|90|180|270] [--keep-background]
```

- One PDF per photo, written next to the photo with the same name. If Iker wants one PDF with all pages, ask first.
- Read the printed lines for each photo. "paper found" under about 50% of the photo can mean the wrong shape was cut.
- Always look at every page before sending: `sips -s format png -Z 900 <file.pdf> --out <scratch>/check.png`, then the
  Read tool. Check that the text is upright and that no table or floor is left at the edges.
- Upside down or sideways: run again with `--rotate`. Paper not found or cut wrong: run again with `--keep-background`.
- Send the PDF files with SendUserFile when done.
