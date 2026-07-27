# Work Agent — agent instructions

This repo trains a personalized AI agent for product discovery and strategy (see `agent/context.md` and `agent/architecture.md`).

| Command | Purpose |
| --- | --- |
| `./onboard-agent-dan` | First-time: clone repo (optional), install, build, open Cursor |
| `./call-agent-dan` | Routine: prepare MCP + open Cursor |
| `./rename-agent-dan <slug>` | Rename agent and refresh entrypoint scripts |

Clone URL: [ethanhuangcst/agent-dan](https://github.com/ethanhuangcst/agent-dan.git) (`agent/default-repo.url`), or `--repo` / `WORK_AGENT_REPO_URL`.

## Rules, skills, workflows

| Type | Production | Draft |
| --- | --- | --- |
| Rules | `.cursor/rules/` | `agent/define-rules/` |
| Skills | `.cursor/skills/<name>/SKILL.md` | `agent/define-skills/` |
| Workflows | `.cursor/workflows/` | `agent/define-workflows/` |

Start with `.cursor/rules/00-project-source-of-truth.mdc`. Prefer **project** `.cursor/` over global `~/.cursor/` defaults.

**Knowledge:** `./knowledge/` (see `knowledge/README.md`).

## MCP server (Cursor Agent mode)

The **work-agent** MCP server connects Cursor to repo knowledge and workflows:

- **Config:** `.cursor/mcp.json`
- **Docs:** `.cursor/MCP.md`, `packages/mcp-server/README.md`
- **Tools:** `knowledge_search`, `knowledge_read`, `knowledge_write`, `workflow_list`, `workflow_run`

Use MCP tools for validated writes and workflow execution; use rules/skills for behavior and playbooks. Enable **work-agent** under Cursor **Settings → MCP** after building `packages/mcp-server`.

## Major task completion

Follow `.cursor/rules/continuous-learning.mdc`: ask before marking done, then samectx sync and retrospective when the user confirms.
