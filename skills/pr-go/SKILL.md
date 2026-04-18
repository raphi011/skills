---
name: pr-go
description: Validates Go code quality and creates a pull request. Triggered by "create a Go PR", "Go PR pipeline", "run Go validation and PR", or "validate and push Go code".
tags: [go, pr, quality]
targets: [claude]
context: fork
allowed-tools: Bash(go:*), Bash(gofmt:*), Bash(dupl:*), Bash(gocyclo:*), Bash(staticcheck:*), Bash(deadcode:*), Bash(*/go-validate.sh), Bash(git:*), Bash(gh:*), Bash(make:*), Read, Glob, Grep
---

# Go PR Pipeline

Validate code quality, run all tests, and create a PR only if everything passes.

**STOP immediately if any step fails** and attempt to fix the issue before retrying.

## Step 1: Validate (Quality + Tests + Analysis)

Run the validation script from the Go module root:

```bash
./scripts/go-validate.sh
```

The script runs all quality checks, tests, and static analysis in one pass.

Parse the `=== SUMMARY ===` line:

- **FAIL > 0**: Fix issues, re-run the script. Repeat until FAIL=0.
- **WARN > 0**: Present warnings to user. Ask: "Found warnings — proceed to PR creation?"
- **SKIP > 0**: Note skipped tools in PR description. Not blocking.
- **autofix=true**: Stage auto-fixed files with `git add`.

See `validate-reference.md` for detailed failure interpretation and fix guidance.

## Step 2: Check for Forgotten Items

Run `git diff main...HEAD` (or `master...HEAD`) to review all changes against the plan/task.

Check for:
- Missing tests for new functionality
- Unused or dead code
- Missing documentation updates for new CLI flags/commands
- TODOs that should be addressed
- Debug code that should be removed

Fix any issues before proceeding.

## Step 3: Verify Documentation

- Check if `CLAUDE.md` exists and reflects current project state
- Check if `README.md` needs updates for new features/changes
- If changes added new CLI flags, commands, or APIs — ensure documented

Update stale docs before proceeding.

## Step 4: Commit Changes

If `git status` shows uncommitted changes (e.g., from formatting fixes):

- Stage relevant files
- Create commit with descriptive message
- Follow conventional commits format

## Step 5: Create/Update PR

Only after ALL checks pass.

1. Check for existing PR: `gh pr view --json number 2>/dev/null`
2. Check for PR template: `ls .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null`
3. If no PR exists:
   - Push branch: `git push -u origin HEAD`
   - Create PR using template if available, otherwise use format from `pr-summary.md`
4. If PR exists:
   - Push new commits
   - Update PR description if needed

## Error Handling

- **FAIL results**: Fix the code and re-run the validation script
- **WARN results**: Present warnings to user, ask to proceed
- **SKIP results**: Tool not installed — note in PR, not blocking
- **Auto-fix applied**: Stage auto-fixed files before committing

## Output

Report status after each step:
- Step passed
- Step failed (with details)
- Step had warnings (proceed with caution)

After PR creation/update, generate summary per `pr-summary.md`.

## Current Branch Context

```
!`git log main...HEAD --oneline 2>/dev/null || git log master...HEAD --oneline 2>/dev/null || echo "(could not detect base branch)"`
```

Changed files:
```
!`git diff main...HEAD --stat 2>/dev/null || git diff master...HEAD --stat 2>/dev/null || echo "(could not detect base branch)"`
```
