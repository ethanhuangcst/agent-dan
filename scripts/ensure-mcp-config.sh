#!/usr/bin/env bash
# Ensure MCP registration files under .cursor/ (Cursor project MCP path; IDE-agnostic script name).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOT="$ROOT/agent/ide-bootstrap/mcp"
DEST="$ROOT/.cursor"

SYNC=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sync) SYNC=true; shift ;;
    --help|-h)
      echo "Usage: ensure-mcp-config.sh [--sync]"
      echo "  --sync  Always copy mcp.json and MCP.md from agent/ide-bootstrap/mcp/"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

mkdir -p "$DEST"

for f in mcp.json MCP.md; do
  if [[ "$SYNC" == true && -f "$BOOT/$f" ]]; then
    cp -f "$BOOT/$f" "$DEST/$f"
    echo "→ Synced $DEST/$f from agent/ide-bootstrap/mcp/"
    continue
  fi
  if [[ ! -f "$DEST/$f" ]]; then
    if [[ -f "$BOOT/$f" ]]; then
      cp "$BOOT/$f" "$DEST/$f"
      echo "→ Restored $DEST/$f from agent/ide-bootstrap/mcp/"
    elif git -C "$ROOT" cat-file -e "HEAD:.cursor/$f" 2>/dev/null; then
      git -C "$ROOT" restore ".cursor/$f"
      echo "→ Restored $DEST/$f from git"
    else
      echo "Error: missing $DEST/$f and no bootstrap copy" >&2
      exit 1
    fi
  fi
done

if [[ -f "$DEST/mcp.json" ]]; then
  mkdir -p "$BOOT"
  cp -f "$DEST/mcp.json" "$BOOT/mcp.json"
  [[ -f "$DEST/MCP.md" ]] && cp -f "$DEST/MCP.md" "$BOOT/MCP.md"
fi
