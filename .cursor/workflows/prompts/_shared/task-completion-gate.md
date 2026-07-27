# Shared — Task completion gate (continuous learning)

Use at the end of **major-task** workflows after deliverables are written. Complements `.cursor/rules/continuous-learning.mdc`.

## Two different confirmations

If this workflow already asked the user to confirm research, content, or storage, that **yes** is **not** task completion. Do not run samectx or retrospective until the user confirms in **this** step.

## Ask before closing

Ask exactly:

> Can I mark this as done?

Wait for explicit confirm (yes / done / approve). If the user defers or changes scope, continue their work—do not run sync or retrospective.

## After task-completion confirm

Run the next workflow steps in order (typically skill steps already declared in YAML):

1. **samectx** — `samectx sync` with `--tasks`, `--keypoints`, `--decisions` (semicolon-separated; no secrets).
2. **retrospective** — ADRs → `specs/adr/`; process knowledge → `specs/knowledge/`; present Retrospective Summary.

Do not commit unless the user requests a commit.

## Used by

- `learn-knowledge` → `prompts/learn-knowledge/05-task-completion-gate.md` (workflow-specific notes + this gate)

Copy or reference this file when adding completion gates to other workflows (see `agent/define-workflows/workflow.md`).
