# Ollama semantic bootstrap on Windows

Use this reference when hermes-aihaus needs local semantic `aih-graph` retrieval on Windows.

## Official install path

The preferred Windows installer is the official Ollama script:

```powershell
irm https://ollama.com/install.ps1 | iex
```

From hermes-aihaus's Git Bash installer, invoke it through PowerShell:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://ollama.com/install.ps1 | iex"
```

`pkg/hermes/scripts/install.sh` does this automatically on Windows when Ollama is missing, unless `HERMES_AIHAUS_SKIP_OLLAMA_INSTALL=1` is set.

## Known-good local verification

```bash
/c/Users/vctrs/AppData/Local/Programs/Ollama/ollama.exe --version
/c/Users/vctrs/AppData/Local/Programs/Ollama/ollama.exe pull nomic-embed-text
/c/Users/vctrs/AppData/Local/Programs/Ollama/ollama.exe list
```

Expected embedding model:

- `nomic-embed-text:latest`
- provider/model in aih-graph output: `ollama:nomic-embed-text`

## Rebuild and verify semantic index

```bash
aih-graph build --accept-all-repos --embed-provider ollama .
aih-graph query --semantic "Linear MCP graph memory automatic install"
```

When reporting readiness, include the number of nodes with embeddings from the SQLite DB or build output.
