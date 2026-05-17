#!/usr/bin/env bash
# hermes-aihaus Hermes workflow smoke test.
# Validates that the shipped package is Hermes-first and no longer the legacy
# Claude/Codex slash-command bundle.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PKG="$ROOT/pkg"
FAILURES=0
CHECKS=0

pass() { CHECKS=$((CHECKS + 1)); printf '[PASS] %s\n' "$1"; }
fail() { CHECKS=$((CHECKS + 1)); FAILURES=$((FAILURES + 1)); printf '[FAIL] %s\n' "$1"; shift; for line in "$@"; do printf '       %s\n' "$line"; done; }
require_file() { [[ -f "$1" ]] && pass "$2" || fail "$2" "missing: $1"; }
require_dir() { [[ -d "$1" ]] && pass "$2" || fail "$2" "missing: $1"; }
reject_path() { [[ ! -e "$1" ]] && pass "$2" || fail "$2" "legacy path still exists: $1"; }
require_grep() { grep -qE "$1" "$2" 2>/dev/null && pass "$3" || fail "$3" "pattern not found: $1 in $2"; }
reject_grep() { ! grep -rIEqi "$1" "$2" 2>/dev/null && pass "$3" || fail "$3" "forbidden pattern found: $1 under $2"; }

printf 'hermes-aihaus Hermes workflow smoke test\n'
printf 'Root: %s\n\n' "$ROOT"

require_file "$ROOT/README.md" 'README exists'
require_grep '^# hermes-aihaus$' "$ROOT/README.md" 'README preserves hermes-aihaus project name'
require_grep 'Hermes Agent' "$ROOT/README.md" 'README declares Hermes Agent as the runtime'
require_grep 'Linear' "$ROOT/README.md" 'README documents Linear source-of-truth workflow'
require_grep 'Adversarial review' "$ROOT/README.md" 'README documents adversarial post-TDD review gate'
require_grep 'Subida Dev' "$PKG/hermes/skills/hermes-aihaus-workflow/SKILL.md" 'workflow skill documents Dev promotion gate'
require_grep 'Review Dev' "$PKG/hermes/skills/hermes-aihaus-workflow/SKILL.md" 'workflow skill documents human Review Dev gate'
require_grep 'Box Dev Features' "$PKG/hermes/skills/hermes-aihaus-execution/SKILL.md" 'execution skill documents Box Dev Features handoff'
require_grep 'follow-up tasks' "$PKG/hermes/skills/hermes-aihaus-execution/SKILL.md" 'execution skill documents failed-test follow-up tasks'
reject_grep 'Claude Code workflow|Claude-Code-primary|/aih-(install|init|plan|feature|milestone|quick|resume|update|brainstorm|bugfix|close|effort|help|sync-notion)' "$ROOT/README.md" 'README no longer documents legacy Claude slash workflow'

require_dir "$PKG/hermes/skills" 'Hermes skills directory exists'
require_dir "$PKG/hermes/agents" 'Hermes agents directory exists'
expected_skills=(hermes-aihaus-workflow hermes-aihaus-stack-discovery hermes-aihaus-linear-planning hermes-aihaus-execution hermes-aihaus-coverage-review hermes-aihaus-memory)
for skill in "${expected_skills[@]}"; do
  path="$PKG/hermes/skills/$skill/SKILL.md"
  require_file "$path" "skill exists: $skill"
  require_grep "^name: $skill$" "$path" "skill frontmatter name matches: $skill"
  require_grep '^description: ' "$path" "skill description present: $skill"
done

require_file "$PKG/hermes/templates/behavior-contract.md" 'behavior contract template exists'
require_file "$PKG/hermes/templates/context-export.md" 'context export template exists'
require_file "$PKG/hermes/templates/stack-profile.md" 'stack profile template exists'
require_file "$PKG/hermes/templates/coverage-matrix.md" 'coverage matrix template exists'
require_file "$PKG/hermes/templates/agent-context-contract.md" 'agent context contract template exists'
require_grep 'APIs & Backend Logic' "$PKG/hermes/templates/coverage-matrix.md" 'coverage matrix includes production backend layer'
require_grep 'Security & RLS' "$PKG/hermes/templates/coverage-matrix.md" 'coverage matrix includes security/RLS layer'
require_grep 'Error Tracking & Logs' "$PKG/hermes/templates/coverage-matrix.md" 'coverage matrix includes observability layer'
expected_agents=(
  orchestrators/hermes-aihaus-stack-discovery-orchestrator
  orchestrators/hermes-aihaus-planning-orchestrator
  orchestrators/hermes-aihaus-execution-orchestrator
  layers/hermes-aihaus-frontend-ui-agent
  layers/hermes-aihaus-backend-api-agent
  layers/hermes-aihaus-auth-permissions-rls-agent
  layers/hermes-aihaus-data-storage-agent
  layers/hermes-aihaus-observability-agent
  review/hermes-aihaus-test-spec-agent
  review/hermes-aihaus-integration-agent
)
for agent in "${expected_agents[@]}"; do
  path="$PKG/hermes/agents/$agent.md"
  require_file "$path" "Hermes-native agent exists: $agent"
  require_grep '^runtime: hermes$' "$path" "agent runtime is Hermes: $agent"
  require_grep '^required_skills: ' "$path" "agent declares required skills: $agent"
  require_grep '^required_memory: ' "$path" "agent declares required memory: $agent"
  require_grep 'target:|produced:|graph:|linear:|package:' "$path" "agent required memory uses source prefixes: $agent"
done
require_grep 'mcp_linear_' "$PKG/hermes/agents/orchestrators/hermes-aihaus-planning-orchestrator.md" 'agents include runtime integration instructions'
python - "$PKG/hermes/agents" <<'PY' && pass 'agents required_memory entries are source-prefixed' || fail 'agents required_memory entries are source-prefixed'
import pathlib, re, sys
root = pathlib.Path(sys.argv[1])
allowed = ('target:', 'produced:', 'graph:', 'linear:', 'package:')
bad = []
for path in root.rglob('*.md'):
    text = path.read_text(encoding='utf-8')
    for match in re.finditer(r'^required_memory:\s*\[([^]]*)\]', text, re.M):
        for item in [x.strip() for x in match.group(1).split(',') if x.strip()]:
            if not item.startswith(allowed):
                bad.append(f'{path}: {item}')
if bad:
    print('\n'.join(bad))
    sys.exit(1)
PY
reject_grep '^agent_type: specialist$' "$PKG/hermes/agents/orchestrators" 'orchestrators are the only allowed generic coordination agents'
reject_grep '^agent_type: orchestrator$' "$PKG/hermes/agents/layers" 'layer agents are not generic orchestrators'
require_file "$PKG/hermes/scripts/install.sh" 'Hermes install script exists'
bash -n "$PKG/hermes/scripts/install.sh" && pass 'Hermes install script passes bash -n' || fail 'Hermes install script passes bash -n'
require_grep 'hermes-aihaus/agents' "$PKG/hermes/scripts/install.sh" 'installer copies Hermes-native agents'
require_grep 'hermes-aihaus/scripts' "$PKG/hermes/scripts/install.sh" 'installer copies helper scripts for update/target install'
require_grep 'HERMES_HOME/bin' "$PKG/hermes/scripts/install.sh" 'installer targets HERMES_HOME/bin for aih-graph binary'
require_grep '@hatcloud/linear-mcp' "$PKG/hermes/scripts/install.sh" 'installer configures known-good Linear MCP package'
require_grep 'mcp_servers' "$PKG/hermes/scripts/install.sh" 'installer writes Hermes mcp_servers config'
require_grep 'nomic-embed-text' "$PKG/hermes/scripts/install.sh" 'installer prepares optional Ollama embedding model'
require_grep 'install.ps1' "$PKG/hermes/scripts/install.sh" 'installer documents official Windows Ollama installer'
require_grep 'HERMES_AIHAUS_SKIP_OLLAMA_INSTALL' "$PKG/hermes/scripts/install.sh" 'installer supports skipping Ollama auto-install'
require_file "$PKG/hermes/scripts/install-target-adapters.sh" 'target adapter installer exists'
bash -n "$PKG/hermes/scripts/install-target-adapters.sh" && pass 'target adapter installer passes bash -n' || fail 'target adapter installer passes bash -n'
require_grep 'CLAUDE.md' "$PKG/hermes/scripts/install-target-adapters.sh" 'target installer writes Claude Code context'
require_grep 'AGENTS.md' "$PKG/hermes/scripts/install-target-adapters.sh" 'target installer writes Codex context'
require_grep '.claude/agents' "$PKG/hermes/scripts/install-target-adapters.sh" 'target installer exports Claude agents'
require_grep '.codex/prompts' "$PKG/hermes/scripts/install-target-adapters.sh" 'target installer exports Codex prompts'
require_grep 'Graph memory refreshed' "$PKG/hermes/scripts/install-target-adapters.sh" 'target installer refreshes graph memory automatically'
require_grep 'mcp_linear_' "$PKG/hermes/scripts/install-target-adapters.sh" 'target context instructs Linear MCP preference'

tmp_target="$(mktemp -d)"
(
  cd "$tmp_target" && git init -q
  HERMES_HOME="$tmp_target/.hermes" HERMES_AIHAUS_SKIP_OLLAMA_INSTALL=1 bash "$PKG/hermes/scripts/install.sh" >/dev/null
  HERMES_HOME="$tmp_target/.hermes" bash "$PKG/hermes/scripts/install-target-adapters.sh" "$tmp_target" >/dev/null
) && pass 'target adapter installer runs against temp repo' || fail 'target adapter installer runs against temp repo'
require_file "$tmp_target/AGENTS.md" 'temp target has Codex AGENTS.md'
require_file "$tmp_target/CLAUDE.md" 'temp target has Claude CLAUDE.md'
require_file "$tmp_target/.claude/skills/hermes-aihaus-workflow.md" 'temp target has Claude workflow skill'
require_file "$tmp_target/.claude/agents/hermes-aihaus-frontend-ui-agent.md" 'temp target has Claude frontend agent'
require_file "$tmp_target/.codex/prompts/hermes-aihaus-task.md" 'temp target has Codex task prompt'
require_file "$tmp_target/.hermes-aihaus/templates/agent-context-contract.md" 'temp target has shared context contract'
if [[ -x "$tmp_target/.hermes/bin/aih-graph" || -x "$tmp_target/.hermes/bin/aih-graph.exe" ]]; then
  pass 'temp Hermes install has aih-graph binary'
else
  fail 'temp Hermes install has aih-graph binary' "missing: $tmp_target/.hermes/bin/aih-graph(.exe)"
fi
require_grep 'HERMES-AIHAUS:START' "$tmp_target/AGENTS.md" 'Codex AGENTS.md has managed hermes-aihaus block'
require_grep 'HERMES-AIHAUS:START' "$tmp_target/CLAUDE.md" 'Claude CLAUDE.md has managed hermes-aihaus block'
require_file "$tmp_target/.hermes/config.yaml" 'temp Hermes install writes config.yaml'
require_file "$tmp_target/.hermes/hermes-aihaus/scripts/install-target-adapters.sh" 'temp Hermes install has target adapter script'
require_grep '@hatcloud/linear-mcp' "$tmp_target/.hermes/config.yaml" 'temp Hermes config has Linear MCP package'
require_grep 'mcp_linear_' "$tmp_target/AGENTS.md" 'temp Codex context prefers Linear MCP tools'
rm -rf "$tmp_target"

reject_grep 'go run ./aih-graph/cmd/aih-graph' "$PKG/hermes/skills" 'installed skills do not require Go source layout'

reject_path "$PKG/.aihaus" 'legacy pkg/.aihaus removed'
reject_path "$ROOT/plugin" 'legacy plugin directory removed'
reject_path "$ROOT/.claude-plugin" 'legacy Claude plugin metadata removed'
reject_path "$ROOT/.agents" 'legacy generated .agents tree removed'
reject_path "$ROOT/.codex" 'legacy generated .codex tree removed'
reject_path "$ROOT/node_modules" 'accidental node_modules removed'
reject_path "$ROOT/package.json" 'accidental package.json removed'

require_file "$ROOT/aih-graph/cmd/aih-graph/main.go" 'aih-graph CLI remains'
require_grep 'ollama' "$ROOT/aih-graph/cmd/aih-graph/main.go" 'aih-graph keeps local Ollama embedding provider'
require_grep 'OllamaProvider' "$ROOT/aih-graph/internal/embed/embed.go" 'Ollama provider implementation exists'

if [[ "$FAILURES" -eq 0 ]]; then
  printf '\nhermes-aihaus Hermes workflow smoke test PASSED (%d checks)\n' "$CHECKS"
  exit 0
fi
printf '\nhermes-aihaus Hermes workflow smoke test FAILED (%d failures / %d checks)\n' "$FAILURES" "$CHECKS"
exit 1
