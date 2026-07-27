#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=agent-slug.sh
source "$ROOT/scripts/agent-slug.sh"

write_wrapper() {
  local name="$1"
  local target="$2"
  cat > "$ROOT/$name" <<EOF
#!/usr/bin/env bash
exec "\$(dirname "\$0")/$target" "\$@"
EOF
  chmod +x "$ROOT/$name"
}

# Remove stale agent entrypoints at repo root
for f in "$ROOT"/call-agent-* "$ROOT"/onboard-agent-* "$ROOT"/rename-agent-*; do
  [[ -e "$f" ]] || continue
  [[ "$f" == *"$AGENT_SLUG" ]] && continue
  rm -f "$f"
done

write_wrapper "call-agent-${AGENT_SLUG}" "scripts/call-agent.sh"
write_wrapper "onboard-agent-${AGENT_SLUG}" "scripts/onboard-agent.sh"
write_wrapper "rename-agent-${AGENT_SLUG}" "scripts/rename-agent.sh"

echo "Generated: call-agent-${AGENT_SLUG}, onboard-agent-${AGENT_SLUG}, rename-agent-${AGENT_SLUG}"
