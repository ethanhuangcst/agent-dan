# Work Agent — agent instructions

This repo trains a personalized AI agent for product discovery and strategy (see `agent/context.md` and `agent/architecture.md`).

| Command | Purpose |
| --- | --- |
| `./onboard-agent-dan` | First-time: choose IDE (Claude/Codex/Cursor/Other), deploy to `.{ide}/`, install, build, open IDE |
| `./call-agent-dan` | Routine: prepare MCP + open Cursor |
| `./rename-agent-dan <slug>` | Rename agent and refresh entrypoint scripts |

Clone URL: [ethanhuangcst/agent-dan](https://github.com/ethanhuangcst/agent-dan.git) (`agent/default-repo.url`), or `--repo` / `WORK_AGENT_REPO_URL`.

## Rules, skills, workflows

| Type | Production | Draft |
| --- | --- | --- |
| Rules | `.cursor/rules/` | `agent/define-rules/` |
| Skills | `.cursor/skills/<name>/SKILL.md` | `agent/define-skills/` |
| Workflows | `.cursor/workflows/` | `agent/define-workflows/` |

Start with `.cursor/rules/00-project-source-of-truth.mdc` and **`99-task-completion-gate.mdc`**. Prefer **project** `.cursor/` over global `~/.cursor/` defaults.

**Knowledge:** `./knowledge/` (see `knowledge/README.md`).

## Major task completion

After any **major task** in this repo (not only learn-knowledge):

1. **AskQuestion** task-done gate (**Mark task done** / Not yet / Pause) — not bare chat **yes** after research/store.
2. On **Mark task done** → **samectx** → **retrospective** (`./adr/`, `./knowledge/`).

See `.cursor/rules/99-task-completion-gate.mdc` and `continuous-learning.mdc`. Research/store **yes** is not task-done **yes**.

## MCP server (Cursor Agent mode)

The **work-agent** MCP server connects Cursor to repo knowledge and workflows:

- **Config:** `.cursor/mcp.json`
- **Docs:** `.cursor/MCP.md`, `packages/mcp-server/README.md`
- **Tools:** `knowledge_search`, `knowledge_read`, `knowledge_write`, `workflow_list`, `workflow_run`

Use MCP tools for validated writes and workflow execution; use rules/skills for behavior and playbooks. Enable **work-agent** under Cursor **Settings → MCP** after building `packages/mcp-server`.
