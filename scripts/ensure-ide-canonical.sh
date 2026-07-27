#!/usr/bin/env bash
# Restore versioned canonical production tree (.cursor/), overlay agent/define-* drafts, optional MCP sync.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SYNC_MCP=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sync-mcp) SYNC_MCP=true; shift ;;
    --help|-h)
      echo "Usage: ensure-ide-canonical.sh [--sync-mcp]"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "$ROOT" ls-files --error-unmatch .cursor/rules >/dev/null 2>&1; then
    echo "→ Restoring tracked canonical tree from git (.cursor/)"
    git -C "$ROOT" restore .cursor 2>/dev/null || git -C "$ROOT" checkout HEAD -- .cursor
  fi
else
  echo "Warning: not a git repo — cannot restore .cursor/ from version control" >&2
fi

mkdir -p "$ROOT/.cursor/rules" "$ROOT/.cursor/skills" "$ROOT/.cursor/workflows"

if [[ -d "$ROOT/agent/define-rules" ]]; then
  rsync -a "$ROOT/agent/define-rules/" "$ROOT/.cursor/rules/"
fi
if [[ -d "$ROOT/agent/define-skills" ]]; then
  rsync -a "$ROOT/agent/define-skills/" "$ROOT/.cursor/skills/"
fi
if [[ -d "$ROOT/agent/define-workflows/prompts" ]]; then
  mkdir -p "$ROOT/.cursor/workflows/prompts"
  rsync -a "$ROOT/agent/define-workflows/prompts/" "$ROOT/.cursor/workflows/prompts/"
fi

if [[ "$SYNC_MCP" == true ]]; then
  bash "$ROOT/scripts/ensure-mcp-config.sh" --sync
else
  bash "$ROOT/scripts/ensure-mcp-config.sh"
fi

for req in rules skills workflows; do
  if [[ ! -d "$ROOT/.cursor/$req" ]] || [[ -z "$(ls -A "$ROOT/.cursor/$req" 2>/dev/null)" ]]; then
    echo "Error: .cursor/$req/ missing or empty after ensure-ide-canonical" >&2
    exit 1
  fi
done

echo "→ Canonical production tree ready (.cursor/)"
