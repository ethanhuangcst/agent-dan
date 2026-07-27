#!/usr/bin/env bash
# Cursor spawns this via .cursor/mcp.json — resolves repo root reliably.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export WORK_AGENT_ROOT="$ROOT"
# shellcheck source=read-ide-target.sh
source "$ROOT/scripts/read-ide-target.sh"
export WORK_AGENT_IDE_DIR="$IDE_DIR"
cd "$ROOT"
exec node "$ROOT/packages/mcp-server/dist/index.js"
