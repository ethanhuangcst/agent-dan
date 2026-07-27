# Work Agent MCP server (`work-agent`)

Stdio MCP server for Cursor. Thin transport layer over **agent-core** services (knowledge + workflow engine).

## Responsibilities

| Layer | Location | Role |
| --- | --- | --- |
| MCP adapter | `packages/mcp-server/` | Register tools, stdio transport, Cursor-facing descriptions |
| Domain logic | `packages/agent-core/` | Knowledge service, workflow engine, shared tool handlers |
| Data | Repo root | `./knowledge`, `.cursor/workflows/` |

Do not duplicate business logic in the MCP package; call agent-core functions from tool handlers.

## Transport

- **stdio** for Cursor Desktop (`mcp-server-patterns`).
- Pin `@modelcontextprotocol/sdk` in `package.json`; validate inputs with **Zod**.

## Entry point

Build output: `dist/index.js` (referenced from `.cursor/mcp.json`).

Bootstrap flow:

1. Read `WORK_AGENT_ROOT` (default: `cwd`).
2. Construct `KnowledgeService` and `WorkflowEngine` with rooted paths.
3. Create `McpServer`, register tools, connect stdio transport.

## Tools

Implement these first (see `agent/architecture.md`):

### `knowledge_search`

- **Input:** `query` (string), optional `limit`, optional `tags[]`
- **Output:** `{ hits: [{ path, title, snippet, score? }] }`
- **Behavior:** Search only under `${WORK_AGENT_ROOT}/knowledge`

### `knowledge_read`

- **Input:** `path` (relative to `knowledge/`)
- **Output:** `{ path, frontmatter, body }` or structured error

### `knowledge_write`

- **Input:** `path`, `body`, optional `frontmatter` object, optional `mode` (`create` | `update`)
- **Output:** `{ path, id }`
- **Behavior:** Validate frontmatter, update `_index.yaml` when present; reject path traversal

### `workflow_list`

- **Input:** optional `tag`
- **Output:** `{ workflows: [{ id, title, description, path }] }`
- **Source:** `${WORK_AGENT_ROOT}/.cursor/workflows/**/*.yaml`

### `workflow_run`

- **Input:** `id`, `inputs` (object), optional `session_id`
- **Output:** `{ status, outputs, steps[], summary_markdown }`
- **Behavior:** Load YAML, run steps via agent-core; emit step events for logging

## Optional MCP surfaces (later)

- **Resources:** `knowledge://...` read-only URIs for large files
- **Prompts:** parameterized templates for common discovery tasks

## Development

When scaffolded:

```bash
# from repo root
npm install
npm run build -w packages/mcp-server
node packages/mcp-server/dist/index.js   # manual smoke test (stdio)
```

Add Makefile targets: `dev-mcp`, `test`, wired to monorepo scripts per project **makefile** rule.

## Testing

- Unit tests: tool handlers with temp `knowledge/` and `.cursor/workflows/` fixtures
- Integration: invoke server with MCP client or Cursor MCP panel after build

## Errors

Return JSON the model can act on: `{ "error": "not_found", "message": "..." }`. No stack traces or absolute paths outside `WORK_AGENT_ROOT` in client-visible payloads.
