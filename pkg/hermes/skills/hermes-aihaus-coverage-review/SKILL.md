---
name: hermes-aihaus-coverage-review
description: "Review an hermes-aihaus plan or implementation for full-stack specification, test, security, deployment, and reliability coverage."
version: 0.1.0
tags: [hermes-aihaus, review, coverage, testing, security, reliability]
---

# hermes-aihaus Coverage Review

Use this skill after planning, after implementation, and before Dev promotion. It turns the production-stack layers into a review checklist so agents do not approve shallow frontend/backend-only work.

## Required inputs

- Linear issue and comments
- Behavior contract
- Stack Profile from `hermes-aihaus-stack-discovery`
- Coverage Matrix from `pkg/hermes/templates/coverage-matrix.md`
- Test/verification evidence from execution
- Git diff or changed file list
- Linear workflow state and intended next state
- Failed-test follow-up tasks and relations, when any suite is not green

## Review stages

### 1. Spec coverage review

For every touched layer, verify that the behavior contract says:

- what changes;
- who/what is affected;
- success behavior;
- failure/denial behavior;
- data/storage impact;
- permissions/security impact;
- deployment/config impact;
- observability/recovery expectations;
- explicit out-of-scope boundaries.

### 2. Test coverage review

For every touched layer, verify that tests match the layer:

- Frontend: component/interaction/e2e as appropriate.
- Backend/API: unit plus integration/API tests for request/response and errors.
- Database/storage: migration/schema/repository tests.
- Auth/RLS/security: positive and negative permission tests.
- Rate limiting/cache/retry/recovery: boundary and failure-mode tests.
- CI/deployment/config: validation/dry-run/build checks.

Reject generic evidence such as "tests pass" unless the exact commands and relevant test names are included.

### 3. Skill routing review

Verify that each implementation/review agent loaded the skills named in the Stack Profile. If a required skill did not exist, verify that the missing skill was recorded as a gap and that the agent compensated with explicit code inspection and commands.

### 4. Operational readiness review

For production-facing layers, require evidence for:

- logs/error handling;
- secrets/env/config safety;
- rollback or recovery path;
- deployment/CI impact;
- monitoring/alerts when applicable.

### 5. Adversarial promotion review

Before an issue may leave `Review pós-execução` or `Testes`, actively try to falsify the implementation:

- identify acceptance criteria that were not proven by RED/GREEN tests;
- challenge happy-path-only evidence and require negative/edge tests where the layer demands them;
- verify failed test logs were either fixed or split into Linear follow-up tasks with blocking status and relations;
- verify parent issues are not moved to `Subida Dev` while blocking child failures remain;
- prefer a reviewer model/provider distinct from the planner and implementer when Hermes configuration makes that possible.

## Output format

Return:

- Verdict: APPROVE / REQUEST CHANGES / BLOCKED
- Missing coverage by layer
- Missing or wrong tests/specs
- Missing skill routing
- Required Linear comment
- Exact next actions
- Promotion decision: stay in current state / return to TDD / create follow-up tasks / move to `Subida Dev` / move to `Review Dev` after verified Dev promotion

## Block conditions

Block if any touched layer lacks acceptance criteria, tests or verification, responsible agent/skill routing, or explicit non-applicability rationale. Also block promotion to `Subida Dev` if adversarial review is missing, automated test evidence is missing, target-environment operational evidence is missing, or unresolved failing tests do not have linked Linear follow-up tasks with clear owner layer and blocking status. `Review Dev` is a human gate after Dev promotion; automation may move an issue there with evidence but must not approve it or advance it to `Box Dev Features`.
