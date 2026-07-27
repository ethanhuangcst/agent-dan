#!/usr/bin/env bash
# Smoke-test deploy + verify for each supported IDE target (restores cursor at end).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BACKUP=""
if [[ -f "$ROOT/agent/ide-target" ]]; then
  BACKUP="$(mktemp)"
  cp "$ROOT/agent/ide-target" "$BACKUP"
fi

restore() {
  if [[ -n "$BACKUP" && -f "$BACKUP" ]]; then
    cp "$BACKUP" "$ROOT/agent/ide-target"
    rm -f "$BACKUP"
  else
    bash "$ROOT/scripts/select-ide.sh" --ide cursor --non-interactive >/dev/null
  fi
  bash "$ROOT/scripts/deploy-ide-assets.sh" >/dev/null
}
trap restore EXIT

test_ide() {
  local ide="$1"
  shift
  echo "=== test deploy: $ide ==="
  bash "$ROOT/scripts/select-ide.sh" --ide "$ide" --non-interactive "$@"
  bash "$ROOT/scripts/deploy-ide-assets.sh"
  bash "$ROOT/scripts/verify-ide-setup.sh" --strict
}

test_ide claude
test_ide codex
echo "=== test deploy: other (windsurf) ==="
bash "$ROOT/scripts/select-ide.sh" --other windsurf --non-interactive
bash "$ROOT/scripts/deploy-ide-assets.sh"
bash "$ROOT/scripts/verify-ide-setup.sh" --strict

echo "=== all IDE deploy smoke tests passed ==="
