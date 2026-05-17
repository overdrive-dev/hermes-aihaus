# aih-graph PRD

**Project:** aih-graph — local graph-memory engine for hermes-aihaus
**Status:** active substrate

## Goal

Provide fast local retrieval for hermes-aihaus project memory without requiring a cloud embedding API.

## Current scope

- Parse repository-level `DECISIONS.md` into Decision nodes.
- Parse Hermes skills from `pkg/hermes/skills/*/SKILL.md` into Skill nodes.
- Parse Hermes shell scripts from `pkg/hermes/scripts/*.sh` into Hook nodes.
- Store nodes and edges in SQLite through the existing pure-Go `modernc.org/sqlite` stack.
- Index canonical node text with SQLite FTS5/BM25 by default.
- Optionally persist local semantic embeddings from Ollama `nomic-embed-text`.
- Query with structural, semantic, and hybrid modes.

## Non-goals

- Replace Linear as the operational source of truth.
- Require an embedding API key.
- Require Graphiti, Neo4j, FalkorDB, or a daemon for default lexical retrieval.
- Recreate legacy runtime-specific package trees.

## CLI

```bash
aih-graph build --accept-all-repos .
aih-graph query --hybrid "behavior contract"
aih-graph build --accept-all-repos --embed-provider ollama .
aih-graph query --semantic "tests before implementation"
```

## Acceptance checks

- `go test ./...` passes in `aih-graph/`.
- Building the repository indexes at least `Decision`, `Skill`, and package script nodes.
- Default build works with no API key and no Ollama daemon.
- Ollama mode is explicit via `--embed-provider ollama`.
