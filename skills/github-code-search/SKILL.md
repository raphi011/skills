---
name: github-code-search
description: >-
  This skill should be used when the user asks to "search GitHub for code",
  "search code on GitHub", "find code across repos", "search for usage examples
  on GitHub", "find implementations in other repos", "find how other repos use",
  "look for code examples on GitHub", "gh search code", or when local grep is
  insufficient because the code lives in other repositories. Covers gh search
  code patterns, structured output, filtering by language/filename/extension,
  and cross-repository code discovery.
version: 1.0.0
tags: [github, search, discovery]
targets: [claude]
allowed-tools: Bash(gh:*)
---

# GitHub Code Search

Search code across GitHub repositories using `gh search code`.

## Quick Reference

```bash
# Search within an org
gh search code "<search-term>" --owner my-org

# Specific repo
gh search code "<search-term>" --repo owner/repo-name

# Filter by language
gh search code "<search-term>" --owner my-org --language kotlin

# Filter by filename
gh search code "<search-term>" --owner my-org --filename build.gradle.kts

# Filter by extension
gh search code "<search-term>" --owner my-org --extension yaml

# JSON output for structured processing
gh search code "<search-term>" --owner my-org --json path,repository,textMatches
```

## Default Behavior

- Always include `--owner` or `--repo` to scope the search — ask the user if not specified
- Use `--limit 20` for broad searches to avoid excessive output
- For targeted searches (specific repo + filename), default limit is fine

## Structured Output

Use `--json` for parseable results, then format as a table for the user:

```bash
gh search code "<search-term>" --json path,repository,textMatches --limit 20
```

JSON fields: `path`, `repository` (has `fullName`), `sha`, `textMatches` (has `fragment`), `url`.

Extract and format with jq:

```bash
gh search code "<search-term>" --owner my-org --json path,repository,textMatches --limit 20 \
  | jq -r '.[] | [.repository.fullName, .path, (.textMatches[0].fragment // "")] | @tsv'
```

Present results as:

```
| Repository | File | Match |
|------------|------|-------|
| owner/repo | src/main/Foo.kt | ...matching line... |
```

## Search Strategy

1. **Exact phrases**: quote multi-word terms — `"error handling"`
2. **Narrow first**: combine `--owner` + `--language` or `--filename` to reduce noise
3. **Broaden if empty**: drop filters one at a time
4. **Multiple searches**: run separate queries for synonyms or related terms if first search yields few results

## Limitations

- Powered by GitHub's legacy code search engine — results may differ from github.com
- No regex support via the API
- Only searches default branches
- Rate-limited: avoid rapid repeated searches
