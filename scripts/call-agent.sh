#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=agent-slug.sh
source "$ROOT/scripts/agent-slug.sh"

# shellcheck source=read-ide-target.sh
source "$ROOT/scripts/read-ide-target.sh"

# Ensure target IDE tree matches .cursor (non-Cursor users rely on $IDE_DIR/)
if ! bash "$ROOT/scripts/verify-ide-setup.sh" --strict 2>/dev/null; then
  echo "→ IDE assets out of sync — deploying to $IDE_DIR/"
  bash "$ROOT/scripts/deploy-ide-assets.sh"
  bash "$ROOT/scripts/verify-ide-setup.sh" --strict
else
  bash "$ROOT/scripts/ensure-mcp-config.sh" --sync
fi

FRESH=false
for arg in "$@"; do
  case "$arg" in
    --fresh) FRESH=true ;;
    --help|-h)
      echo "Usage: call-agent-${AGENT_SLUG} [--fresh]"
      echo "  Installs deps if needed, builds MCP server, opens IDE per agent/ide-target."
      echo "  Agent: ${AGENT_DISPLAY_NAME} (slug: ${AGENT_SLUG})"
      exit 0
      ;;
  esac
done

need_install=false
need_build=false

if [[ "$FRESH" == true ]] || [[ ! -d "$ROOT/node_modules" ]]; then
  need_install=true
fi

if [[ "$FRESH" == true ]] || [[ ! -f "$ROOT/packages/mcp-server/dist/index.js" ]]; then
  need_build=true
fi

if [[ "$need_install" == true ]]; then
  echo "→ npm install"
  npm install
  need_build=true
fi

if [[ "$need_build" == true ]]; then
  echo "→ npm run build"
  npm run build
fi

chmod +x "$ROOT/scripts/run-work-agent-mcp.sh" 2>/dev/null || true
bash "$ROOT/scripts/generate-agent-wrappers.sh" >/dev/null

node -e "
const fs = require('fs');
const p = '$ROOT/packages/mcp-server/dist/index.js';
if (!fs.existsSync(p)) process.exit(1);
"

echo ""
echo "Work Agent ready — ${AGENT_DISPLAY_NAME}."
echo "  Repo: $ROOT"
echo "  IDE:  $IDE_LABEL → $IDE_DIR/ (agent/ide-target)"
if [[ "$IDE_KEY" == "cursor" ]]; then
  echo "  MCP:  work-agent via .cursor/mcp.json"
else
  echo "  MCP:  WORK_AGENT_IDE_DIR=$IDE_DIR — see $IDE_DIR/README-ide.md"
fi
echo ""

if [[ "$IDE_KEY" == "cursor" ]] && command -v cursor >/dev/null 2>&1; then
  echo "→ Opening Cursor…"
  exec cursor "$ROOT"
fi

if [[ "$IDE_KEY" == "cursor" ]]; then
  echo "Cursor CLI not found. Open this folder in Cursor manually:"
  echo "  $ROOT"
  exit 0
fi

echo "Open this repo in ${IDE_LABEL} and load assets from $IDE_DIR/"
echo "  bash scripts/verify-ide-setup.sh --strict"
