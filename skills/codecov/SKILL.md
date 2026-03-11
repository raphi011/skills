---
name: codecov
description: >-
  This skill should be used when the user asks to "check test coverage",
  "find untested code", "show coverage gaps", "fetch codecov report",
  "check codecov", "analyze coverage", "what needs more tests",
  "coverage on this branch", or when planning coverage improvements.
  Fetches test coverage data from the Codecov API and identifies
  coverage gaps for the current repository.
version: 1.1.0
allowed-tools: WebFetch Bash(git remote:*) Bash(git rev-parse:*) Bash(git branch:*)
argument-hint: "[path-filter]"
---

# Codecov Coverage Analysis

Fetch and analyze test coverage data from Codecov for the current repository.
The optional argument is a directory path prefix to filter results (e.g., `src/services/`).

## Steps

1. **Derive owner/repo** from git remote:
   ```bash
   git remote get-url origin
   ```
   Handle both URL formats:
   - HTTPS: `https://github.com/{owner}/{repo}.git` → extract `{owner}/{repo}`
   - SSH: `git@github.com:{owner}/{repo}.git` → extract `{owner}/{repo}`

   Strip the `.git` suffix if present. Detect the provider from the hostname:
   `github.com` → `github`, `gitlab.com` → `gitlab`, `bitbucket.org` → `bitbucket`.
   Use the provider in the API path (Step 3).

2. **Check authentication**: The Codecov API requires a token for private repositories.
   - Check for `CODECOV_TOKEN` environment variable
   - If set, include header: `Authorization: Bearer $CODECOV_TOKEN`
   - If not set and the API returns 401/403, inform the user:
     *"This appears to be a private repo. Set `CODECOV_TOKEN` to a Codecov API token to access coverage data."*

3. **Fetch overall report** from:
   ```
   https://api.codecov.io/api/v2/{provider}/{owner}/repos/{repo}/report/?page_size=50
   ```
   - To fetch a specific branch, append `&branch={branch}`
   - Detect the current branch via `git rev-parse --abbrev-ref HEAD` if the user asks about "this branch" or "my branch"

4. **Apply path filter** if `$ARGUMENTS` is provided:
   - Append `&path={ARGUMENTS}` to filter by directory
   - Otherwise fetch the top-level report without a path filter

5. **Handle pagination**: Check the response for a `next` field.
   - If `next` is present, fetch additional pages to get complete results
   - If skipping pagination, warn the user: *"Showing first 50 files. Use a path filter to narrow results."*

6. **Extract per-file coverage** from the response:
   - Overall totals: `response.totals` (`coverage`, `lines`, `hits`, `misses`, `partials`)
   - Per-file data: `response.files[]` with fields: `name`, `totals.coverage`, `totals.lines`, `totals.hits`, `totals.misses`

7. **Sort files by missed lines descending** and present:
   - Overall coverage percentage
   - Files with 0% coverage (completely untested)
   - Top files by missed lines (partially tested)
   - Actionable recommendations for improving coverage

## Error Handling

| Response | Action |
|----------|--------|
| 401/403 | Token required — ask user to set `CODECOV_TOKEN` |
| 404 | Repo not found on Codecov — confirm owner/repo is correct and coverage is uploaded |
| Empty `files[]` | No coverage data — ask if coverage reports are being uploaded in CI |
| Non-GitHub remote | Adjust API path: replace `github` with `gitlab` or `bitbucket` as appropriate |
| Network error | Report the error, suggest retrying |

## Output Format

```
## Coverage Report: {owner}/{repo}

Overall: {coverage}% ({hits}/{lines} lines covered)

### Untested Files (0% coverage)
| File | Lines |
|------|-------|
| path/to/file.go | 42 |

### Top Coverage Gaps (by missed lines)
| File | Coverage | Missed | Total |
|------|----------|--------|-------|
| path/to/file.go | 45.2% | 74 | 135 |

### Recommendations
- Add unit tests for `{file}` — {N} lines completely untested
- Improve coverage in `{file}` — {N} lines partially covered
- Consider integration tests for `{package}` — multiple files below {X}% coverage
```
