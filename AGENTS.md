# AGENTS.md

This repository is the `hermes-aihaus` workflow-file package plus graph-memory substrate. Preserve the project name `hermes-aihaus`; do not shorten or rename it to `aihaus`.

## Runtime stance

- Hermes Agent is the orchestrator and target runtime.
- Linear is the source of truth for issues, status, blockers, comments, and acceptance criteria. The package installer must keep Hermes Linear MCP configured with `npx -y @hatcloud/linear-mcp`; agents prefer `mcp_linear_*` tools and fall back to direct GraphQL only when MCP is unavailable.
- aih-graph is the local memory engine. Keep it lightweight: SQLite + FTS5/BM25 by default, optional Ollama embeddings. Install/update and target adapters should refresh the graph automatically so agents do not require manual setup commands.
- Do not reintroduce legacy slash-command package trees or generated runtime directories.

## Editing rules

- Shipped Hermes skills live in `pkg/hermes/skills/<name>/SKILL.md`.
- Hermes-native agent definitions live in `pkg/hermes/agents/<category>/<name>.md`.
- Generic agent definitions are allowed only under `pkg/hermes/agents/orchestrators/`; layer/review/planning agents must name required skills, required memory/context, and production-layer evidence.
- Templates live in `pkg/hermes/templates/`.
- Installer scripts live in `pkg/hermes/scripts/` and must pass `bash -n`. They own idempotent runtime setup for hermes-aihaus skills/agents/templates, `aih-graph`, Linear MCP, official Windows Ollama bootstrap (`irm https://ollama.com/install.ps1 | iex` via PowerShell), and target-repo graph refresh.
- aih-graph remains a Go module under `aih-graph/`.
- Target application repositories must not need Go to use hermes-aihaus; Go is only for developing/building the packaged `aih-graph` binary.
- Validate with `bash tools/smoke-test.sh` and `cd aih-graph && go test ./...`.

## Workflow contract

Planning must inspect real code and produce a behavior contract before execution. Execution must preserve TDD evidence: failing test first, passing test after implementation, and final regression verification. After TDD is green, run adversarial post-execution review with a distinct model/provider when available, then run the relevant automated test suite against the target repo's real test environment before promotion. Unresolved failing tests must become linked Linear follow-up tasks that can run through the same automatic workflow. Only promote to Dev when TDD, review, and tests/operational checks are green. After Dev promotion is verified, move the issue to `Review Dev` for automated Playwright validation against the Dev environment. Playwright review must verify behavior-contract acceptance criteria, capture screenshot/printscreen evidence, and attach or link those screenshots in Linear comments. Only a passing Playwright review may advance to `Human Review`; `Human Review` is the human product gate before `Box Dev Features`. Human-approved work moves to `Box Dev Features` with release metadata such as `#01`/`#02` labels or cycles, not one workflow state per release code by default.

Before planning or execution, run stack discovery for the target repo and route work by production layer: frontend, APIs/backend logic, database/storage, auth/permissions, hosting/deployment, cloud/compute, CI/CD, security/RLS, rate limiting, caching/CDN, load balancing/scaling, error tracking/logs, and availability/recovery. Do not use generic agents when repo-specific services, commands, or skills can be identified.
