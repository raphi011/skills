# Validation: Failure Interpretation

Per-check failure guidance for `go-validate.sh` results.

## Fixing Failures

Look at each `=== name: FAIL ===` section for details:

- **mod_tidy**: Dependency issues — check imports
- **gofmt**: Should not fail if autofix is on
- **go_fix**: Should not fail if autofix is on (requires Go 1.26+)
- **go_vet**: Suspicious code patterns — fix the flagged lines
- **go_build**: Compilation errors — fix and retry
- **test_unit / test_tag_***: Test failures — investigate and fix, do NOT skip tests

## Disabling Auto-fix

To see issues without fixing:

```bash
GO_VALIDATE_AUTOFIX=false ./scripts/go-validate.sh
```
