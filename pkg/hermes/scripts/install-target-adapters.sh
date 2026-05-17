#!/usr/bin/env bash
# Install hermes-aihaus native context adapters into a target application repo.
# This does not install Hermes itself; run pkg/hermes/scripts/install.sh first.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
resolve_hermes_home() {
  if [[ -n "${HERMES_HOME:-}" ]]; then
    printf '%s\n' "$HERMES_HOME"
    return
  fi
  if command -v hermes >/dev/null 2>&1; then
    local cfg
    cfg="$(hermes config path 2>/dev/null || true)"
    if [[ -n "$cfg" ]]; then
      cd "$(dirname "$cfg")" && pwd
      return
    fi
  fi
  printf '%s\n' "$HOME/.hermes"
}

HERMES_HOME="$(resolve_hermes_home)"
TARGET_REPO="${1:-$(pwd)}"

find_ollama() {
  if command -v ollama >/dev/null 2>&1; then
    command -v ollama
    return 0
  fi
  local candidates=(
    "/c/Users/vctrs/AppData/Local/Programs/Ollama/ollama.exe"
    "$LOCALAPPDATA/Programs/Ollama/ollama.exe"
    "/c/Program Files/Ollama/ollama.exe"
  )
  local p
  for p in "${candidates[@]}"; do
    if [[ -n "$p" && -x "$p" ]]; then
      printf '%s\n' "$p"
      return 0
    fi
  done
  return 1
}

if [[ ! -d "$TARGET_REPO" ]]; then
  printf 'Target repo does not exist: %s\n' "$TARGET_REPO" >&2
  exit 1
fi

TARGET_REPO="$(cd "$TARGET_REPO" && pwd)"

# Prefer source-package files when this script is run from the hermes-aihaus repo.
# Fall back to the installed Hermes package when copied elsewhere.
if [[ -d "$PKG_ROOT/agents" && -d "$PKG_ROOT/skills" && -d "$PKG_ROOT/templates" ]]; then
  SOURCE_ROOT="$PKG_ROOT"
elif [[ -d "$HERMES_HOME/hermes-aihaus/agents" && -d "$HERMES_HOME/skills/hermes-aihaus" ]]; then
  SOURCE_ROOT="$HERMES_HOME/hermes-aihaus"
else
  printf 'Cannot find hermes-aihaus package files. Run pkg/hermes/scripts/install.sh first or run this script from the hermes-aihaus source repo.\n' >&2
  exit 1
fi

if [[ ! -d "$TARGET_REPO/.git" ]]; then
  printf 'Warning: %s is not a git repository root. Installing adapters anyway.\n' "$TARGET_REPO" >&2
fi

mkdir -p "$TARGET_REPO/.hermes-aihaus/templates" \
         "$TARGET_REPO/.hermes-aihaus/agents" \
         "$TARGET_REPO/.claude/agents" \
         "$TARGET_REPO/.claude/skills" \
         "$TARGET_REPO/.codex/prompts"

cp -R "$SOURCE_ROOT/templates/." "$TARGET_REPO/.hermes-aihaus/templates/"
cp -R "$SOURCE_ROOT/agents/." "$TARGET_REPO/.hermes-aihaus/agents/"

if [[ -d "$SOURCE_ROOT/skills" ]]; then
  SKILLS_SOURCE="$SOURCE_ROOT/skills"
else
  SKILLS_SOURCE="$HERMES_HOME/skills/hermes-aihaus"
fi

python - "$TARGET_REPO" "$SOURCE_ROOT" "$SKILLS_SOURCE" <<'PY'
from pathlib import Path
import re
import sys

target = Path(sys.argv[1])
source = Path(sys.argv[2])
skills_source = Path(sys.argv[3])

START = "<!-- HERMES-AIHAUS:START -->"
END = "<!-- HERMES-AIHAUS:END -->"

shared_block = f"""{START}
# hermes-aihaus runtime contract

This repository uses hermes-aihaus for Linear-backed feature delivery.

Non-negotiables for Hermes, Claude Code, and Codex:
- Treat Linear as the operational source of truth for issue status, comments, blockers, acceptance criteria, and evidence.
- Before implementation, inspect this real repository and produce/use `.hermes-aihaus/templates/stack-profile.md` fields; do not assume framework, package manager, database, auth provider, deploy target, or test runner.
- Before code changes, align behavior through a Behavior Contract and Coverage Matrix.
- Execute with TDD: RED test evidence, GREEN implementation evidence, then refactor with tests still green.
- Route by production layers: frontend, APIs/backend, database/storage, auth/permissions, deployment/cloud/CI, security/RLS, rate limiting, caching/CDN, scaling, logs, and recovery.
- Resolve agent `required_memory` through `.hermes-aihaus/templates/agent-context-contract.md`. `produced:*` must come from prior hermes-aihaus stages; `graph:*` must come from `aih-graph`; `linear:*` must come from Linear via Hermes Linear MCP/native Linear tooling; `target:*` must be read from this repo.
- Prefer Hermes MCP tools with the `mcp_linear_*` prefix for Linear reads/writes when available; otherwise use the direct Linear GraphQL fallback from the Linear skill. Never treat local notes as a substitute for Linear status/comments.
- The hermes-aihaus installers bootstrap Linear MCP and refresh aih-graph memory automatically. Agents should consume the generated context and run memory refresh/query themselves when needed; do not ask the user to run setup commands during a task.
- Keep technical retryable blockers, technical non-retryable blockers, and human-input blockers distinct.

Local package surfaces:
- Shared templates: `.hermes-aihaus/templates/`
- Shared Hermes role catalog copy: `.hermes-aihaus/agents/`
- Claude Code native agents: `.claude/agents/hermes-aihaus-*.md`
- Claude Code native skills: `.claude/skills/hermes-aihaus-*.md`
- Codex prompt bundles: `.codex/prompts/hermes-aihaus-*.md`

Runtime surfaces already installed by hermes-aihaus:
- Linear MCP: Hermes config `mcp_servers.linear` using `npx -y @hatcloud/linear-mcp`, with credentials resolved from `${{LINEAR_API_KEY}}` or `${{LINEAR_ACCESS_TOKEN}}`.
- Graph memory: this installer refreshes `aih-graph` for the target repo. Use semantic retrieval automatically when local Ollama `nomic-embed-text` is available; otherwise use hybrid BM25/FTS5.
- Start Hermes with workflow skill: `hermes -s hermes-aihaus-workflow`
{END}
"""

claude_extra = """
Claude Code notes:
- Load this CLAUDE.md plus `.claude/skills/hermes-aihaus-workflow.md` before planning or implementing hermes-aihaus work.
- Use the generated `.claude/agents/` specialists only after stack discovery proves the touched production layers.
- Prefer print mode for one-shot verification and interactive mode for long iterative work.
"""

agents_extra = """
Codex notes:
- Codex reads AGENTS.md as its native project context. For hermes-aihaus tasks, include `.codex/prompts/hermes-aihaus-task.md` or paste its contents into `codex exec`.
- Do not rely on Claude-only `.claude/*` files for Codex behavior; use this AGENTS.md plus `.codex/prompts/*`.
"""

def upsert_block(path: Path, extra: str) -> None:
    if path.exists():
        text = path.read_text(encoding="utf-8")
    else:
        text = f"# {path.name}\n\n"
    block = shared_block.rstrip() + "\n" + extra.strip() + "\n"
    pattern = re.compile(re.escape(START) + r".*?" + re.escape(END) + r"(?:\n[^<].*?)?(?=\n#|\Z)", re.S)
    if START in text and END in text:
        text = re.sub(re.escape(START) + r".*?" + re.escape(END), block.rstrip(), text, flags=re.S)
    else:
        if not text.endswith("\n"):
            text += "\n"
        text += "\n" + block
    path.write_text(text.rstrip() + "\n", encoding="utf-8")

upsert_block(target / "AGENTS.md", agents_extra)
upsert_block(target / "CLAUDE.md", claude_extra)

# Claude skills: one Markdown file per hermes-aihaus Hermes skill, preserving the procedure text.
claude_skills = target / ".claude" / "skills"
for skill_md in sorted(skills_source.glob("*/SKILL.md")):
    name = skill_md.parent.name
    content = skill_md.read_text(encoding="utf-8")
    out = claude_skills / f"{name}.md"
    out.write_text(
        f"# {name}\n\n"
        "This is an hermes-aihaus procedure exported for Claude Code from the Hermes skill package.\n"
        "Follow it together with CLAUDE.md and the Behavior Contract.\n\n"
        + content,
        encoding="utf-8",
    )

# Claude agents: convert Hermes role catalog into Claude-native custom agents.
claude_agents = target / ".claude" / "agents"
agent_source = source / "agents"
for agent_md in sorted(agent_source.rglob("*.md")):
    rel = agent_md.relative_to(agent_source)
    text = agent_md.read_text(encoding="utf-8")
    name = agent_md.stem
    desc_match = re.search(r"^description:\s*>?\s*\n?((?:  .+\n)|.+)", text, re.M)
    if desc_match:
        desc = " ".join(line.strip() for line in desc_match.group(1).splitlines()).strip().strip('"')
    else:
        desc = f"hermes-aihaus role adapter for {name}"
    model = "opus" if any(part in str(rel) for part in ["planning", "review"]) else "sonnet"
    out = claude_agents / f"{name}.md"
    out.write_text(
        "---\n"
        f"name: {name}\n"
        f"description: {desc}\n"
        f"model: {model}\n"
        "tools: [Read, Grep, Glob, Bash, Edit, Write]\n"
        "---\n\n"
        "You are the Claude Code adapter for this hermes-aihaus Hermes role. Preserve the contract below.\n\n"
        + text,
        encoding="utf-8",
    )

# Codex prompt bundles: Codex does not automatically load .claude/*, so provide explicit prompt files.
codex_prompts = target / ".codex" / "prompts"
workflow = (skills_source / "hermes-aihaus-workflow" / "SKILL.md").read_text(encoding="utf-8") if (skills_source / "hermes-aihaus-workflow" / "SKILL.md").exists() else ""
execution = (skills_source / "hermes-aihaus-execution" / "SKILL.md").read_text(encoding="utf-8") if (skills_source / "hermes-aihaus-execution" / "SKILL.md").exists() else ""
context_contract = (source / "templates" / "agent-context-contract.md").read_text(encoding="utf-8") if (source / "templates" / "agent-context-contract.md").exists() else ""
(codex_prompts / "hermes-aihaus-task.md").write_text(
    "# Codex prompt: hermes-aihaus task\n\n"
    "Use this prompt with `codex exec` from the target repo. Replace bracketed placeholders before running.\n\n"
    "```text\n"
    "You are Codex working inside a repo that uses hermes-aihaus. Read AGENTS.md first.\n"
    "Task / Linear issue: [paste Linear issue URL, title, and current acceptance notes]\n\n"
    "Required protocol:\n"
    "1. Inspect the real repo and summarize stack evidence before editing.\n"
    "2. Confirm or request the Behavior Contract before implementation.\n"
    "3. Use TDD: write/run failing test, implement minimal fix, rerun passing test, then relevant regression checks.\n"
    "4. Map changes and tests to touched production layers.\n"
    "5. Return exact files changed, commands run, RED/GREEN evidence, blockers, and Linear comment text.\n\n"
    "hermes-aihaus workflow skill excerpt:\n"
    + workflow + "\n\n"
    "Execution skill excerpt:\n" + execution + "\n\n"
    "Context contract:\n" + context_contract + "\n"
    "```\n",
    encoding="utf-8",
)
(codex_prompts / "hermes-aihaus-review.md").write_text(
    "# Codex prompt: hermes-aihaus review\n\n"
    "```text\n"
    "You are Codex reviewing an hermes-aihaus change. Read AGENTS.md first.\n"
    "Review against Behavior Contract, Coverage Matrix, Stack Profile, TDD evidence, and Linear closeout requirements.\n"
    "Check for missing production layers, missing RED/GREEN evidence, business-rule drift, security/RLS/auth gaps, and unreported blockers.\n"
    "Return verdict, required fixes, and exact evidence gaps.\n"
    "```\n",
    encoding="utf-8",
)
PY

# Refresh target graph memory automatically so agents start with current context.
AIH_GRAPH_BIN="$HERMES_HOME/bin/aih-graph"
if [[ ! -x "$AIH_GRAPH_BIN" ]]; then
  if command -v aih-graph >/dev/null 2>&1; then
    AIH_GRAPH_BIN="$(command -v aih-graph)"
  elif [[ -x "$HERMES_HOME/bin/aih-graph.exe" ]]; then
    AIH_GRAPH_BIN="$HERMES_HOME/bin/aih-graph.exe"
  else
    AIH_GRAPH_BIN=""
  fi
fi

if [[ -n "$AIH_GRAPH_BIN" ]]; then
  GRAPH_ARGS=(build --accept-all-repos)
  GRAPH_MODE="hybrid lexical"
  OLLAMA_BIN="$(find_ollama || true)"
  if [[ -n "$OLLAMA_BIN" ]]; then
    if ! "$OLLAMA_BIN" list 2>/dev/null | grep -q '^nomic-embed-text'; then
      "$OLLAMA_BIN" pull nomic-embed-text >/dev/null 2>&1 || true
    fi
    if "$OLLAMA_BIN" list 2>/dev/null | grep -q '^nomic-embed-text'; then
      GRAPH_ARGS+=(--embed-provider ollama)
      GRAPH_MODE="semantic Ollama"
    fi
  fi
  (cd "$TARGET_REPO" && "$AIH_GRAPH_BIN" "${GRAPH_ARGS[@]}" . >/dev/null)     && printf 'Graph memory refreshed for %s (%s)\n' "$TARGET_REPO" "$GRAPH_MODE"     || printf 'Warning: graph memory refresh failed for %s; agents should retry aih-graph before planning.\n' "$TARGET_REPO" >&2
else
  printf 'Warning: aih-graph binary not found; run pkg/hermes/scripts/install.sh first.\n' >&2
fi

printf 'hermes-aihaus target adapters installed\n'
printf 'Target repo: %s\n' "$TARGET_REPO"
printf 'Shared context: %s\n' "$TARGET_REPO/.hermes-aihaus"
printf 'Claude Code: %s and %s\n' "$TARGET_REPO/CLAUDE.md" "$TARGET_REPO/.claude"
printf 'Codex: %s and %s\n' "$TARGET_REPO/AGENTS.md" "$TARGET_REPO/.codex/prompts"
