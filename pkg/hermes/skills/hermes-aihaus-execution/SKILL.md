---
name: hermes-aihaus-execution
description: "Execute an hermes-aihaus behavior contract with strict TDD and Linear evidence updates."
version: 0.1.0
tags: [hermes-aihaus, tdd, execution, verification]
---

# hermes-aihaus Execution

Use this skill only after a behavior contract exists.

Before writing tests or code, load the Stack Profile produced by `hermes-aihaus-stack-discovery`. Execution agents must be layer-specific: frontend, backend/API, data/storage, auth/security, deployment/CI, observability/reliability, or another explicit role justified by repo evidence.

## TDD loop

1. Write the smallest failing test for one acceptance criterion.
2. Map that test to the touched production layer and responsible skill/agent.
3. Run the specific test and capture RED evidence.
4. Implement the minimum production code needed to pass.
5. Run the specific test and capture GREEN evidence.
6. Refactor only while tests stay green.
7. Run the relevant layer regression suite plus cross-layer checks named in the behavior contract.
8. Move the Linear issue to `Review pós-execução` and run an adversarial review with a different model/provider when available. The reviewer must try to disprove the implementation against the behavior contract, RED/GREEN evidence, layer coverage, security/permissions assumptions, and deployability.
9. If adversarial review requests changes, return to the smallest failing test first and repeat RED -> GREEN -> REFACTOR.
10. Move the issue to `Testes` and run the full relevant automated suite against the behavior contract's real target environment. For Nora Care, Testes means validating against the development environment (old staging backend/environment: `dev` / `dev-api.noracare.com.br`) unless the issue explicitly says otherwise; local tests alone are insufficient for promotion. When any test fails, cluster failures by likely root cause and create/link Linear child or related tasks for each unresolved cluster, including the command, failing test names, log excerpt, responsible layer, and whether the parent is blocked. Those tasks must be eligible for the same automated hermes-aihaus pipeline.
11. Only after TDD, adversarial review, and automated tests/target-environment operational checks are green, move the issue to `Subida Dev` and execute the repo-specific dev deploy/promotion command or record an explicit non-applicability reason. For AWS CodePipeline-backed repos, GitHub Actions failures caused by account billing/spending-limit pre-start annotations are not the deploy signal; use the documented CodePipeline/CodeBuild state, backend health endpoint, and frontend build metadata as promotion evidence. If the repository working tree is dirty with unrelated artifacts, do not treat that as approval to deploy the entire tree; either isolate/stage the issue-specific changeset or leave an explicit Linear comment that promotion applies only to the isolated changeset and that unrelated local files remain out of scope.
12. After Dev promotion is verified, move the issue to `Review Dev` and run automated Playwright validation against the Dev environment. Use the behavior contract to select routes, personas, assertions, and screenshots. Capture screenshot/printscreen evidence for the requested change and any critical before/after or error path; attach or link those screenshots in a Linear evidence comment (prefer Linear `attachmentCreate`/MCP attachment support when available; otherwise upload/link an accessible CI or artifact URL). If Playwright passes and the requested behavior is proven, move the issue to `Human Review`. If Playwright fails, cannot authenticate, or finds mismatch, return to TDD or create linked Linear follow-up tasks with trace/screenshot/console/network evidence and keep the parent out of `Human Review`.
13. `Human Review` is the human product gate; Hermes/agents must not auto-approve it. If the human reviewer approves, the human/user moves the issue to `Box Dev Features` and applies the release/box code as metadata such as label or cycle `#01`, `#02`, etc.
14. Comment evidence back to Linear immediately after each stage transition or gate result; Linear is the operational source of truth, not a final after-action summary.

## Post-TDD promotion gates

- `Review pós-execução`: required after the implementation's TDD loop is green; use an adversarial reviewer and prefer model/provider separation.
- `Testes`: required after review approval; run exact commands from the Stack Profile/Behavior Contract, not ad hoc smoke claims.
- Failed tests: do not bury failures in parent comments only. Create Linear follow-up tasks with first-class relations to the parent and enough evidence for automatic execution.
- `Subida Dev`: allowed only when no blocking failures remain and review/test evidence is attached to Linear.
- `Review Dev`: automated Playwright browser-evidence gate after successful Dev promotion. It must validate behavior-contract acceptance criteria on Dev and attach/link screenshot evidence in Linear comments before any human gate.
- `Human Review`: human product gate after Playwright Review Dev passes. Automation stops here and must not approve it.
- `Box Dev Features`: human-approved holding box for features selected for a dev release/box; use release metadata labels/cycles (`#01`, `#02`) instead of creating one workflow state per release code by default.

## Layer-specific execution requirements

- Frontend: cover user-visible state, validation copy, accessibility expectations, and route/component behavior.
- APIs & Backend Logic: cover request/response, service rules, error cases, idempotency, and integration boundaries.
- Database & Storage: cover migrations, constraints, repository behavior, fixtures/seeds, and rollback when applicable.
- Auth & Permissions / Security & RLS: cover allowed and denied actors, row/policy boundaries, and secret handling.
- Rate Limiting / Caching & CDN / Scaling: cover boundary behavior, cache keys/invalidation, concurrency or retry semantics when touched.
- Hosting / Cloud / CI/CD: validate config, build, workflow, deploy dry-run, or explicit non-applicability.
- Error Tracking & Logs / Availability & Recovery: exercise failure paths and prove logs/recovery behavior where code-owned.

## Blockers

- Technical transient blocker: retry with a bounded cap and record attempts.
- Technical non-retryable blocker: leave visible with durable reason and evidence.
- Human-input blocker: ask the user/domain owner and do not proceed with guessed behavior.
