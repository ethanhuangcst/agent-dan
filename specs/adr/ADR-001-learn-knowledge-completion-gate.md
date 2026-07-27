# ADR-001: Encode continuous-learning in learn-knowledge workflow steps

## Status

Accepted

## Context

After **learn-knowledge** completed (research confirm, `knowledge_write` to `./knowledge/`), samectx sync and retrospective did not run despite `continuous-learning.mdc` (`alwaysApply: true`). Agents treated research **yes** as session complete and did not ask the task-done question.

MCP `workflow_run` only loads prompt/skill text; it does not invoke samectx or retrospective automatically.

## Decision

Extend production workflow `learn-knowledge` with three steps after storage:

1. `task-completion-gate` (prompt) — ask *“Can I mark this as done?”*; distinguish from research confirmation.
2. `samectx-sync` (skill `samectx`) — run after user confirms task completion.
3. `retrospective` (skill `retrospective`) — persist to `specs/adr/` and `specs/knowledge/` as appropriate.

Document the pattern in `agent/define-workflows/workflow.md` for other major-task workflows.

## Rationale

**Alternatives considered:**

- **Rule-only** — Already present; failed in practice due to agent non-compliance and ambiguous confirmation scopes.
- **Post-workflow hook in MCP engine** — Out of MVP scope; would hide human gate and conflate store confirm with task done.
- **Explicit workflow steps** — Matches existing skill/prompt composition; visible in `workflow_run` output; teachable in draft docs.

Chosen: explicit steps — minimal engine change, maximum clarity for Cursor Agent execution.

## Consequences

- Every learn-knowledge run should end with an extra user turn unless the user defers.
- Other workflows should copy the completion-gate pattern when they deliver a major artifact.
- Draft and production YAML/prompts must stay in sync (`agent/define-workflows/` ↔ `.cursor/workflows/`).

## Date

2026-07-27
