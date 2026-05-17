# hermes-aihaus Coverage Matrix

Use this matrix before implementation and again before review. Every changed layer needs specification coverage, automated tests, and operational verification appropriate to that layer.

| Layer | Spec/contract required | Minimum automated coverage | Operational evidence | Review owner |
| --- | --- | --- | --- | --- |
| Frontend | User flow, states, validation copy, accessibility expectation | Component/unit tests plus interaction/e2e when behavior crosses routes | Screenshot or local UI verification when UI changes | Frontend/UI agent |
| APIs & Backend Logic | Endpoint/service contract, request/response, error semantics | Unit + integration/API tests for happy path, errors, idempotency where relevant | Local API command/log proving route/service works | Backend/API agent |
| Database & Storage | Schema/data migration contract, constraints, retention | Migration test or repository integration test; seed/fixture validation | Migration dry run or DB inspection | Data/storage agent |
| Auth & Permissions | Actor matrix, role rules, denial semantics | Positive and negative permission tests | Evidence that unauthorized path fails | Auth/security agent |
| Hosting & Deployment | Runtime/env contract, deploy target, config changes | Config validation/build smoke | Deployment preview or dry-run output | Deployment agent |
| Cloud & Compute | Provider resources, IAM/env dependency, cost/scaling assumption | IaC/config validation where present | Provider/dry-run output or explicit not applicable | Cloud agent |
| CI/CD & Version Control | Required checks, branch/release behavior | CI workflow validation or local equivalent | CI status/check command | CI agent |
| Security & RLS | Threat boundary, RLS/policy rules, secret handling | Abuse-case tests, RLS negative tests, secret-scan where available | Security review notes and policy evidence | Security agent |
| Rate Limiting | Limit key, thresholds, bypass/admin semantics | Tests for allowed, limited, reset/window behavior | Logs/headers proving limit behavior when possible | Backend/security agent |
| Caching & CDN | Cache key, invalidation, TTL, stale behavior | Tests for hit/miss/invalidation when code-owned | Header/config evidence | Performance agent |
| Load Balancing & Scaling | Concurrency/scaling assumption, statelessness | Concurrency or queue behavior tests when touched | Capacity note or non-applicability | Reliability agent |
| Error Tracking & Logs | Error taxonomy, log fields, alert/noise rules | Test/log assertion for new failure paths | Example log/error event or local substitute | Observability agent |
| Availability & Recovery | Failure mode, retry/rollback/recovery behavior | Recovery/retry tests for touched behavior | Rollback/recovery note | Reliability agent |

## Exit rule

No execution handoff is complete until every touched layer has:

- explicit acceptance criteria;
- specific RED tests to write first or an explicit reason no code test applies;
- verification commands;
- responsible stage agent/skill routing;
- open risks or blockers posted back to Linear.
