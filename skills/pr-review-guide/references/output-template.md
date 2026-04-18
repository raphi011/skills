# Output Template

This is the exact markdown structure for the review guide file. Fill in all `{PLACEHOLDER}` values.
Code snippets MUST be verbatim copies from the diff — never paraphrase or approximate code.

---

## Template

```markdown
# PR Review Guide: {PR_TITLE}

| Field  | Value |
|--------|-------|
| Branch | `{HEAD_BRANCH}` → `{BASE_BRANCH}` |
| Author | {AUTHOR} |
| PR     | [#{PR_NUMBER}]({PR_URL}) |
| Files  | {FILE_COUNT} changed ({ADDITIONS}+, {DELETIONS}-) |

---

## Index

- [TLDR](#tldr)
- [{Section 1 Title}](#{section-1-slug})
- [{Section 2 Title}](#{section-2-slug})
- [{Section N Title}](#{section-n-slug})
- [Tests](#tests)
- [Summary](#summary)

---

## TLDR

{2-3 sentences: what this PR does, why it's needed, and the approach taken.}

---

## {Section Title}

{1-2 sentences explaining what this logical chunk of changes does and why it matters.}

**{filename}** ([`{filename}:{start_line}`]({ABSOLUTE_PATH}#L{LINE}))

\```diff
- removed line
+ added line
  context line
\```

{Brief explanation of what this code does and how it connects to the section's purpose.}

> [!WARNING]
> {CRITICAL or HIGH severity finding from review agents — bugs, security issues, silent failures.
> Include the specific problem and a concrete suggestion.}

**{another_filename}** ([`{filename}:{start_line}`]({ABSOLUTE_PATH}#L{LINE}))

\```diff
+ added line
  context line
\```

{Explanation of how this connects to the previous snippet and the broader change.}

> [!NOTE]
> {Informational observation — positive pattern, design choice worth noting.}

> [!TIP]
> {Suggestion for improvement — not blocking but worth considering.}

> [!CAUTION]
> {MEDIUM severity finding — potential issue that deserves attention.}

---

## Tests

### What's Covered
- `{test_file}`: {what behavior/scenario it tests}
- `{test_file}`: {what behavior/scenario it tests}

### What Might Be Missing
- {Gap identified by pr-test-analyzer or own analysis}
- {Another gap}

> [!TIP]
> {Suggestion for additional test coverage if applicable.}

---

## Summary

**Assessment**: {APPROVE | APPROVE_WITH_SUGGESTIONS | REQUEST_CHANGES}

### Strengths
- {What's well done in this PR}

### Must Address
- {Critical issues that should be fixed before merge}

### Should Consider
- {Important suggestions worth discussing}
```

---

## Callout Mapping

Map agent findings to callout types based on severity:

| Severity | Callout | Use for |
|----------|---------|---------|
| CRITICAL / HIGH | `> [!WARNING]` | Bugs, security issues, silent failures, explicit guideline violations |
| MEDIUM | `> [!CAUTION]` | Potential issues, code smells, questionable patterns |
| Suggestion | `> [!TIP]` | Improvements, better alternatives, test coverage ideas |
| Positive | `> [!NOTE]` | Good patterns, design observations, informational context |

## Snippet Rules

1. **Verbatim only**: Copy code exactly from the diff — never paraphrase, simplify, or rewrite
2. **Diff format**: Use ` ```diff ` with `+`/`-`/` ` prefixes for added/removed/context lines
3. **Truncation**: If a hunk exceeds ~30 lines, show the most relevant lines and add `... ({N} more lines)` with a link to the full file
4. **Links**: Every snippet gets an absolute path link: `[filename:line](/absolute/path/to/file#L{LINE})`
5. **Context**: Include 1-3 lines of unchanged context around changes when it aids understanding

## Section Ordering

Order sections by importance, not by file path:
1. Core behavioral changes (new features, bug fixes, logic changes)
2. Supporting infrastructure (helpers, utilities, middleware)
3. Configuration / build / dependency changes
4. Tests (always last dedicated section before Summary)

## Large PR Handling

For PRs with >30 changed files or >1000 changed lines:
- Group more aggressively — aim for 3-5 main sections max
- Add a **Minor Changes** section after the core sections that lists remaining files as a table:

```markdown
## Minor Changes

| File | Change |
|------|--------|
| `path/to/config.yaml` | Updated timeout value |
| `path/to/constants.go` | Added new error code |
```

- Do NOT include full snippets for minor changes — a one-line description suffices
