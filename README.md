# ai-tools

Small tools Beta built for Iker. One folder per tool. Each folder has:

- `README.md` — how to run it
- `SKILL.md` — when Claude Code should use it (linked into `~/.claude/skills/<name>`)

| Tool | What it does |
|---|---|
| `md-to-pdf` | Markdown file → A4 PDF with tables, using Chrome headless |
| `gpx-to-plan` | GPX tracks + a list of stops → easy-pacer bundled route plans (`Seeded.elm`) |
| `photo-to-pdf` | Phone photos of paper documents → A4 PDF files that look scanned (upright, background cut away) |

## Setup on a new Mac

```bash
git clone git@github.com:programever/ai-tools.git ~/Workspace/ai-tools
mkdir -p ~/.claude/skills
for t in ~/Workspace/ai-tools/*/; do ln -sfn "$t" ~/.claude/skills/$(basename "$t"); done
```
