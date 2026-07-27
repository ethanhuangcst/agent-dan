# Knowledge base

Git-tracked domain and method knowledge for the Work Agent. Consumed by:

- MCP tools `knowledge_search`, `knowledge_read`, `knowledge_write` ([`packages/mcp-server`](../packages/mcp-server/README.md))
- Web chat agent core (same handlers as MCP)
- Cursor Agent (via MCP or direct file read)

Conventions and layout: [`agent/architecture.md`](../agent/architecture.md) (Knowledge subsystem).

Use YAML frontmatter: `id`, `title`, `tags`, `created`, `updated`, `source`, `related[]`.
