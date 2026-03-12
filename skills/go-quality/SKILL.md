---
name: go-quality
description: >-
  Validates Go code quality, runs tests, and fixes issues using a comprehensive
  validation script. Use this skill whenever working in a Go codebase and the user
  asks to "validate Go code", "fix Go issues", "run Go linters", "check Go code",
  "clean up Go code", or mentions go vet, staticcheck, gofmt, or Go static analysis.
  Also use when Go builds fail, tests are failing, or the user wants a quality check
  before committing. This skill should be the first step for any Go code quality concern.
version: 1.0.0
allowed-tools: Bash(go:*), Bash(gofmt:*), Bash(dupl:*), Bash(gocyclo:*), Bash(staticcheck:*), Bash(deadcode:*), Bash(*/go-validate.sh), Bash(make:*), Bash(cp:*), Bash(chmod:*), Bash(mkdir:*), Read, Glob, Grep
---

# Go Quality Validation

Comprehensive Go quality gate: formatting, vetting, building, testing, and static analysis in one pass. Fixes issues and re-validates until clean.

## Step 1: Ensure Validation Script Exists

Check if `./scripts/go-validate.sh` exists in the project root. If not:

```bash
mkdir -p scripts
cp "${CLAUDE_SKILL_DIR}/scripts/go-validate.sh" scripts/go-validate.sh
chmod +x scripts/go-validate.sh
```

Also verify you're in a Go module root (`go.mod` exists). If not, navigate to the correct directory first.

## Step 2: Run Validation

```bash
./scripts/go-validate.sh
```

The script runs these checks in order:
1. `go mod tidy` — dependency hygiene
2. `gofmt` — canonical formatting
3. `go fix` — modernizers (Go 1.26+)
4. `go vet` — suspicious constructs
5. `go build` — compilation
6. `go test` — unit tests + tagged tests
7. `staticcheck`, `deadcode`, `dupl`, `gocyclo` — static analysis (skipped if not installed)

Auto-fix is on by default for formatting and mod tidy. When autofix runs, stage the fixed files with `git add`.

## Step 3: Fix Failures and Re-validate

Parse the `=== SUMMARY ===` line at the end: `PASS=N FAIL=N WARN=N SKIP=N autofix=true|false`

**FAIL > 0** — The script exits non-zero. For each `=== name: FAIL ===` block:
1. Read the indented output below it for the exact error
2. Fix the root cause in the source code
3. Re-run `./scripts/go-validate.sh` — repeat until FAIL=0

The reason this is a strict loop rather than a one-shot fix: Go issues often cascade (e.g., fixing a vet warning reveals a test failure). Re-running catches these chains.

See `references/validate-reference.md` for per-check fix guidance.

**WARN > 0** — Present warnings to the user and ask if they want fixes. Warnings come from static analysis tools (staticcheck, deadcode, dupl, gocyclo) and may indicate real issues or acceptable trade-offs — the user should decide.

**SKIP > 0** — A tool isn't installed. Not blocking. Note which tools were skipped and their install commands (printed by the script).

## Step 4: Report

Once all checks pass:
- Summary: PASS / WARN / SKIP counts
- Any warnings the user should review
- Skipped tools with install commands
- Whether autofix was applied (and which files were changed)
