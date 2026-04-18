# Step 3: Code Quality

Run in order. Fix issues before proceeding to next check.

## Module Tidiness

```bash
go mod tidy -diff
```

If changes shown, run `go mod tidy` to fix.

## Code Formatting

```bash
gofmt -l .
```

If files listed, run `gofmt -w .` and stage the changes.

## Go Vet

```bash
go vet ./...
```

If issues found, fix them.

## Build Check

```bash
go build ./...
```

Must succeed before running tests.
