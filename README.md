<div align="center">

# hermes-aihaus

**Workflow-file package plus graph memory for feature delivery with Hermes Agent, Linear, and local project memory.**

You describe features. Hermes plans, records the behavior contract, keeps Linear updated, retrieves project memory through aih-graph, and executes with TDD discipline.

</div>

---

## What hermes-aihaus is

hermes-aihaus is not a renamed `aihaus` project. The name is intentional: it combines the workflow layer that Hermes runs with the graph-memory substrate that keeps project context queryable.

It is no longer a slash-command bundle for another coding runtime. It is a Hermes Agent workflow package:

- **Hermes Agent is the orchestrator.** hermes-aihaus ships Hermes skills, templates, and installer scripts.
- **Linear is the operational source of truth.** Planning, status, blockers, comments, and acceptance criteria live on Linear issues.
- **aih-graph is the local memory engine.** It uses SQLite + FTS5/BM25 by default and can opt into local Ollama embeddings for semantic retrieval without API keys.
- **TDD is mandatory for implementation.** Planning owns business-rule alignment; execution owns RED/GREEN evidence.
- **Context is compiled, not symlinked.** Hermes skills read the shared memory/contract substrate and can export native context for whichever implementation agent is used later.

## Package layout

```text
pkg/hermes/
├── agents/
│   ├── orchestrators/
│   ├── planning/
│   ├── layers/
│   └── review/
├── skills/
│   ├── hermes-aihaus-workflow/
│   ├── hermes-aihaus-stack-discovery/
│   ├── hermes-aihaus-linear-planning/
│   ├── hermes-aihaus-execution/
│   ├── hermes-aihaus-coverage-review/
│   └── hermes-aihaus-memory/
├── templates/
│   ├── behavior-contract.md
│   ├── context-export.md
│   ├── stack-profile.md
│   └── coverage-matrix.md
└── scripts/
    └── install.sh

aih-graph/
└── Go source for the packaged aih-graph binary: SQLite, FTS5/BM25, optional Ollama embeddings
```

## Install into Hermes

From this repository:

```bash
bash pkg/hermes/scripts/install.sh
```

The installer copies the hermes-aihaus workflow skills into `$HERMES_HOME/skills/hermes-aihaus/`, Hermes-native agent definitions into `$HERMES_HOME/hermes-aihaus/agents/`, templates into `$HERMES_HOME/hermes-aihaus/templates/`, and helper install/update scripts into `$HERMES_HOME/hermes-aihaus/scripts/`.
If `HERMES_HOME` is unset, the script asks `hermes config path` for the active Hermes home and falls back to `~/.hermes`.
When installing from source, it also builds/copies the `aih-graph` executable into `$HERMES_HOME/bin` when Go or a prebuilt package binary is available.
It also installs/updates Hermes runtime wiring: Python MCP SDK when missing, `mcp_servers.linear` using `npx -y @hatcloud/linear-mcp`, `${LINEAR_API_KEY}`/`${LINEAR_ACCESS_TOKEN}` credential interpolation, Ollama on Windows via the official `irm https://ollama.com/install.ps1 | iex` installer when missing, and optional Ollama `nomic-embed-text` preparation when Ollama is available.

Then start a fresh Hermes session and load the workflow skill when needed:

```bash
hermes -s hermes-aihaus-workflow
```

## Install into a target app repo for Hermes + Claude Code + Codex

After the package is installed into Hermes, export native agent-context surfaces into the application repository you want to work on:

```bash
# from this hermes-aihaus repository
bash pkg/hermes/scripts/install-target-adapters.sh /path/to/domus-nora-app
```

The target installer is idempotent and preserves existing project context files by inserting an `HERMES-AIHAUS` managed block. It creates/updates:

- `AGENTS.md` — Codex-native project context.
- `CLAUDE.md` — Claude Code-native project context.
- `.claude/skills/hermes-aihaus-*.md` — Claude Code procedure adapters generated from Hermes skills.
- `.claude/agents/hermes-aihaus-*.md` — Claude Code specialist agents generated from the Hermes role catalog.
- `.codex/prompts/hermes-aihaus-task.md` and `.codex/prompts/hermes-aihaus-review.md` — prompt bundles to paste/include with `codex exec`.
- `.hermes-aihaus/templates/` and `.hermes-aihaus/agents/` — shared package context used by all runtimes.
- Refreshed `aih-graph` index for the target repo, using semantic Ollama embeddings automatically when available and hybrid BM25/FTS5 otherwise.

Codex usage example from the target repo:

```bash
codex exec "$(cat .codex/prompts/hermes-aihaus-task.md)"
```

Claude Code usage example from the target repo:

```bash
claude -p "Use CLAUDE.md and .claude/skills/hermes-aihaus-workflow.md to plan this Linear issue: <url>" --max-turns 10
```

Hermes remains the orchestrator and Linear source-of-truth owner; Claude/Codex are implementation/review workers that consume the exported native context.

## Core workflow

1. **Intake** — user describes a feature conversationally.
2. **Stack discovery** — Hermes inspects the actual repo stack across frontend, APIs, database, auth, deployment, CI, security/RLS, rate limiting, caching/CDN, scaling, logs, and recovery before choosing agents/skills.
3. **Linear planning** — Hermes creates or updates a Linear issue, inspects the codebase, and writes a behavior contract plus coverage matrix.
4. **Memory retrieval** — Hermes queries aih-graph for related decisions, rules, gotchas, and previous contracts. Install/update refreshes the index automatically; agents refresh it themselves if stale.
5. **Execution** — Hermes runs a layer-specific TDD plan: RED test, GREEN implementation, refactor, verification.
6. **Adversarial review** — after TDD is green, a preferably distinct model/provider tries to falsify the implementation against the contract, evidence, security assumptions, and deployability.
7. **Automated tests** — Hermes moves the issue to `Testes`, runs the full relevant suite against the real target environment, and creates linked Linear follow-up tasks for unresolved failing-test clusters; those tasks are eligible for the same automatic workflow. Target repos may define environment-specific requirements; for Nora Care, `Testes` means dev/old-staging (`dev-api.noracare.com.br`) rather than local-only checks.
8. **Dev promotion** — only when TDD, adversarial review, and automated tests/operational checks are green, Hermes moves the issue to `Subida Dev` and runs or records the repo-specific dev deploy gate. For AWS CodePipeline-backed repos, use CodePipeline/CodeBuild, backend health, and frontend build metadata as the deploy signal when GitHub Actions is not authoritative.
9. **Review Dev** — after Dev promotion is verified, Hermes moves the issue to `Review Dev` for automated browser validation. The review agent must run Playwright against the Dev environment, verify the acceptance criteria from the behavior contract, capture screenshot/printscreen evidence for each relevant user-facing path, and attach or link those screenshots in a Linear evidence comment. If Playwright finds a regression or cannot prove the requested change, the issue returns to TDD or gets linked follow-up tasks instead of advancing.
10. **Human Review** — only after Playwright Review Dev passes may Hermes move the issue to `Human Review`. This is the human product gate: the user/domain reviewer checks the Linear evidence, screenshots, and release readiness. Automation must not approve this gate.
11. **Box Dev Features** — after human approval, the user/human reviewer moves the issue to `Box Dev Features` and applies a release/box code such as `#01` or `#02` as metadata (label/cycle), not as a new workflow state per release by default.
12. **Linear closeout** — Hermes comments status, blockers, evidence, Playwright screenshot links/attachments, follow-up links, and final result back to Linear throughout the workflow, not only at the end.

## Agent model

Legacy aihaus agents were converted into Hermes-native stage/layer definitions under `pkg/hermes/agents/`. Generic roles are allowed only as orchestrators. Specialist agents must bind to a production layer, required hermes-aihaus skills, required memory/context inputs, and real Stack Profile evidence from the target repository.

Examples:

- `orchestrators/hermes-aihaus-stack-discovery-orchestrator.md`
- `layers/hermes-aihaus-frontend-ui-agent.md`
- `layers/hermes-aihaus-backend-api-agent.md`
- `layers/hermes-aihaus-auth-permissions-rls-agent.md`
- `review/hermes-aihaus-test-spec-agent.md`
- `review/hermes-aihaus-integration-agent.md`

## Linear MCP and local memory

`pkg/hermes/scripts/install.sh` idempotently configures Hermes native MCP for Linear:

```yaml
mcp_servers:
  linear:
    command: npx
    args: ["-y", "@hatcloud/linear-mcp"]
    env:
      LINEAR_API_KEY: "${LINEAR_API_KEY}" # or "${LINEAR_ACCESS_TOKEN}" when that is the available secret
    timeout: 120
    connect_timeout: 120
```

On Windows, Ollama bootstrap uses the official installer (`irm https://ollama.com/install.ps1 | iex`) through `powershell.exe` when Ollama is missing; set `HERMES_AIHAUS_SKIP_OLLAMA_INSTALL=1` to skip that side effect. After a fresh session or `/reload-mcp`, Linear tools are exposed with the `mcp_linear_*` prefix. hermes-aihaus agents prefer those tools and only fall back to direct GraphQL when MCP is unavailable.

## Local memory modes

Default, no daemon, from any target repository such as an app repo:

```bash
aih-graph build --accept-all-repos .
aih-graph query --hybrid "business rule alignment"
```

Optional semantic retrieval with no API key:

```bash
ollama pull nomic-embed-text
aih-graph build --accept-all-repos --embed-provider ollama .
aih-graph query --semantic "tests before implementation"
```

Go is a development/build dependency for the `aih-graph` source in this package, not a runtime requirement for repositories that use hermes-aihaus after installation.

## Validation

```bash
bash tools/smoke-test.sh
cd aih-graph && go test ./...
```
