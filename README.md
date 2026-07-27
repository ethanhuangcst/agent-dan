# Work Agent

Personalized AI agent for product discovery and strategy (innovation work before a fixed domain is chosen).

## Documentation map

| Doc | Purpose |
| --- | --- |
| [`agent/context.md`](agent/context.md) | Situation and task |
| [`agent/architecture.md`](agent/architecture.md) | Full technical architecture |
| [`agent/mvp-cursor.md`](agent/mvp-cursor.md) | MVP walkthrough for Cursor |
| [`AGENTS.md`](AGENTS.md) | Cursor agent entrypoint |
| [`.cursor/MCP.md`](.cursor/MCP.md) | Enable **work-agent** MCP in Cursor |
| [`.cursor/mcp.json`](.cursor/mcp.json) | MCP server registration |
| [`packages/mcp-server/README.md`](packages/mcp-server/README.md) | MCP tool contracts and implementation |
| [`packages/agent-core/README.md`](packages/agent-core/README.md) | Shared knowledge + workflow logic |
| [`knowledge/README.md`](knowledge/README.md) | Knowledge base conventions |

## Layout

- **Draft:** `agent/define-rules`, `agent/define-skills`, `agent/define-workflows`
- **Production:** `.cursor/rules`, `.cursor/skills`, `.cursor/workflows`, `./knowledge`
- **MCP:** `packages/mcp-server` (stdio, server name **work-agent**)

## Quick start

| Command | When |
| --- | --- |
| `./onboard-agent-dan` | **First time** — choose IDE (Cursor / Claude / Codex / Other), deploy rules/skills/workflows to `.{ide}/`, install, build, open IDE |
| `./call-agent-dan` | **Daily** — install/build if needed, open Cursor |
| `./rename-agent-dan <slug>` | Rename agent (regenerates `call/onboard/rename-*` entrypoints) |

Agent slug is stored in [`agent/agent-name`](agent/agent-name). Default clone URL: [https://github.com/ethanhuangcst/agent-dan.git](https://github.com/ethanhuangcst/agent-dan.git) ([`agent/default-repo.url`](agent/default-repo.url)).

```bash
./onboard-agent-dan
# prompts: A Claude / B Codex / C Cursor / D Other → deploys to .cursor, .claude, .codex, etc.
# or: ./onboard-agent-dan --ide cursor --non-interactive
./call-agent-dan
```

Onboard writes [`agent/ide-target`](agent/ide-target) (`IDE_DIR`), restores `.cursor/` from git, deploys to `$IDE_DIR`, and verifies with `bash scripts/verify-ide-setup.sh --strict`. Re-sync after pull: `bash scripts/deploy-ide-assets.sh`.

Then use **Agent mode** in Cursor (or load `$IDE_DIR/rules` and `$IDE_DIR/skills` in your IDE). MCP **work-agent** uses `IDE_DIR` for workflows/skills when set.

See `.cursor/rules/00-project-source-of-truth.mdc` for precedence and paths.
