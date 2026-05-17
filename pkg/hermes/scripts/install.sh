#!/usr/bin/env bash
# Install/update hermes-aihaus Hermes skills, agents, aih-graph, and Linear MCP runtime wiring.
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

find_python() {
  if command -v python3 >/dev/null 2>&1; then
    printf 'python3\n'
  elif command -v python >/dev/null 2>&1; then
    printf 'python\n'
  else
    return 1
  fi
}


is_windows_host() {
  case "$(uname -s 2>/dev/null || printf unknown)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

find_ollama() {
  if command -v ollama >/dev/null 2>&1; then
    command -v ollama
    return 0
  fi
  local candidates=(
    "/c/Users/vctrs/AppData/Local/Programs/Ollama/ollama.exe"
    "${LOCALAPPDATA:-}/Programs/Ollama/ollama.exe"
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

install_ollama_windows_official() {
  if [[ "${HERMES_AIHAUS_SKIP_OLLAMA_INSTALL:-0}" == "1" ]]; then
    printf 'Ollama not found; skipping automatic install because HERMES_AIHAUS_SKIP_OLLAMA_INSTALL=1.\n' >&2
    return 1
  fi
  if ! is_windows_host; then
    printf 'Ollama not found; automatic Ollama install is only enabled on Windows for this installer.\n' >&2
    return 1
  fi
  if ! command -v powershell.exe >/dev/null 2>&1; then
    printf 'Ollama not found and powershell.exe is unavailable. Install manually from https://ollama.com/download.\n' >&2
    return 1
  fi
  printf 'Ollama not found; installing via official Ollama Windows installer script...\n'
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://ollama.com/install.ps1 | iex"
}

HERMES_HOME="$(resolve_hermes_home)"
DEST="$HERMES_HOME/skills/hermes-aihaus"
BIN_DEST="$HERMES_HOME/bin"
CONFIG_PATH="${HERMES_CONFIG:-$HERMES_HOME/config.yaml}"
ENV_PATH="$HERMES_HOME/.env"
PYTHON_BIN="$(find_python || true)"

mkdir -p "$DEST"
cp -R "$PKG_ROOT/skills/." "$DEST/"
mkdir -p "$HERMES_HOME/hermes-aihaus/templates"
cp -R "$PKG_ROOT/templates/." "$HERMES_HOME/hermes-aihaus/templates/"
mkdir -p "$HERMES_HOME/hermes-aihaus/agents"
cp -R "$PKG_ROOT/agents/." "$HERMES_HOME/hermes-aihaus/agents/"
mkdir -p "$HERMES_HOME/hermes-aihaus/scripts"
cp -R "$PKG_ROOT/scripts/." "$HERMES_HOME/hermes-aihaus/scripts/"

mkdir -p "$BIN_DEST"
if [[ -x "$PKG_ROOT/bin/aih-graph" ]]; then
  cp "$PKG_ROOT/bin/aih-graph" "$BIN_DEST/aih-graph"
elif [[ -x "$PKG_ROOT/bin/aih-graph.exe" ]]; then
  cp "$PKG_ROOT/bin/aih-graph.exe" "$BIN_DEST/aih-graph.exe"
elif command -v go >/dev/null 2>&1 && [[ -d "$PKG_ROOT/../../aih-graph" ]]; then
  (cd "$PKG_ROOT/../../aih-graph" && go build -o "$BIN_DEST/aih-graph" ./cmd/aih-graph)
else
  printf 'Warning: aih-graph binary not installed. Install a prebuilt aih-graph into %s or run this installer from source with Go available.\n' "$BIN_DEST" >&2
fi

# Ensure Hermes native MCP can load and configure Linear automatically.
if [[ -n "$PYTHON_BIN" ]]; then
  if ! "$PYTHON_BIN" - <<'PY' >/dev/null 2>&1
import mcp  # noqa: F401
PY
  then
    printf 'MCP Python SDK not found; installing it for the current Python environment...\n'
    "$PYTHON_BIN" -m pip install --user --upgrade mcp >/dev/null || printf 'Warning: failed to install MCP SDK automatically. Run: %s -m pip install --user --upgrade mcp\n' "$PYTHON_BIN" >&2
  fi

  if ! "$PYTHON_BIN" - <<'PY' >/dev/null 2>&1
import yaml  # noqa: F401
PY
  then
    "$PYTHON_BIN" -m pip install --user --upgrade pyyaml >/dev/null || true
  fi

  mkdir -p "$(dirname "$CONFIG_PATH")"
  "$PYTHON_BIN" - "$CONFIG_PATH" "$ENV_PATH" <<'PY'
from pathlib import Path
import os
import sys

config_path = Path(sys.argv[1])
env_path = Path(sys.argv[2])

def read_dotenv(path: Path) -> dict:
    values = {}
    if not path.exists():
        return values
    for raw in path.read_text(encoding='utf-8', errors='ignore').splitlines():
        line = raw.strip()
        if not line or line.startswith('#') or '=' not in line:
            continue
        k, v = line.split('=', 1)
        values[k.strip()] = v.strip().strip('"').strip("'")
    return values

try:
    import yaml
except Exception as exc:
    # Last-resort append for fresh/minimal installs. Existing complex config is left untouched.
    text = config_path.read_text(encoding='utf-8') if config_path.exists() else ''
    if 'mcp_servers:' not in text:
        with config_path.open('a', encoding='utf-8') as f:
            if text and not text.endswith('\n'):
                f.write('\n')
            f.write('\nmcp_servers:\n  linear:\n    command: npx\n    args: ["-y", "@hatcloud/linear-mcp"]\n    env:\n      LINEAR_API_KEY: "${LINEAR_API_KEY}"\n    timeout: 120\n    connect_timeout: 120\n')
    print(f'Warning: PyYAML unavailable; used minimal MCP config append only: {exc}', file=sys.stderr)
    raise SystemExit(0)

config = {}
if config_path.exists() and config_path.read_text(encoding='utf-8', errors='ignore').strip():
    loaded = yaml.safe_load(config_path.read_text(encoding='utf-8'))
    if isinstance(loaded, dict):
        config = loaded

dotenv = read_dotenv(env_path)
credential_value = '${LINEAR_API_KEY}'
if os.environ.get('LINEAR_API_KEY') or dotenv.get('LINEAR_API_KEY'):
    credential_value = '${LINEAR_API_KEY}'
elif os.environ.get('LINEAR_ACCESS_TOKEN') or dotenv.get('LINEAR_ACCESS_TOKEN'):
    credential_value = '${LINEAR_ACCESS_TOKEN}'

servers = config.setdefault('mcp_servers', {})
existing = servers.get('linear') if isinstance(servers.get('linear'), dict) else {}
linear = dict(existing or {})
linear.update({
    'command': 'npx',
    'args': ['-y', '@hatcloud/linear-mcp'],
    'timeout': 120,
    'connect_timeout': 120,
})
env = dict(linear.get('env') or {})
env['LINEAR_API_KEY'] = credential_value
linear['env'] = env
servers['linear'] = linear
config_path.parent.mkdir(parents=True, exist_ok=True)
config_path.write_text(yaml.safe_dump(config, sort_keys=False, allow_unicode=True), encoding='utf-8')
print(f'Configured mcp_servers.linear in {config_path}')
PY
else
  printf 'Warning: no Python found; skipped automatic MCP config update.\n' >&2
fi

OLLAMA_BIN="$(find_ollama || true)"
if [[ -z "$OLLAMA_BIN" ]]; then
  install_ollama_windows_official || true
  OLLAMA_BIN="$(find_ollama || true)"
fi
if [[ -n "$OLLAMA_BIN" ]]; then
  if ! "$OLLAMA_BIN" list 2>/dev/null | grep -q '^nomic-embed-text'; then
    printf 'Ollama found; ensuring nomic-embed-text embedding model is available...\n'
    "$OLLAMA_BIN" pull nomic-embed-text >/dev/null || printf 'Warning: failed to pull nomic-embed-text; aih-graph will use lexical/hybrid retrieval until embeddings are available.\n' >&2
  fi
else
  printf 'Warning: Ollama is not available. Semantic aih-graph retrieval will use lexical/hybrid mode until Ollama is installed. On Windows the official manual command is: irm https://ollama.com/install.ps1 | iex\n' >&2
fi

if command -v npx >/dev/null 2>&1; then
  :
else
  printf 'Warning: npx not found on PATH. Linear MCP config was written, but Hermes needs Node.js/npx to start @hatcloud/linear-mcp.\n' >&2
fi

if [[ "${HERMES_AIHAUS_INSTALL_VERIFY_MCP:-0}" == "1" ]] && command -v hermes >/dev/null 2>&1; then
  hermes mcp test linear || printf 'Warning: hermes mcp test linear did not pass yet; restart Hermes or check LINEAR_API_KEY/LINEAR_ACCESS_TOKEN and npx.\n' >&2
fi

printf 'hermes-aihaus Hermes workflow installed/updated\n'
printf 'Skills: %s\n' "$DEST"
printf 'Templates: %s\n' "$HERMES_HOME/hermes-aihaus/templates"
printf 'Agents: %s\n' "$HERMES_HOME/hermes-aihaus/agents"
printf 'Scripts: %s\n' "$HERMES_HOME/hermes-aihaus/scripts"
printf 'Binary dir: %s\n' "$BIN_DEST"
printf 'Linear MCP: %s -> mcp_servers.linear uses npx -y @hatcloud/linear-mcp\n' "$CONFIG_PATH"
printf 'Start a fresh Hermes session or use /reload-mcp; use: hermes -s hermes-aihaus-workflow\n'
