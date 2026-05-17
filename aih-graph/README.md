# aih-graph

Standalone Go binary graph-memory engine for [hermes-aihaus](https://github.com/overdrive-dev/hermes-aihaus).

**Status:** v0.1.5-dev (shipped M033–M046 plus local Ollama embedding provider; markdown extraction + modernc/sqlite storage + 3 query modes + BM25/FTS5 lexical search + native CC agent-memory indexing + 4-platform binary release).

## What this is

aih-graph is the **memory + structural retrieval engine** hermes-aihaus uses as its graph-memory substrate. It builds a queryable knowledge graph of hermes-aihaus-managed repositories with **first-class ontological types** for workflow and memory concepts (Decision, Milestone, Story, Agent, Hook, Skill).

This is intentionally **narrower than graphify-the-tool**. v0.1 forever-scope:
- **Markdown-only extraction** for 6 hermes-aihaus typed nodes (Decision/Milestone/Story/Agent/Hook/Skill) — per ADR-260515-C-amend-02
- **modernc.org/sqlite storage** (pure-Go, no CGO) — per ADR-260515-B-amend-02
- **Lexical search via BM25/FTS5** (pure-Go offline, zero API keys, zero model downloads) — default per ADR-260515-B-amend-02 + ADR-260516-A. Optional vector providers are wired for explicit opt-in, including local Ollama (`nomic-embed-text`) with no API key.
- **Three query modes:** structural BFS, vector similarity (`--semantic`), hybrid
- **Pure-Go single binary** — zero CGO requirement, works on any platform Go supports

Out of scope for v0.1 (use graphify in parallel if needed):
- AST extraction for code files (Python/JS/Go/bash/PowerShell) — deferred to v0.2+ when CGO ecosystem matures or pure-Go tree-sitter port emerges
- Symbol/File generic node types for code — paired with above
- Semantic LLM extraction (paid LLM-driven node/edge extraction — distinct from embeddings)
- Clustering (Leiden community detection)
- HNSW/IVF vector indexes (brute-force only; sufficient for target repos up to ~500k nodes)
- LLM re-ranking (`--rerank` deferred to v0.2+)
- Local-ONNX embedding provider — deferred indefinitely (would re-introduce CGO; pure-Go transformer inference not production-grade today)

## Status

**v0.1.1 — shipped.** Markdown extraction across 6 hermes-aihaus types + modernc/sqlite storage + 3 query modes + BM25/FTS5 lexical search + 4-platform binary release.

Shipped milestone chain:
- M033: Markdown extraction (6 type parsers)
- M034: modernc/sqlite storage
- M035: Query (BFS/semantic/hybrid) + typed accessors + embedding pipeline
- M036: Privacy gates (XDG storage, isolation, consent, purge, NDA opt-out)
- M037: CI cross-compile (4 platforms)
- M038: v0.1.0 release
- M039: hermes-aihaus integration (install.sh, hooks, agent prompts)
- M040: Smoke checks + hermes-aihaus v0.35.0 release
- M041: BM25/FTS5 lexical search default; one-shot install; tag v0.1.1
- M041 dogfood: query --db default + hybrid BM25 routing + var-version ldflag fix; tag v0.1.2
- M042: Voyage demotion from advertised surfaces; CLI/PRD/README reconciliation; tag v0.1.3
- M046: Agent memory indexing — `.claude/agent-memory/<name>/MEMORY.md` excerpts (200 lines / 25KB cap matching native CC) injected into Agent node properties; tag v0.1.4

## Verifying the memory engine

After `aih-graph build --accept-all-repos .` has built the index for at least one project, you can verify the binary, the DB file, and the query pipeline in three steps.

**1. Binary present and reports version:**
```
aih-graph version
```
Should print `v0.1.3` (or higher). If the binary is absent: `bash pkg/scripts/install-aih-graph-binary.sh` re-downloads it from GitHub Releases.

**2. DB file exists on disk** (per-repo isolated, XDG-scoped):

| Platform | Path |
|----------|------|
| Linux | `$XDG_STATE_HOME/aih-graph/<sha256-hex-16>/graph.db` (default: `~/.local/state/aih-graph/...`) |
| macOS | `~/Library/Application Support/aih-graph/<sha256-hex-16>/graph.db` |
| Windows | `%LOCALAPPDATA%\aih-graph\<sha256-hex-16>\graph.db` |

The 16-hex subfolder is the SHA-256 prefix of the absolute repo path — one subfolder per repo. Override the location with the `AIH_GRAPH_HOME` env var.

**3. Query returns scored results:**
```
aih-graph query --hybrid "decision"
```
A healthy index returns at least one `[s=N.NN]` line, for example:
```
[s=5.42] Decision   ADR-260515-E-amend-02   v0.1 forever-scope: vector promoted...
[s=4.72] Hook       aih-graph-refresh.sh    aih-graph-refresh.sh — refresh...
```

Use `--semantic` (vector-only, when an embedding provider is configured) or `--bfs <exact-identifier>` (structural lookup) instead of `--hybrid` for narrower queries.

### Optional local semantic embeddings with Ollama

BM25/FTS5 remains the default because it is offline, fast, and requires no daemon. To add local semantic embeddings, run Ollama with an embedding model and opt in during build:

```
ollama pull nomic-embed-text
aih-graph build --accept-all-repos --embed-provider ollama .
aih-graph query --semantic "testing before implementation"
```

Defaults:
- endpoint: `$OLLAMA_HOST` if set, otherwise `http://localhost:11434`
- model: `nomic-embed-text`
- dimensions: `768`

This path keeps memory local: text is sent only to the local Ollama daemon, then stored as vector BLOBs in the per-repo SQLite database. No API key is required.

### Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `no node matches identifier "..."` | Used the default mode (identifier exact-match) on free-text input | Pass `--hybrid` or `--semantic` |
| `consent gate: missing .aih-graph-consent` | Repo not opted-in to indexing | `aih-graph build --accept-all-repos .` |
| `database is locked` | Another process writing to the DB | Wait a few seconds and retry |
| Build prints `0 nodes` | `DECISIONS.md` and Hermes skill package have no indexable records | Verify this is an hermes-aihaus Hermes workflow repo |
| `aih-graph: command not found` | Binary not on PATH and discovery chain failed | Run from source with `go run ./aih-graph/cmd/aih-graph` or build the binary |

## Specs

Authoritative design package in `DECISIONS.md`:
- ADR-260515-A — privacy contract
- ADR-260515-B — Node/Edge data model (hybrid generic+typed)
- ADR-260515-C — tree-sitter binding (provisional + M033 pre-flight gate; amended by C-amend-01)
- ADR-260515-D — integration model (tight, monorepo)
- ADR-260515-E — v0.1 forever-scope

Full PRD at `aih-graph/PRD.md`.

## License

MIT — see `LICENSE`.
