# Draft workflows

Markdown (and notes) for designing workflows before promotion.

**Production (runtime):** [`.cursor/workflows/`](../../.cursor/workflows/)

When a workflow is ready:

1. Convert the draft to validated YAML (see `agent/architecture.md` workflow schema).
2. Place the file under `.cursor/workflows/` (e.g. `discovery/market-scan.yaml`).
3. Test via MCP `workflow_list` and `workflow_run` after the MCP server is built.
