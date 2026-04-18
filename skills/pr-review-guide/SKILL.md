---
name: pr-review-guide
description: >-
  Generate a narrative PR review guide as a markdown file. Use when the user asks to
  "review this PR", "generate a review guide", "create a PR walkthrough",
  "review guide for PR", "pr review file", "guide me through this PR",
  "narrative review", or wants a structured markdown document that walks through
  PR changes as a story rather than file-by-file.
version: 1.0.0
tags: [review, pr, documentation]
targets: [claude]
allowed-tools: Bash(git:*) Bash(gh:*) Read Glob Grep Write Task
argument-hint: "[pr-number-or-url]"
---

# PR Review Guide Generator

Generate a markdown file that walks a human reviewer through a PR as a **narrative story** — grouped by logical concepts, not file-by-file. The output includes verbatim code snippets, absolute-path links, and review insights inlined as callouts.

Read `references/output-template.md` for the exact output structure and rules.

## Workflow

### Step 1: Detect PR & Gather Metadata

**If `$ARGUMENTS` contains a PR number or URL:**
```bash
gh pr view <number> --json title,number,url,author,baseRefName,headRefName,additions,deletions,changedFiles
```

**If no arguments — try current branch:**
```bash
gh pr view --json title,number,url,author,baseRefName,headRefName,additions,deletions,changedFiles
```

**Fallback — no PR exists:**
```bash
git log --oneline $(git merge-base HEAD main)..HEAD  # commits on this branch
git diff --stat $(git merge-base HEAD main)...HEAD    # change summary
```
Use the branch name as the identifier. The output file will be `review-<branch>.md`.

**Always get the repo root** (needed for absolute path links):
```bash
git rev-parse --show-toplevel
```

### Step 2: Fetch the Full Diff

```bash
gh pr diff <number>          # if PR exists
git diff <base>...HEAD       # fallback
```

Also get the stat summary:
```bash
git diff --stat <base>...HEAD
```

Parse the diff into per-file hunks. Classify each file:
- **Core logic**: source files with behavioral changes (new features, bug fixes, refactors)
- **Tests**: files matching `*_test.*`, `*.test.*`, `**/test/**`, `**/tests/**`, `**/__tests__/**`
- **Config/infra**: `.yaml`, `.json`, `.toml`, `Dockerfile`, CI files, build configs
- **Generated**: lock files, generated code, vendored dependencies

### Step 3: Launch Review Agents (Parallel)

Spawn applicable agents via `Task` in a **single response turn** for parallel execution.
Pass each agent the relevant diff sections and instruct them to return findings with `file:line` references.

| Agent | Condition | What to include in prompt |
|-------|-----------|--------------------------|
| `code-reviewer` | **Always** | Full diff of non-test files |
| `silent-failure-hunter` | Diff contains `catch`, `except`, `rescue`, error handling, or fallback logic | Relevant diff sections only |
| `pr-test-analyzer` | Test files are in the diff | Test file diffs + production code they should cover |
| `type-design-analyzer` | New types, interfaces, structs, or classes added | Relevant type definitions |

**Agent prompt template:**
> Review the following changes from a pull request. Return your findings as a structured list.
> For each finding include: severity (CRITICAL/HIGH/MEDIUM), file path, line number, description, and suggestion.
>
> {diff content}

### Step 4: Analyze & Group Changes

This is the critical creative step. Do NOT just list files alphabetically.

1. Read all diff hunks and all agent findings
2. Identify **logical groupings** by concept — examples:
   - "New authentication middleware"
   - "Database schema migration"
   - "Payment processing refactor"
   - "API endpoint for user profiles"
   - "Error handling improvements"
3. **Order by importance**:
   1. Core behavioral changes (the "why" of the PR)
   2. Supporting infrastructure (helpers, utilities, middleware)
   3. Configuration / build / dependency changes
4. Map each agent finding to the logical section where its code lives
5. For large PRs (>30 files), identify minor/supporting files to list in a summary table

### Step 5: Assemble the Review Document

Build the markdown following the template in `references/output-template.md`.

**Key rules:**

**Snippets must be verbatim.** Copy code exactly from the diff. Never paraphrase, simplify, or rewrite. Use `diff` code blocks with `+`/`-`/` ` prefixes.

**Every snippet gets a link.** Format: `[filename:line]({REPO_ROOT}/path/to/file#L{LINE})` where `REPO_ROOT` is the absolute path from Step 1. The link must be an absolute filesystem path so the reviewer can cmd-click it in their markdown reader.

**Inline agent findings as callouts.** Place each finding directly after the code snippet it relates to. Use the callout type matching the severity:
- CRITICAL/HIGH → `> [!WARNING]`
- MEDIUM → `> [!CAUTION]`
- Suggestions → `> [!TIP]`
- Positive observations → `> [!NOTE]`

**Truncate long hunks.** If a hunk exceeds ~30 lines, show the most important lines (additions, core logic) and add:
```
... (N more lines) — [view full file](absolute/path#L{START})
```

**Tests section is concise.** List what's tested and what might be missing. Don't reproduce test code line-by-line. Flag if no tests were added/changed.

**TLDR is 2-3 sentences max.** What the PR does, why, and the approach — nothing more.

### Step 6: Write to Disk

Write the assembled markdown to the **current working directory**:
- `review-{PR_NUMBER}.md` if a PR exists
- `review-{BRANCH_NAME}.md` if no PR (sanitize branch name: replace `/` with `-`)

Tell the user the file path so they can open it.

## Edge Cases

| Scenario | Handling |
|----------|----------|
| No PR found | Fall back to branch diff against `main` (or `master`). Use branch name in filename. |
| Large PR (>30 files / >1000 lines) | Group aggressively (3-5 sections max). Add "Minor Changes" summary table. |
| Binary files | Mention in metadata section, skip snippets. |
| No test changes | Flag explicitly in Tests section as a potential gap. |
| Agent returns no findings | Good news — note "No issues found" for that agent's domain. |
| Agent fails or times out | Proceed without it. Note in Summary which agents were skipped. |
| Extremely long hunks (>30 lines) | Truncate with `... (N more lines)` + link to full file. |
| Merge commits in diff | Use `--no-merges` or `gh pr diff` which excludes merge noise. |

## Example Invocations

```
# Review the current branch's PR
/pr-review-guide

# Review a specific PR by number
/pr-review-guide 1234

# Review a PR by URL
/pr-review-guide https://github.com/org/repo/pull/1234
```
