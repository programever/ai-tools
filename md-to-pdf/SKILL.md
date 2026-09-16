---
name: md-to-pdf
description: Turn a Markdown (.md) file into a clean A4 PDF with tables, using the local md-to-pdf tool. Use whenever Iker asks to make a PDF from a Markdown file, a report, a brief, or notes.
---

# md-to-pdf

Run the tool, do not rewrite it:

```bash
~/Workspace/ai-tools/md-to-pdf/md-to-pdf <source.md> [output.pdf] [--preview N]
```

- Output defaults to the same name with `.pdf` next to the source.
- Use `--preview 1` and look at the PNG with the Read tool before sending, to check tables and page breaks.
- If a numbered list contains a table, or two bold paragraphs touch, fix the Markdown first (see README "Known limits").
- Send the PDF with SendUserFile when done. Keep a master copy of the Markdown outside Dropbox: `.md` files placed in
  Iker's Dropbox have disappeared before.
