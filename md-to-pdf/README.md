# md-to-pdf

Turns a Markdown file into an A4 PDF. Tables, headings, lists, code blocks and bold text all render.
Uses Google Chrome in headless mode to print, so it needs Chrome installed on the Mac.

## Use

```bash
~/Workspace/ai-tools/md-to-pdf/md-to-pdf report.md
```

Writes `report.pdf` next to the source. Give a second path to choose the output file:

```bash
~/Workspace/ai-tools/md-to-pdf/md-to-pdf report.md ~/Dropbox/report.pdf
```

Add `--preview 2` to also write the first two pages as PNG images, so you can look at the layout.

First run creates a private Python environment in `.venv/` inside this folder. It takes about 20 seconds.

## Known limits

- Markdown lists: a table inside a numbered list breaks the list. Put the table after the list.
- Blank lines matter: two bold paragraphs with no blank line between them become one paragraph.
- Only Chrome is supported for printing. If Chrome moves, change `CHROME` at the top of `md2pdf.py`.
