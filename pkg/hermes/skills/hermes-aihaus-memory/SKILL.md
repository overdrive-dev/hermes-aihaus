---
name: hermes-aihaus-memory
description: "Query and refresh hermes-aihaus local memory through aih-graph SQLite/FTS5/Ollama retrieval."
version: 0.1.0
tags: [hermes-aihaus, memory, sqlite, fts5, ollama]
---

# hermes-aihaus Memory

Use this skill whenever hermes-aihaus needs project context beyond the current chat.


## Automatic bootstrap

`pkg/hermes/scripts/install.sh` installs/updates the packaged `aih-graph` binary into `$HERMES_HOME/bin`, installs Ollama on Windows through the official `irm https://ollama.com/install.ps1 | iex` path when missing, and prepares optional Ollama semantic retrieval when Ollama is present. `pkg/hermes/scripts/install-target-adapters.sh <target-repo>` refreshes the target repository index automatically after exporting native context.

Agents must treat graph refresh as their own prerequisite: if retrieval looks stale or missing, run the appropriate `aih-graph build` command directly and continue. Do not stop to ask the user to run setup commands unless the binary, target repo, or credentials are genuinely unavailable.

## Retrieval

Prefer semantic retrieval when local Ollama `nomic-embed-text` is available; otherwise use hybrid lexical search by default:

```bash
aih-graph build --accept-all-repos .
aih-graph query --hybrid "<question>"
```

If local Ollama embeddings are installed and the user wants semantic retrieval:

```bash
aih-graph build --accept-all-repos --embed-provider ollama .
aih-graph query --semantic "<question>"
```

## Runtime dependency boundary

Do not require Go in target application repositories. Go is only needed when developing or building the `aih-graph` binary inside the `hermes-aihaus` package. Installed workflows should call the packaged `aih-graph` executable from PATH or `$HERMES_HOME/bin/aih-graph`.

## Context compiler rule

Do not rely on raw symlinks as the source of truth. Compile context from the shared contract/memory substrate into the runtime-native form each agent needs.
