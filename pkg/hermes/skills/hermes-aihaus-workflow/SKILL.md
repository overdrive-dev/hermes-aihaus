---
name: hermes-aihaus-workflow
description: "Orchestrate the hermes-aihaus Hermes workflow: Linear planning, memory retrieval, TDD execution, review, and closeout."
version: 0.1.0
tags: [hermes-aihaus, hermes, linear, workflow, tdd, memory]
---

# hermes-aihaus Workflow

Use this skill when the user wants hermes-aihaus to turn a feature conversation into delivered work.

## Protocol

1. Load project context from `AGENTS.md`, `DECISIONS.md`, and aih-graph query results. The hermes-aihaus installers bootstrap `aih-graph`; agents must refresh/query memory themselves when the index is stale instead of asking the user for setup commands. Prefer semantic retrieval automatically when local Ollama `nomic-embed-text` is available; otherwise use hybrid BM25/FTS5.
2. Ensure the Linear issue exists or create/update it through Hermes Linear tooling/MCP. Prefer native Hermes MCP tools with the `mcp_linear_*` prefix when present; fall back to the direct Linear GraphQL skill only when MCP is unavailable. The package installer configures `mcp_servers.linear` with `npx -y @hatcloud/linear-mcp` and `${LINEAR_API_KEY}`/`${LINEAR_ACCESS_TOKEN}` interpolation. Before starting or advancing workflow gates, verify the issue has a project, owner/assignee, and one primary kind label (`Bug`, `Feature`, or `Improvement`, or the target workspace's equivalent); set the missing metadata first or block with a Linear comment.
3. Invoke `hermes-aihaus-stack-discovery` in the target repo before choosing implementation agents. The result must name real services/frameworks, test commands, touched production layers, required skills, and Hermes-native agent definitions from `pkg/hermes/agents/`.
4. Invoke `hermes-aihaus-linear-planning` to produce a behavior contract before implementation.
5. Invoke `hermes-aihaus-memory` to retrieve related rules, decisions, prior gotchas, and contracts.
6. Invoke `hermes-aihaus-execution` for strict TDD implementation with layer-specific agents and skills from the Stack Profile.
7. After TDD evidence is GREEN, run an adversarial post-execution review before promotion. Use a distinct model/provider from the planner/implementer when Hermes configuration makes that possible, and make the reviewer actively try to falsify the behavior contract, test evidence, security assumptions, and deployment readiness.
8. Move through the Linear pipeline explicitly: `Execução TDD` -> `Review pós-execução` -> `Testes` -> `Subida Dev` -> `Review Dev` -> `Human Review` -> `Box Dev Features`. Update Linear at each stage transition as soon as it happens; do not wait until the end of a batch or rely on a local todo/commit log as the source of truth. Do not skip the review or test stage just because local changes look small.
9. In `Testes`, run the full relevant automated suite named by the Stack Profile/Behavior Contract against the contract's real target environment, not merely local tests. For Nora Care, the Testes target is the development environment (the old staging backend/environment: `dev` / `dev-api.noracare.com.br`) unless the issue explicitly says otherwise. If tests fail, create Linear follow-up tasks for each distinct failure/root-cause cluster with failing command, excerpt, owner layer, and relation to the parent issue; route those tasks back through the same automated flow. Retry the parent only after the child tasks are resolved or explicitly marked non-blocking with evidence.
10. Only move to `Subida Dev` when TDD evidence, adversarial review, and automated tests/operational environment checks are all green. Comment exact evidence and final status back to Linear, including commit SHA, pipeline/build IDs, target URLs, and any explicitly non-applicable smoke lanes.
11. After Dev promotion is verified, move the issue to `Review Dev` and run automated Playwright validation against the Dev environment named by the behavior contract/Stack Profile. The Playwright reviewer must exercise the requested user-facing paths, verify the acceptance criteria, capture screenshot/printscreen evidence for each relevant pass/fail path, and attach or link those screenshots in a Linear evidence comment (prefer Linear `attachmentCreate`/MCP attachment support when available; otherwise upload/link an accessible CI or artifact URL in the comment). If Playwright fails, cannot authenticate, or cannot prove the requested behavior, do not advance: return to TDD or create linked follow-up tasks with the trace, screenshot, console/network errors, and responsible layer. Only after Playwright Review Dev passes may Hermes move the issue to `Human Review`; `Human Review` is the human product gate before `Box Dev Features`. If the human reviewer approves, the human/user moves the issue to `Box Dev Features` and applies the release/box code as metadata such as label or cycle `#01`, `#02`, etc. Do not create one workflow state per release code by default.

## Production-layer model

Do not treat work as generic "frontend/backend". Classify and route by the production layers below, based on real repo evidence:

- Frontend
- APIs & Backend Logic
- Database & Storage
- Auth & Permissions
- Hosting & Deployment
- Cloud & Compute
- CI/CD & Version Control
- Security & RLS
- Rate Limiting
- Caching & CDN
- Load Balancing & Scaling
- Error Tracking & Logs
- Availability & Recovery

Every touched layer needs an owner agent, required skills, acceptance criteria, test/spec evidence, and operational verification or explicit non-applicability.

## Agent routing

Use `pkg/hermes/agents/` as the role catalog:

- generic coordination roles must come from `agents/orchestrators/`;
- planning roles must come from `agents/planning/` and produce contracts/ADRs, not code;
- implementation roles must come from `agents/layers/` and be selected by Stack Profile evidence;
- review roles must come from `agents/review/` and verify coverage/evidence.

Do not dispatch a generic `frontend` or `backend` worker without first narrowing it to the actual repo framework/services and loading the skills/memory named by the chosen agent definition.

Resolve agent `required_memory` through `pkg/hermes/templates/agent-context-contract.md`. Entries prefixed with `produced:` must be created by earlier pipeline stages; entries prefixed with `graph:` must come from `aih-graph`; entries prefixed with `target:` must be read from the target repo. Missing produced context is a blocker unless stack discovery marks it `not present in this repo`.

## Non-negotiables

- Do not execute ambiguous business behavior.
- Do not dispatch generic agents when stack-specific skills or repo evidence are available.
- Do not skip RED/GREEN evidence.
- Do not accept "tests pass" without exact test names/commands mapped to touched layers.
- Do not promote to Dev without adversarial post-TDD review plus automated test evidence.
- Do not skip Playwright `Review Dev`; it is the automated browser-evidence gate before `Human Review`. Do not auto-approve `Human Review`; it is the human gate before `Box Dev Features`.
- Do not hide failing tests inside a summary; create and link Linear follow-up tasks for unresolved failures, and let those tasks run automatically through the same workflow.
- Do not create workflow states such as `Box Dev #01` / `Box Dev #02` by default; use `Box Dev Features` plus release metadata labels/cycles for the code.
- Keep technical blockers separate from human-input blockers.
- Treat Linear as the operational source of truth; use Linear MCP automatically when available and never ask the user to run separate Linear setup during an hermes-aihaus task.
- Do not leave Linear issues without required operating metadata: project, owner/assignee, and one primary kind label (`Bug`, `Feature`, or `Improvement`, or the target workspace's equivalent) are mandatory for intake, planning, execution, review, and follow-up tasks.
