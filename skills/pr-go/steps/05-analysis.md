# Step 5: Static Analysis

## Unused Code Check

```bash
go build ./... 2>&1 | grep -i "imported and not used" || true
```

Review any suspicious patterns.

## Duplicate Code Detection

```bash
dupl -threshold 50 . 2>/dev/null || echo "dupl not installed — using manual check"
```

If `dupl` unavailable, use Grep to find similar function signatures and repeated patterns.

## Cyclomatic Complexity

```bash
gocyclo -over 15 . 2>/dev/null || true
```

## Refactoring Opportunities

Flag potential issues:
- Functions > 50 lines (consider splitting)
- Repeated struct/interface patterns across files
- Similar switch/if-else chains that could be consolidated
- Magic numbers or repeated string literals

## User Confirmation

If duplication or complexity issues found:

1. Report all findings as **warnings** with file locations
2. **STOP and ask user**: "Found X duplication/complexity warnings. Proceed to PR creation anyway?"
3. Only continue if user explicitly confirms
