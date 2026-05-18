---
name: hermes-aihaus-linear-planning
description: "Produce Linear-backed behavior contracts before hermes-aihaus execution."
version: 0.1.0
tags: [hermes-aihaus, linear, planning, behavior-contract]
---

# hermes-aihaus Linear Planning

Use this skill before implementation when business behavior matters.

## Planning steps

1. Read the Linear issue, comments, labels, status, and linked context via Hermes Linear MCP (`mcp_linear_*`) when available; otherwise use the direct Linear GraphQL fallback. Do not ask the user to run Linear setup commands during planning.
2. Run `hermes-aihaus-stack-discovery` and attach or summarize the Stack Profile.
3. Inspect the real codebase for existing behavior and tests in every touched production layer.
4. Query aih-graph for related decisions and rules.
5. Fill the layer coverage section using `pkg/hermes/templates/coverage-matrix.md`.
6. Write or update the behavior contract using `pkg/hermes/templates/behavior-contract.md`.
7. Post a concise agreement summary to Linear.
8. When creating or renaming Linear issues, use user-facing/card-like titles that describe the visible problem or outcome in the user's language. Keep implementation details, root causes, table names, scripts, fixtures, commits, and environment mechanics in the description/comments, not the title. Example: prefer "Garantir que os usuários de teste consigam acessar o app após preparar o ambiente de dev" over "Dev seed: corrigir people.cognito_sub placeholder".
9. If behavior is ambiguous, block for human input instead of inventing rules.

## Required contract sections

- Problem/context
- Affected user/persona
- Agreed business rule
- Happy path
- Alternate flows
- Edge cases
- Permissions/authorization
- Existing behavior observed in code
- Stack profile and services detected
- Touched production layers
- Required layer agents and skills
- Acceptance criteria
- TDD strategy and expected RED tests
- Layer coverage matrix
- Out of scope
- Open questions

## Planning hard stops

- Backend/API work without identified framework, service boundaries, and integration-test command.
- Database/storage work without schema/migration/ORM evidence and rollback/fixture strategy.
- Auth/RLS/security work without actor matrix plus positive and negative tests.
- Deployment/cloud/CI work without config file evidence and validation/dry-run command.
- Observability/reliability work without logs/error/recovery expectations.


## Runtime assumptions

- The hermes-aihaus installer owns Linear MCP wiring: `mcp_servers.linear` should use `npx -y @hatcloud/linear-mcp` and credentials interpolated from `${LINEAR_API_KEY}` or `${LINEAR_ACCESS_TOKEN}`.
- Planning agents should prefer MCP for Linear reads/writes when the tools are discovered in the session, and fall back to the Linear GraphQL skill only when MCP is unavailable or unhealthy.
- Graph memory is refreshed by install/update and target adapter installation, but planning agents may rerun `aih-graph build` themselves when context is stale.
