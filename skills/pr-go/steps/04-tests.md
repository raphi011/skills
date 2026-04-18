# Step 4: Tests

## Unit Tests

```bash
go test ./...
```

All tests must pass.

## Integration Tests

If integration tests exist (build tag `integration`):

```bash
go test -tags=integration ./...
```

All integration tests must pass.
