---
title: Continuous-learning gate — workflow vs rule-only
type: ops-lesson
status: active
as_of: 2026-07-27
tags:
  - continuous-learning
  - workflows
  - cursor
related:
  - adr/ADR-001-learn-knowledge-completion-gate.md
---

# Continuous-learning gate — workflow vs rule-only

## Summary

Relying on `.cursor/rules/continuous-learning.mdc` alone did not produce samectx sync or retrospective after a completed **learn-knowledge** run. The agent stored `./knowledge/` and stopped without asking *“Can I mark this as done?”* User **yes** to research confirmation was scoped to `knowledge_write`, not task completion.

## Evidence

- Rule requires: ask before closing → on confirm → samectx → retrospective.
- **learn-knowledge** ended at `04-store.md` with no completion step.
- `workflow_run` embeds skills/prompts but does not execute samectx or retrospective server-side.
- Global DoD retrospective gate was also skipped in the same session.

## Lesson / guidance

1. For major interactive workflows, add explicit YAML steps: **task-completion-gate** prompt → **samectx** skill → **retrospective** skill (see `agent/define-workflows/workflow.md`).
2. Prompts must state that **research/store yes ≠ task-done yes**.
3. Verify project `.cursor/rules/` are active in Cursor for the workspace; treat `AGENTS.md` as backup, not the only hook.
4. Domain deliverables → `./knowledge/`; process/ops lessons from retros → `specs/knowledge/`.

## Links

- ADR-001: encode gate in learn-knowledge YAML
- `.cursor/workflows/prompts/learn-knowledge/05-task-completion-gate.md`
