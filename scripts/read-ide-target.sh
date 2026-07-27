#!/usr/bin/env bash
# Read agent/ide-target into env (IDE, IDE_DIR, IDE_LABEL). Source from other scripts.
set -euo pipefail

ROOT="${WORK_AGENT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

IDE_KEY="${WORK_AGENT_IDE:-cursor}"
IDE_DIR="${WORK_AGENT_IDE_DIR:-.cursor}"
IDE_LABEL="${WORK_AGENT_IDE_LABEL:-Cursor}"

if [[ -f "$ROOT/agent/ide-target" ]]; then
  IDE_KEY="$(grep '^IDE=' "$ROOT/agent/ide-target" | cut -d= -f2- | tr -d '[:space:]' || echo cursor)"
  IDE_DIR="$(grep '^IDE_DIR=' "$ROOT/agent/ide-target" | cut -d= -f2- | tr -d '[:space:]' || echo .cursor)"
  IDE_LABEL="$(grep '^IDE_LABEL=' "$ROOT/agent/ide-target" | cut -d= -f2- | tr -d '[:space:]' || echo Cursor)"
fi

[[ -n "${WORK_AGENT_IDE_DIR:-}" ]] && IDE_DIR="$WORK_AGENT_IDE_DIR"

export WORK_AGENT_IDE="$IDE_KEY"
export WORK_AGENT_IDE_DIR="$IDE_DIR"
export WORK_AGENT_IDE_LABEL="$IDE_LABEL"
