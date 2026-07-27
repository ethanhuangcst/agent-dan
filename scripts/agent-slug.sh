#!/usr/bin/env bash
# shellcheck disable=SC2034
# Source from other scripts: ROOT must be set to repo root first.
_agent_slug_file="${ROOT}/agent/agent-name"
if [[ -f "$_agent_slug_file" ]]; then
  AGENT_SLUG="$(tr -d '[:space:]' < "$_agent_slug_file" | head -1)"
fi
AGENT_SLUG="${AGENT_SLUG:-dan}"
# Display name: first letter upper (dan -> Dan)
AGENT_DISPLAY_NAME="$(echo "${AGENT_SLUG:0:1}" | tr '[:lower:]' '[:upper:]')${AGENT_SLUG:1}"
