# hermes-aihaus Decisions

## ADR-260517-A: hermes-aihaus is a Hermes Agent workflow plus graph memory package

Date: 2026-05-17
Status: Accepted

### Context

The previous package carried a large legacy runtime surface: slash-command skills, generated agent trees, plugin metadata, hooks, and installer machinery tied to non-Hermes runtimes. The new target is `hermes-aihaus`: a Hermes-native workflow-file package plus graph memory where the user discusses features and Hermes owns Linear orchestration, planning, memory retrieval, TDD execution, review, and closeout.

### Decision

Refactor the repository into the `hermes-aihaus` Hermes Agent workflow package. Remove the legacy package/runtime trees. Ship Hermes skills under `pkg/hermes/skills`, templates under `pkg/hermes/templates`, and a minimal installer under `pkg/hermes/scripts/install.sh`. Keep `aih-graph` as the local graph-memory engine and support local Ollama embeddings as an explicit semantic option.

### Consequences

+ The repository is smaller and aligned with the desired Hermes workflow.
+ Linear planning and behavior contracts become first-class.
+ aih-graph remains reusable for local memory without requiring cloud embeddings.
- Existing legacy package consumers must migrate to Hermes.
- Old smoke tests are replaced by Hermes-first validation.

## ADR-260517-B: Dev promotion flows through Playwright Review Dev then Human Review

Date: 2026-05-17
Status: Accepted

### Context

Nora Care delivery exposed three workflow gaps that must be package-level hermes-aihaus behavior, not one-off local memory: Linear must be updated at every gate, `Testes` must validate the real target environment rather than only local suites, and Dev product validation should be automated with browser evidence before the human reviewer spends attention. After successful Dev promotion, agents should prove the requested behavior with Playwright first; humans review the resulting evidence in a separate Linear gate.

### Decision

The automated hermes-aihaus delivery path is:

`Execução TDD` -> `Review pós-execução` -> `Testes` -> `Subida Dev` -> `Review Dev` -> `Human Review` -> `Box Dev Features`.

`Review Dev` is an automated Playwright gate. Hermes/agents may move an issue into `Review Dev` after verified Dev promotion evidence is attached, then must run Playwright against the Dev environment, validate the behavior-contract acceptance criteria, capture screenshot/printscreen evidence for relevant user-facing paths, and attach or link that evidence in Linear comments. If Playwright cannot prove the change, the issue returns to TDD or gets linked follow-up tasks. A passing Playwright review moves the issue to `Human Review`, which is the human product gate. Human-approved work moves to `Box Dev Features`. Release/box codes such as `#01` and `#02` are metadata (labels/cycles) on issues in `Box Dev Features`, not separate workflow states by default.

For target repos with environment-specific gates, `Testes` must run against the contract's real target environment. For Nora Care, that target is dev/old-staging (`dev-api.noracare.com.br`) unless an issue explicitly says otherwise. AWS CodePipeline/CodeBuild, backend health, and frontend build metadata are valid Dev promotion evidence when GitHub Actions is not authoritative.

### Consequences

+ Linear remains the operational source of truth throughout execution, not a final summary sink.
+ Human product validation is clearly separated from automated adversarial review and automated Playwright Dev review.
+ Release grouping stays flexible and avoids cluttering team-wide Linear workflow states.
- The workflow now requires target-repo-specific Dev evidence rules, Playwright routes/personas, and screenshot attachment/linking strategy to be captured in behavior contracts or Stack Profiles.


## ADR-260517-C: Install/update owns Linear MCP and graph-memory bootstrap

### Context

hermes-aihaus should not depend on the operator remembering separate setup commands for Linear MCP, graph indexing, or semantic memory. Agents also need the same assumptions embedded in their native prompts when exported to Claude Code or Codex.

### Decision

`pkg/hermes/scripts/install.sh` owns idempotent Hermes runtime setup: skills, templates, agents, `aih-graph`, Python MCP SDK when missing, Windows Ollama bootstrap through the official `irm https://ollama.com/install.ps1 | iex` installer when Ollama is absent, and `mcp_servers.linear` configured with `npx -y @hatcloud/linear-mcp` plus `${LINEAR_API_KEY}`/`${LINEAR_ACCESS_TOKEN}` interpolation. `pkg/hermes/scripts/install-target-adapters.sh` exports runtime-native context and refreshes the target repo graph automatically, using Ollama semantic embeddings when available and hybrid BM25/FTS5 otherwise. Agent definitions must instruct workers to prefer `mcp_linear_*` tools and to refresh/query `aih-graph` themselves instead of asking the user for setup commands.

### Consequences

+ Fresh installs and updates converge the Linear/MCP/memory runtime without extra manual commands.
+ Claude/Codex/Hermes exported agents carry the same Linear and graph-memory assumptions.
+ If credentials, Node/npx, Ollama, or `aih-graph` are missing, installers warn and agents fall back or block with durable evidence rather than silently pretending context exists.
