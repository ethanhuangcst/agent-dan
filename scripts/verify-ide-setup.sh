#!/usr/bin/env bash
# Verify IDE asset dirs and print load instructions.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

STRICT=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) STRICT=true; shift ;;
    --help|-h)
      echo "Usage: verify-ide-setup.sh [--strict]"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# shellcheck source=read-ide-target.sh
source "$ROOT/scripts/read-ide-target.sh"

DEST="$ROOT/$IDE_DIR"
CANON="$ROOT/.cursor"
ok=true

for sub in rules skills workflows; do
  if [[ ! -d "$DEST/$sub" ]]; then
    echo "✗ Missing $IDE_DIR/$sub/ — run: bash scripts/deploy-ide-assets.sh"
    ok=false
  fi
done

# Canonical .cursor always present (source tree + Cursor MCP)
if [[ ! -f "$ROOT/.cursor/mcp.json" ]]; then
  echo "✗ Missing .cursor/mcp.json — run: bash scripts/ensure-mcp-config.sh --sync"
  ok=false
fi

if [[ "$IDE_DIR" != ".cursor" ]]; then
  if [[ ! -f "$DEST/README-ide.md" ]]; then
    echo "✗ Missing $IDE_DIR/README-ide.md — run: bash scripts/deploy-ide-assets.sh"
    ok=false
  fi
  for sub in rules skills workflows; do
    if [[ -d "$CANON/$sub" && -d "$DEST/$sub" ]]; then
      if ! diff -qr "$CANON/$sub" "$DEST/$sub" >/dev/null 2>&1; then
        echo "✗ $IDE_DIR/$sub/ differs from .cursor/$sub/ — run: bash scripts/deploy-ide-assets.sh"
        ok=false
      fi
    fi
  done
fi

if [[ "$STRICT" == true ]] && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    rel="${path#".cursor/"}"
    case "$rel" in
      mcp.json|MCP.md)
        [[ -f "$ROOT/$path" ]] || { echo "✗ Missing tracked file: $path"; ok=false; }
        ;;
      rules/*|skills/*|workflows/*)
        if [[ "$IDE_DIR" == ".cursor" ]]; then
          [[ -f "$ROOT/$path" ]] || { echo "✗ Missing tracked file: $path"; ok=false; }
        else
          [[ -f "$DEST/$rel" ]] || { echo "✗ Missing in $IDE_DIR/: $rel"; ok=false; }
        fi
        ;;
    esac
  done < <(git -C "$ROOT" ls-files '.cursor/' 2>/dev/null || true)
fi

if [[ "$ok" != true ]]; then
  exit 1
fi

echo ""
echo "IDE setup — $IDE_LABEL ($IDE_DIR/)"
echo "  Rules:     $IDE_DIR/rules/*.mdc"
echo "  Skills:    $IDE_DIR/skills/<name>/SKILL.md"
echo "  Workflows: $IDE_DIR/workflows/**/*.yaml"
if [[ "$IDE_DIR" == ".cursor" ]]; then
  echo "  MCP:       .cursor/mcp.json (work-agent)"
else
  echo "  MCP:       .cursor/mcp.json (Cursor only) — or WORK_AGENT_IDE_DIR=$IDE_DIR + scripts/run-work-agent-mcp.sh"
fi
echo ""

case "$IDE_KEY" in
  cursor)
    echo "Cursor:"
    echo "  1. Open this repo in Cursor."
    echo "  2. Settings → Rules — project rules under $IDE_DIR/rules/."
    echo "  3. Settings → MCP — enable **work-agent** (.cursor/mcp.json). Reload window if empty."
    echo "  4. Agent mode: workflow_run / knowledge_* tools."
    ;;
  claude)
    echo "Claude:"
    echo "  1. Open this repo as project root."
    echo "  2. Load rules from $IDE_DIR/rules/ and skills from $IDE_DIR/skills/ (Claude Code project .claude layout)."
    echo "  3. See $IDE_DIR/README-ide.md for MCP with WORK_AGENT_IDE_DIR=$IDE_DIR."
    ;;
  codex)
    echo "Codex:"
    echo "  1. Open repo root in Codex."
    echo "  2. Point project config at $IDE_DIR/rules and $IDE_DIR/skills."
    echo "  3. See $IDE_DIR/README-ide.md — re-deploy: bash scripts/deploy-ide-assets.sh"
    ;;
  *)
    echo "$IDE_LABEL:"
    echo "  1. Load rules/skills/workflows from $IDE_DIR/ (see README-ide.md)."
    echo "  2. MCP: WORK_AGENT_IDE_DIR=$IDE_DIR bash scripts/run-work-agent-mcp.sh"
    ;;
esac

echo ""
echo "Runtime: WORK_AGENT_IDE_DIR=$IDE_DIR (scripts/run-work-agent-mcp.sh reads agent/ide-target)."
