---
name: zk
description: >
  Use when the user asks to "search my notes", "find in knowledge base",
  "look up my docs", "create a note", "remember this", "what do I know about",
  "find related notes", "find orphan notes", "list tags", "daily note",
  "quick note", "maintain knowledge base", "search zk", "search zettelkasten",
  "browse my vault", "check my notes on", "edit my document",
  or when interacting with the zk Zettelkasten knowledge base.
tags: [notes, zettelkasten, knowledge]
targets: [claude]
allowed-tools: Bash(zk:*), Read, Write, Edit, Grep, Glob
---

# Zettelkasten Knowledge Base

Knowledge base managed with `zk` CLI. `ZK_NOTEBOOK_DIR` should be set globally — no need to pass `--notebook-dir`.

## Navigation

Every directory has an `index.md` listing its contents. Navigate top-down:

1. Read `$ZK_NOTEBOOK_DIR/index.md` to see top-level directories
2. Read the `index.md` of the relevant subdirectory to find notes
3. When creating a note, add a row to the `index.md` of the target directory

## Conventions

- Kebab-case filenames
- YAML frontmatter: `tags` (YAML list) + `date` (YYYY-MM-DD)
- Wiki-link syntax `[[note-name]]`

## Tagging

**Reuse existing tags.** Before tagging a note, run `zk tag list --sort note-count-` and pick from existing tags. Only create a new tag when nothing suitable exists.

- Tags are lowercase, single-word or hyphenated (`go`, `cli-tool`, `incident`)
- Prefer broader tags over narrow ones — `go` not `go-testing`
- 2–5 tags per note is the sweet spot
- Namespaced tags use colons for special purposes: `repo:owner/repo`

## Search & Retrieve

```bash
# Full-text search
zk list --match "query terms" --format medium --limit 10

# Boolean: "go OR rust", "go NOT generics", "\"exact phrase\"", "title: kubernetes", "edi*"

# By tag (AND: "t1, t2" | OR: "t1 OR t2" | NOT: "NOT done" | Glob: "program*")
zk list --tag "programming, go" --format medium --limit 10

# Browse directory
zk list notes/programming/ --sort title --format oneline

# List all tags
zk tag list --sort note-count-

# Links & relations
zk list --linked-by notes/path/note.md   # outgoing links
zk list --link-to notes/path/note.md     # backlinks
zk list --related notes/path/note.md     # shared links

# Date filtering (natural language: "last tuesday", "Feb 3", "2024", "last two weeks")
zk list --modified-after "last week" --sort modified-

# Read a note
zk list --match "exact title" -Me --format full --limit 1
```

Or read files directly at their path.

## Create & Capture

### New note

```bash
printf '%s' "Content" | zk new \
  --title "Note Title" --print-path --no-input --interactive \
  <target-directory>/
```

After creation, **edit the file** to set tags. Check `zk tag list --sort note-count-` first and reuse existing tags.

### Daily note

```bash
zk new --no-input --print-path daily/
```

Won't overwrite if today's entry exists.

### Edit existing note

Read the file, modify with Edit tool. No special zk command needed.

## Link & Maintain

```bash
# Orphan notes (no links pointing to them)
zk list --orphan --sort modified- --format oneline --limit 20

# Untagged notes
zk list --tagless --sort modified- --format oneline --limit 20

# Missing backlinks
zk list --missing-backlink --format oneline --limit 20

# Short/flimsy notes
zk list --format '{{word-count}}\t{{title}}\t{{path}}' --sort word-count --limit 20
```

Vault health check: run orphan + tagless + tag list checks, report findings, suggest fixes.

## Quick Reference

| Format | Use |
|--------|-----|
| `oneline` | Browsing (title + path) |
| `medium` | Search results (title + lead) |
| `full` | Reading a note |
| `json` / `jsonl` | Programmatic processing |
| Custom | `--format "{{title}} \| {{join tags ', '}}"` |

Sort: `created`, `modified`, `path`, `title`, `random`, `word-count`. Suffix: `+` asc, `-` desc.

## Gotchas

- `ZK_NOTEBOOK_DIR` env var is set globally — no need for `--notebook-dir`
- `--no-input` prevents interactive prompts that hang Claude Code
- `--print-path` outputs path only, no editor launch
- `--interactive` on `zk new` means "read stdin", NOT "launch fzf"
- Groups auto-apply by directory — `zk new daily/` uses the daily group config
- After creating notes, edit the file to set tags (templates default to `tags: []`)
- Git workflow: `cd $ZK_NOTEBOOK_DIR && git add -A && git commit -m "latest" && git push`
