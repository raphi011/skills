---
name: surrealdb
description: >-
  Use whenever working with SurrealDB — writing queries, defining schemas,
  configuring indexes, debugging errors, handling record IDs, using the Go SDK,
  or discussing SurrealDB architecture. Activate on any mention of SurrealDB,
  SurrealQL, HNSW indexes, or surreal-related Go SDK code.
version: 1.0.0
tags: [database, surrealdb, go]
targets: [claude]
---

# SurrealDB v3.0 Reference

Quick-reference for SurrealDB v3.0 patterns, gotchas, and SDK usage. Updated for v3.0.2.

For complete details: `references/full-reference.md`

## Critical Gotchas

These bite silently — check every time.

### UPSERT WHERE Doesn't Create Records

`UPSERT ... WHERE` only updates existing rows — **never creates** new records when WHERE matches nothing. Returns empty result silently.

```sql
-- BAD: silently does nothing if no record matches
UPSERT asset SET data = $data WHERE vault = $v AND path = $p

-- GOOD: check-then-create/update pattern
-- 1. SELECT to check existence
-- 2. If not found: CREATE
-- 3. If found: UPDATE
-- 4. On unique constraint violation during CREATE: retry as UPDATE (race)
```

### HNSW Rejects NONE Values

Even on `option<array<float>>` fields, setting `embedding = NONE` causes: `Expected 'array' but found 'NONE'`.

**Fix**: Omit the field entirely from CREATE. UPDATE later when embedding is available.

```sql
-- BAD
CREATE chunk SET content = $content, embedding = NONE

-- GOOD
CREATE chunk SET content = $content
-- later: UPDATE chunk:xyz SET embedding = $embedding
```

### bytes Fields Reject NULL

SurrealDB's `bytes` type does not accept NULL. Go `nil` slice → `Expected 'bytes' but found 'NULL'`.

**Fix**: Normalize `nil` to `[]byte{}` before passing to the query.

### type::record() Expects Bare IDs (Double-Prefix Trap)

`type::record("table", $id)` — if `$id` already has a table prefix (e.g., `"vault:default"`), result is `vault:vault:default`. Silently matches nothing.

**Fix**: Strip table prefix with `bareID` helper:

```go
func bareID(table, id string) string {
    return strings.TrimPrefix(id, table+":")
}
```

### INSIDE Requires Typed RecordIDs, Not Strings

`id INSIDE $ids` — passing `[]string{"document:abc123"}` silently matches nothing due to CBOR type distinction.

**Fix**: Pass `[]surrealmodels.RecordID`:

```go
recordIDs := make([]surrealmodels.RecordID, len(ids))
for i, id := range ids {
    recordIDs[i] = newRecordID("document", bareID("document", id))
}
```

### Compound OR Parse Errors

Parenthesized OR in WHERE clauses can cause parse errors (v3.0.2):

```sql
-- FAILS
DELETE FROM folder WHERE vault = $v AND (path = $p OR string::starts_with(path, $prefix))

-- WORKAROUND: split into separate queries (use transaction if atomicity needed)
```

### type::record() in RELATE Needs LET Vars

Cannot use `type::record()` inline in RELATE endpoints — parse error.

```sql
-- FAILS
RELATE type::record("doc", $from)->rel->type::record("doc", $to)

-- WORKS
LET $from = type::record("doc", $from_id);
LET $to = type::record("doc", $to_id);
RELATE $from->rel->$to SET ...
```

Note: multi-statement queries return one result per statement. With 2 LETs + RELATE, the RELATE result is at index `[2]`.

### SPLIT + GROUP BY Mutually Exclusive

Cannot appear in the same query in v3.0 (was allowed in v2).

```sql
-- FAILS
SELECT labels, count() FROM document SPLIT labels GROUP BY labels

-- WORKS: subquery
SELECT label, count() AS count
FROM (SELECT labels AS label FROM document SPLIT labels)
GROUP BY label ORDER BY count DESC
```

### Negative Array Indexing Unreliable

`[-1]` returns NONE. Use `array::last()` or `array::at()` instead.

### RETURN vs SELECT for Computed Expressions

Standalone computed expressions (no table) need `RETURN`, not `SELECT`:

```sql
-- FAILS: Unexpected end of file, expected FROM
SELECT array::distinct(array::flatten(...)) AS labels

-- WORKS
RETURN array::distinct(array::flatten(...))
```

## KNN Operator (v3.0)

Two forms depending on index presence:

**HNSW form** `<|K,EF|>` (requires HNSW index):
- K = neighbors, EF = effort (higher = more accurate, slower). Default EF: 40
- **EF param is required** — omitting it gives misleading error about OR/NOT expressions
- Can combine with AND: `WHERE doc.vault = $v AND embedding <|10,40|> $vec`

**Brute force** `<|K,DIST|>` (no index):
- DIST = COSINE, EUCLIDEAN, etc.

```sql
embedding <|10,40|> $query_vec    -- HNSW
embedding <|10,COSINE|> $query_vec -- brute force
```

## Schema Patterns

```sql
-- Strict mode (per-database, not server-wide in v3.0)
DEFINE DATABASE IF NOT EXISTS mydb STRICT;

-- HNSW vector index
DEFINE INDEX idx_embedding ON chunk FIELDS embedding
    HNSW DIMENSION 1024 DIST COSINE TYPE F32 EFC 150 M 12 HASHED_VECTOR;

-- Fulltext analyzer + index
DEFINE ANALYZER my_analyzer TOKENIZERS class FILTERS lowercase, ascii, snowball(english);
DEFINE INDEX idx_ft ON chunk FIELDS content FULLTEXT ANALYZER my_analyzer BM25;

-- Async events with bounded retries
DEFINE EVENT cascade ON document WHEN $event = "DELETE" ASYNC RETRY 3 THEN {
    DELETE FROM chunk WHERE document = $before.id
};
```

## SDK Patterns (Go)

### Transactions (v1.3.0+)

```go
tx, err := db.Begin(ctx)
if err != nil { return err }
defer tx.Cancel(ctx)

_, err = surrealdb.Query[any](ctx, tx, "DELETE FROM doc WHERE vault = $v", vars)
if err != nil { return err }

err = tx.Commit(ctx)
```

- `tx` satisfies same `sendable` interface as `db` — pass to `surrealdb.Query[T]()` directly
- WebSocket-only

### Error Types (v1.4.0+)

| Type | When | Key Fields |
|------|------|------------|
| `RPCError` | Transport failures | `Code`, `Message` |
| `QueryError` | `surrealdb.Query()` failures | `Message` only |
| `ServerError` | RPC method failures (`Create`, `Insert`, etc.) | `Kind`, `Details`, `Cause` |

Same DB error surfaces as different Go types depending on call path (Query vs RPC method).

### Batch INSERT

```go
rows := make([]map[string]any, len(items))
for i, item := range items {
    rows[i] = map[string]any{"field": item.Field}
}
surrealdb.Query(ctx, db, `INSERT INTO table $rows ON DUPLICATE KEY UPDATE id = id`, map[string]any{"rows": rows})
```

For `record<T>` fields: pass typed `surrealmodels.RecordID` values, not strings.

## Connection Best Practices

- Use `rews` (reconnecting websocket) for production
- Force HTTP/1.1 for WSS to prevent ALPN issues
- Use CBOR codec (`surrealcbor`) for proper type handling
- `surrealdb.New()` / `surrealdb.Connect()` deprecated → use `surrealdb.FromEndpointURLString()` or `surrealdb.FromConnection()`

## v3.0 Breaking Changes Summary

- `type::thing()` → `type::record()`, `rand::guid()` → `rand::id()`
- `DEFINE TOKEN` / `DEFINE SCOPE` removed
- `MTREE` index removed (use HNSW)
- `LET` keyword now mandatory
- `.id` idiom → `.id()` function
- v3.0.2 fixes: RRF scoring bug, parameterized BM25, DEFINE FUNCTION parse bug
