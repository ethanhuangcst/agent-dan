#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=agent-slug.sh
source "$ROOT/scripts/agent-slug.sh"

OLD_SLUG="$AGENT_SLUG"

usage() {
  echo "Usage: rename-agent-${OLD_SLUG} <new-slug>"
  echo "  Renames the agent (e.g. dan → alex). Regenerates call/onboard/rename entrypoints."
  echo "  Slug: lowercase letters, numbers, hyphens; 2–32 chars."
}

NEW_SLUG="${1:-}"
if [[ -z "$NEW_SLUG" ]] || [[ "$NEW_SLUG" == "--help" ]] || [[ "$NEW_SLUG" == "-h" ]]; then
  usage
  exit 0
fi

if ! [[ "$NEW_SLUG" =~ ^[a-z0-9][a-z0-9-]{1,30}[a-z0-9]$|^[a-z0-9]{2}$ ]]; then
  echo "Error: invalid slug '$NEW_SLUG'"
  usage
  exit 1
fi

if [[ "$NEW_SLUG" == "$OLD_SLUG" ]]; then
  echo "Slug unchanged ($OLD_SLUG)."
  exit 0
fi

echo "$NEW_SLUG" > "$ROOT/agent/agent-name"
# shellcheck source=agent-slug.sh
source "$ROOT/scripts/agent-slug.sh"

# Remove old root wrappers
rm -f "$ROOT/call-agent-${OLD_SLUG}" "$ROOT/onboard-agent-${OLD_SLUG}" "$ROOT/rename-agent-${OLD_SLUG}"

bash "$ROOT/scripts/generate-agent-wrappers.sh"

# Update Makefile npm script aliases (portable sed)
if [[ -f "$ROOT/package.json" ]]; then
  node <<'NODE' "$ROOT/package.json" "$OLD_SLUG" "$NEW_SLUG"
const fs = require('fs');
const [,, pkgPath, oldS, newS] = process.argv;
const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
const scripts = pkg.scripts || {};
for (const key of Object.keys(scripts)) {
  if (key.includes(`-${oldS}`)) {
    const nk = key.replace(`-${oldS}`, `-${newS}`);
    scripts[nk] = scripts[key];
    delete scripts[key];
  }
}
pkg.scripts = scripts;
fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');
NODE
fi

# Replace slug in user-facing docs (limited set)
DOCS=(
  README.md AGENTS.md agent/mvp-cursor.md .cursor/MCP.md
)
for doc in "${DOCS[@]}"; do
  [[ -f "$ROOT/$doc" ]] || continue
  sed -i '' \
    -e "s/call-agent-${OLD_SLUG}/call-agent-${NEW_SLUG}/g" \
    -e "s/onboard-agent-${OLD_SLUG}/onboard-agent-${NEW_SLUG}/g" \
    -e "s/rename-agent-${OLD_SLUG}/rename-agent-${NEW_SLUG}/g" \
    "$ROOT/$doc" 2>/dev/null || sed -i \
    -e "s/call-agent-${OLD_SLUG}/call-agent-${NEW_SLUG}/g" \
    -e "s/onboard-agent-${OLD_SLUG}/onboard-agent-${NEW_SLUG}/g" \
    -e "s/rename-agent-${OLD_SLUG}/rename-agent-${NEW_SLUG}/g" \
    "$ROOT/$doc"
done

echo "Renamed agent: ${OLD_SLUG} → ${NEW_SLUG}"
echo "  New commands: call-agent-${NEW_SLUG}, onboard-agent-${NEW_SLUG}, rename-agent-${NEW_SLUG}"
