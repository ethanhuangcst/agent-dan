# ADR-002: Structured AskQuestion for task-done gate

## Status
Accepted

## Context

Major tasks in this repo require a **task-done** confirmation separate from research/store **yes** (see ADR-001). Agents asked *Can I mark this as done?* in plain chat; users answered **yes** after an earlier research step, and agents skipped or mis-ran samectx and retrospective.

The Cursor session feedback bar (“How did the agent do?”) is product UI and is not available to agents as a custom completion prompt.

## Decision

At **task-completion-gate**, agents must use the **AskQuestion** tool with three fixed options:

- **Mark task done** (`mark-task-done`) — authorizes samectx + retrospective
- **Not yet** (`not-yet`)
- **Pause here** (`pause-no-sync`)

Plain chat **yes** / **done** after research or storage does **not** authorize samectx or retrospective. If AskQuestion is unavailable, require the exact phrase **Mark task done** in chat.

Canonical copy lives in `.cursor/workflows/prompts/_shared/task-completion-gate.md` and **`99-task-completion-gate.mdc`**.

## Rationale

- Labeled choices remove ambiguity between deliverable confirmation and session closure.
- AskQuestion is the supported in-chat structured UI in Agent mode; no custom pop-up API exists today.
- `workflow_run` summaries in agent-core reinforce the same contract.

## Consequences

- Agents must call AskQuestion before samectx on major tasks.
- Users get a clickable panel instead of parsing another free-text question.
- Future Cursor UI for agent-driven completion would supersede or complement this; update this ADR if product adds one.

## Date
2026-07-27
