#!/usr/bin/env bash
# Cursor spawns this via .cursor/mcp.json — resolves repo root reliably.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export WORK_AGENT_ROOT="$ROOT"
cd "$ROOT"
exec node "$ROOT/packages/mcp-server/dist/index.js"
