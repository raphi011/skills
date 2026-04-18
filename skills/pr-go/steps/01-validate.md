# Step 1: Validate (Quality + Tests + Analysis)

Run the validation script from the Go module root:

```bash
./scripts/go-validate.sh
```

The script runs all quality checks, tests, and static analysis in one pass.

## Interpreting Results

Parse the `=== SUMMARY ===` line at the end:

- **FAIL > 0**: Fix issues in code, then re-run the script. Repeat until FAIL=0.
- **WARN > 0**: Report warnings to user. **STOP and ask**: "Found warnings — proceed to PR creation?"
- **SKIP > 0**: Note skipped tools in PR description. Not blocking.
- **autofix=true**: The script auto-fixed formatting/module issues. Stage changed files with `git add`.

## Fixing Failures

Look at each `=== name: FAIL ===` section for details:

- **mod_tidy**: Dependency issues — check imports
- **gofmt**: Should not fail if autofix is on
- **go_vet**: Suspicious code patterns — fix the flagged lines
- **go_build**: Compilation errors — fix and retry
- **test_unit / test_tag_***: Test failures — investigate and fix, do NOT skip tests

## Disabling Auto-fix

To see issues without fixing:

```bash
GO_VALIDATE_AUTOFIX=false ./scripts/go-validate.sh
```
