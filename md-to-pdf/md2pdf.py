import argparse, pathlib, subprocess, sys

import markdown

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

STYLE = """
  @page { size: A4; margin: 18mm 16mm; }
  body { font-family: -apple-system, "Helvetica Neue", Arial, sans-serif; font-size: 10.5pt; line-height: 1.45; color: #1b1b1b; }
  h1 { font-size: 20pt; margin: 0 0 6pt; }
  h2 { font-size: 15pt; margin: 18pt 0 6pt; border-bottom: 1px solid #ccc; padding-bottom: 3pt; }
  h3 { font-size: 12pt; margin: 14pt 0 4pt; }
  table { border-collapse: collapse; width: 100%; margin: 6pt 0 10pt; font-size: 9.5pt; }
  th, td { border: 1px solid #bbb; padding: 4pt 6pt; vertical-align: top; text-align: left; }
  th { background: #f0ece4; } tr { page-break-inside: avoid; }
  code { font-family: Menlo, monospace; font-size: 9pt; background: #f4f4f4; padding: 0 2pt; }
  pre { background: #f4f4f4; padding: 6pt 8pt; font-size: 9pt; white-space: pre-wrap; }
  hr { border: 0; border-top: 1px solid #ccc; margin: 14pt 0; }
  li { margin: 2pt 0; }
"""


def build(source: pathlib.Path, output: pathlib.Path) -> None:
    body = markdown.markdown(source.read_text(), extensions=["tables", "fenced_code", "sane_lists"])
    html = f'<!doctype html><html><head><meta charset="utf-8"><title>{source.stem}</title><style>{STYLE}</style></head><body>{body}</body></html>'
    html_path = output.with_suffix(".html")
    html_path.write_text(html)
    try:
        subprocess.run(
            [CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer", f"--print-to-pdf={output}", f"file://{html_path}"],
            check=True, capture_output=True, timeout=120,
        )
    finally:
        html_path.unlink(missing_ok=True)


def preview(output: pathlib.Path, pages: int) -> list[pathlib.Path]:
    import pypdfium2  # optional: only installed when --preview is used

    document = pypdfium2.PdfDocument(str(output))
    written = []
    for index in range(min(pages, len(document))):
        path = output.with_name(f"{output.stem}-page{index + 1}.png")
        document[index].render(scale=1.3).to_pil().save(path)
        written.append(path)
    return written


def main() -> int:
    parser = argparse.ArgumentParser(description="Turn a Markdown file into an A4 PDF using Google Chrome.")
    parser.add_argument("source", type=pathlib.Path)
    parser.add_argument("output", type=pathlib.Path, nargs="?")
    parser.add_argument("--preview", type=int, default=0, metavar="N", help="also write the first N pages as PNG, for a visual check")
    args = parser.parse_args()

    if not pathlib.Path(CHROME).exists():
        print(f"Google Chrome not found at {CHROME}", file=sys.stderr)
        return 2
    output = args.output or args.source.with_suffix(".pdf")
    build(args.source, output)
    print(f"{output} ({output.stat().st_size} bytes)")
    for path in preview(output, args.preview) if args.preview else []:
        print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
