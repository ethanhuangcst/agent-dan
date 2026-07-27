#!/usr/bin/env bash
# First-time setup: clone repo (optional), install, build, generate wrappers, open Cursor.
set -euo pipefail

REPO_URL=""
TARGET_DIR=""
FRESH=false
IDE_ARG=""
IDE_OTHER=""
NON_INTERACTIVE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  echo "Usage: onboard-agent-[slug] [--repo URL] [--dir PATH] [--fresh]"
  echo "         [--ide cursor|claude|codex] [--other NAME] [--non-interactive]"
  echo "  --repo URL   Git clone URL (or set WORK_AGENT_REPO_URL / agent/default-repo.url)"
  echo "  --dir PATH   Clone into PATH (default: ./work-agent next to cwd, or use existing repo)"
  echo "  --fresh      Force npm install and rebuild"
  echo ""
  echo "If run inside an existing Work Agent checkout, clones are skipped."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO_URL="$2"; shift 2 ;;
    --dir) TARGET_DIR="$2"; shift 2 ;;
    --fresh) FRESH=true; shift ;;
    --ide) IDE_ARG="$2"; shift 2 ;;
    --other) IDE_OTHER="$2"; shift 2 ;;
    --non-interactive) NON_INTERACTIVE=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

is_work_agent_repo() {
  local dir="$1"
  [[ -f "$dir/package.json" ]] && grep -q '"name"[[:space:]]*:[[:space:]]*"work-agent"' "$dir/package.json" 2>/dev/null
}

resolve_default_repo_url() {
  if [[ -n "${WORK_AGENT_REPO_URL:-}" ]]; then
    echo "$WORK_AGENT_REPO_URL"
    return
  fi
  if [[ -f "$SCRIPT_DIR/../agent/default-repo.url" ]]; then
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line%%#*}"
      line="$(echo "$line" | tr -d '[:space:]')"
      [[ -z "$line" ]] && continue
      echo "$line"
      return
    done < "$SCRIPT_DIR/../agent/default-repo.url"
  fi
  if git -C "$SCRIPT_DIR/.." rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$SCRIPT_DIR/.." remote get-url origin 2>/dev/null || true
  fi
}

ROOT=""
if is_work_agent_repo "$SCRIPT_DIR/.."; then
  ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  echo "→ Using existing Work Agent repo: $ROOT"
else
  if [[ -z "$REPO_URL" ]]; then
    REPO_URL="$(resolve_default_repo_url || true)"
  fi
  if [[ -z "$REPO_URL" ]]; then
    echo "Error: no clone URL. Use --repo URL, WORK_AGENT_REPO_URL, or agent/default-repo.url"
    exit 1
  fi
  if [[ -z "$TARGET_DIR" ]]; then
    TARGET_DIR="$(pwd)/work-agent"
  fi
  if [[ -d "$TARGET_DIR/.git" ]] || is_work_agent_repo "$TARGET_DIR"; then
    echo "→ Directory exists: $TARGET_DIR"
    ROOT="$(cd "$TARGET_DIR" && pwd)"
  else
    echo "→ Cloning $REPO_URL → $TARGET_DIR"
    git clone "$REPO_URL" "$TARGET_DIR"
    ROOT="$(cd "$TARGET_DIR" && pwd)"
  fi
fi

cd "$ROOT"
# shellcheck source=agent-slug.sh
source "$ROOT/scripts/agent-slug.sh"

if [[ ! -f "$ROOT/agent/agent-name" ]]; then
  echo "dan" > "$ROOT/agent/agent-name"
fi

echo "→ Onboarding agent ${AGENT_DISPLAY_NAME} (${AGENT_SLUG})"

SELECT_ARGS=()
[[ -n "$IDE_ARG" ]] && SELECT_ARGS+=(--ide "$IDE_ARG")
[[ -n "$IDE_OTHER" ]] && SELECT_ARGS+=(--other "$IDE_OTHER")
[[ "$NON_INTERACTIVE" == true ]] && SELECT_ARGS+=(--non-interactive)
bash "$ROOT/scripts/select-ide.sh" "${SELECT_ARGS[@]}"
# shellcheck source=read-ide-target.sh
source "$ROOT/scripts/read-ide-target.sh"
echo "→ Target folder: $IDE_DIR/ ($IDE_LABEL)"
bash "$ROOT/scripts/deploy-ide-assets.sh"
bash "$ROOT/scripts/verify-ide-setup.sh" --strict

ARGS=()
[[ "$FRESH" == true ]] && ARGS+=(--fresh)

bash "$ROOT/scripts/generate-agent-wrappers.sh"
if ((${#ARGS[@]})); then
  exec bash "$ROOT/scripts/call-agent.sh" "${ARGS[@]}"
else
  exec bash "$ROOT/scripts/call-agent.sh"
fi
