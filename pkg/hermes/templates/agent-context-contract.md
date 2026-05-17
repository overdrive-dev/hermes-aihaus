# hermes-aihaus Agent Context Contract

Agent definitions must not reference vague memory such as `frontend patterns` or `component tests` without a producer. Every context input must use one of these source prefixes.

## Source prefixes

- `target:<path>` — must be read from the target application repository if present, e.g. `target:AGENTS.md`, `target:README.md`, `target:docs/**`.
- `linear:<field>` — must be read from Linear, e.g. `linear:issue`, `linear:comments`, `linear:evidence`.
- `produced:<artifact>` — must be produced earlier in the hermes-aihaus pipeline, e.g. `produced:stack-profile`, `produced:behavior-contract`, `produced:coverage-matrix`, `produced:context-export`.
- `produced:stack-profile.<layer>.<field>` — layer evidence produced by stack discovery. Examples: `produced:stack-profile.frontend.patterns`, `produced:stack-profile.frontend.tests`, `produced:stack-profile.auth.actor-matrix`.
- `graph:<query>` — must be retrieved with `aih-graph query --hybrid <query>` from the target repository or hermes-aihaus package memory.
- `package:<path>` — packaged hermes-aihaus template/agent/skill path, e.g. `package:pkg/hermes/templates/coverage-matrix.md`.

## Required producer order

1. Intake produces/updates `linear:issue`.
2. Stack discovery produces `produced:stack-profile` and all `produced:stack-profile.*` layer fields.
3. Planning produces `produced:behavior-contract` and `produced:coverage-matrix`.
4. Execution produces RED/GREEN/regression evidence under `linear:evidence` and/or `produced:context-export`.
5. Review consumes all produced artifacts and may produce missing-coverage findings.

## Agent rule

If a `produced:*` context input is absent, the agent must either:

- invoke the producer stage first;
- block with a missing-context reason; or
- explicitly mark the field `not present in this repo` when stack discovery proves non-applicability.
