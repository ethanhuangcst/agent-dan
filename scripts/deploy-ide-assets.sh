#!/usr/bin/env bash
# Deploy rules, skills, and workflows into ./.{ide} for the selected IDE.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# shellcheck source=read-ide-target.sh
source "$ROOT/scripts/read-ide-target.sh"

# Complete .cursor/ first (git restore + define-* overlays + MCP) — canonical source for all IDEs
bash "$ROOT/scripts/ensure-ide-canonical.sh" --sync-mcp

CANON="$ROOT/.cursor"
DEST="$ROOT/$IDE_DIR"

if [[ ! -d "$CANON/rules" || ! -d "$CANON/skills" || ! -d "$CANON/workflows" ]]; then
  echo "Error: canonical production tree missing under $CANON"
  exit 1
fi

if [[ "$IDE_DIR" == ".cursor" ]]; then
  echo "→ Deploying production assets → .cursor/ (Cursor)"
else
  echo "→ Deploying production assets → $IDE_DIR/ ($IDE_LABEL)"
  echo "   (canonical source: .cursor/ → target IDE folder)"
fi

mkdir -p "$DEST/rules" "$DEST/skills" "$DEST/workflows"

# Full mirror into target IDE folder (same tree as .cursor rules/skills/workflows)
rsync -a --delete "$CANON/rules/" "$DEST/rules/"
rsync -a --delete "$CANON/skills/" "$DEST/skills/"
rsync -a --delete "$CANON/workflows/" "$DEST/workflows/"
if [[ -d "$CANON/hooks" ]]; then
  rsync -a "$CANON/hooks/" "$DEST/hooks/" 2>/dev/null || true
fi
if [[ "$IDE_DIR" != ".cursor" && -f "$CANON/hooks.json" ]]; then
  cp -f "$CANON/hooks.json" "$DEST/hooks.json"
fi

# Cursor MCP registration (Cursor Desktop reads .cursor/mcp.json only)
bash "$ROOT/scripts/ensure-mcp-config.sh" --sync

if [[ "$IDE_DIR" != ".cursor" ]]; then
  cp -f "$CANON/mcp.json" "$DEST/mcp.json.example" 2>/dev/null || true
  cp -f "$CANON/MCP.md" "$DEST/MCP.md.example" 2>/dev/null || true
  cat > "$DEST/README-ide.md" <<EOF
# Work Agent — $IDE_LABEL

Your active IDE asset root is **\`$IDE_DIR/\`** (see \`agent/ide-target\`).

| Asset | Path |
| --- | --- |
| Rules | \`$IDE_DIR/rules/*.mdc\` |
| Skills | \`$IDE_DIR/skills/<name>/SKILL.md\` |
| Workflows | \`$IDE_DIR/workflows/**\` |

Configure **$IDE_LABEL** to load project rules and skills from this folder.

## MCP (work-agent)

- **Cursor:** use \`.cursor/mcp.json\` (project MCP).
- **This IDE:** run the same server with your asset dir:

\`\`\`bash
export WORK_AGENT_IDE_DIR=$IDE_DIR
bash scripts/run-work-agent-mcp.sh
\`\`\`

Wire that command in your IDE's MCP settings if supported.

Re-deploy after \`git pull\`: \`bash scripts/deploy-ide-assets.sh\`
EOF
fi

echo "   rules:     $(find "$DEST/rules" -name '*.mdc' 2>/dev/null | wc -l | tr -d ' ') files"
echo "   skills:    $(find "$DEST/skills" -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ') SKILL.md"
echo "   workflows: $(find "$DEST/workflows" -name '*.yaml' 2>/dev/null | wc -l | tr -d ' ') yaml"
if [[ "$IDE_DIR" == ".cursor" ]]; then
  echo "   MCP:       .cursor/mcp.json (work-agent)"
else
  echo "   MCP:       .cursor/mcp.json (Cursor) | WORK_AGENT_IDE_DIR=$IDE_DIR for this IDE"
fi
