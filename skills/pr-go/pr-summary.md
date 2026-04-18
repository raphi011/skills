# PR Summary Format

After PR creation/update:

1. Run `git diff main...HEAD --stat` (or `master...HEAD`) for file change overview
2. Review changes and produce:

```
## PR Summary

**Changes**: [1-2 sentence description of the PR purpose]

**Modified**:
- `path/to/file.go`: [brief change description]
- `path/to/other.go`: [brief change description]

**Tests**: [X tests added/modified, or "No test changes"]
```

Also note any breaking changes if applicable.
