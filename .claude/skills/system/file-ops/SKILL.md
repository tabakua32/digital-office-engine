---
name: file-ops
description: Create and edit spreadsheets, presentations, documents
---
# File Operations

## Spreadsheets (CSV/TSV)
- Create: write CSV to output/{date}/filename.csv
- Read: parse existing CSV from workspace/
- Tools: Bash (csvkit), Write tool

## Presentations
- Generate markdown outline → convert via Marp CLI
- Or use PowerPoint MCP if available
- Save to output/{date}/filename.pptx

## Documents
- Markdown is default format
- Convert to PDF via pandoc if needed
- Save to output/{date}/filename.md

## Rule
All files → output/{YYYY-MM-DD}/ with descriptive names
Never create files in repo root or src/
