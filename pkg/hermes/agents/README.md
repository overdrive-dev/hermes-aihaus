# hermes-aihaus Hermes-native agents

These agents are Hermes-native role definitions derived from the legacy aihaus agent prompts. They are not restored Claude/Codex runtime trees.

## Rule

Generic agents are allowed only as orchestrators. Specialist agents must bind to:

- a production layer or stage;
- required hermes-aihaus skills;
- required memory/context inputs;
- real Stack Profile evidence from the target repository.

## Categories

- `orchestrators/` — intake, stack discovery, planning, execution, review coordination.
- `planning/` — business contract and architecture decisions.
- `layers/` — production-layer specialists.
- `review/` — coverage, integration, security, code quality, docs/memory review.

The installer copies this directory to `$HERMES_HOME/hermes-aihaus/agents`.
