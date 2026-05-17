---
name: hermes-aihaus-stack-discovery
description: "Discover the real full-stack architecture of a target repository and route agents to layer-specific skills before planning or execution."
version: 0.1.0
tags: [hermes-aihaus, stack-discovery, architecture, skills, routing]
---

# hermes-aihaus Stack Discovery

Use this skill before planning, execution, or review in a target application repository. Its job is to prevent generic agents from treating production software as only "frontend + backend".

## Production layers to inspect

Always classify evidence across these layers:

1. Frontend
2. APIs & Backend Logic
3. Database & Storage
4. Auth & Permissions
5. Hosting & Deployment
6. Cloud & Compute
7. CI/CD & Version Control
8. Security & RLS
9. Rate Limiting
10. Caching & CDN
11. Load Balancing & Scaling
12. Error Tracking & Logs
13. Availability & Recovery

## Discovery protocol

1. Read repo instructions first: `AGENTS.md`, `CLAUDE.md`, `README.md`, `docs/`, decisions, and existing plans.
2. Inspect manifests and config before choosing an agent identity: package files, framework config, Docker/IaC files, CI workflows, env examples, database migrations, auth config, observability config.
3. Inspect existing tests/specs and record the real test commands. Do not invent `pytest`, `npm test`, or `go test` if the repo uses something else.
4. Query `aih-graph` for prior decisions, gotchas, behavior contracts, and repo-specific service knowledge.
5. Fill `pkg/hermes/templates/stack-profile.md` or equivalent context with evidence per layer.
6. Fill all applicable `produced:stack-profile.*` fields defined in `pkg/hermes/templates/agent-context-contract.md` and `pkg/hermes/templates/stack-profile.md`.
7. Route each touched layer to an appropriate specialist agent from `pkg/hermes/agents/` and skills. If a skill is missing, name the missing skill explicitly instead of proceeding generically.

## Skill routing rules

- Frontend/UI changes must load frontend/framework/design/testing skills that match the repo evidence.
- API/backend changes must load backend framework, validation, API contract, and integration-test skills that match the repo evidence.
- Database/storage changes must load database/migration/ORM/RLS skills that match the repo evidence.
- Auth/security/RLS changes must load security and authorization-specific skills and require negative tests.
- Deployment/cloud/CI changes must load DevOps/provider/CI skills and require dry-run or config validation.
- Observability/reliability changes must load logging/error-tracking/availability skills and require failure-mode evidence.

## Output contract

Return a Stack Profile containing:

- actual services/frameworks detected with file-path evidence;
- test/spec commands detected with file-path evidence;
- touched production layers;
- required skills to load for each layer;
- Hermes-native agents/stages responsible for each layer, using `pkg/hermes/agents/` paths;
- produced context fields required by those agents;
- unknowns that block non-generic execution.

## Hard stops

Block instead of continuing if:

- the target repo's stack cannot be identified;
- a touched layer has no owner/agent/skill routing;
- required tests/specs cannot be found and no acceptable substitute is documented;
- auth, RLS, deployment, or data migration behavior is ambiguous.
