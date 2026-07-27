#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=agent-slug.sh
source "$ROOT/scripts/agent-slug.sh"

FRESH=false
for arg in "$@"; do
  case "$arg" in
    --fresh) FRESH=true ;;
    --help|-h)
      echo "Usage: call-agent-${AGENT_SLUG} [--fresh]"
      echo "  Installs deps if needed, builds MCP server, opens Cursor on this repo."
      echo "  Agent display name: ${AGENT_DISPLAY_NAME} (slug: ${AGENT_SLUG})"
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
echo "Work Agent ready — ${AGENT_DISPLAY_NAME} (MCP: work-agent)."
echo "  Repo: $ROOT"
echo "  Talk in Cursor Agent mode — e.g. \"Run learn-knowledge on …\""
echo ""

if command -v cursor >/dev/null 2>&1; then
  echo "→ Opening Cursor…"
  exec cursor "$ROOT"
else
  echo "Cursor CLI not found. Open this folder in Cursor manually:"
  echo "  $ROOT"
fi
