#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import {
  KnowledgeService,
  WorkflowEngine,
  resolveWorkAgentRoot,
} from "@work-agent/agent-core";

const root = resolveWorkAgentRoot();
const knowledge = new KnowledgeService(root);
const workflows = new WorkflowEngine(root);

const server = new McpServer({
  name: "work-agent",
  version: "0.1.0",
});

function toolError(message: string, code: string) {
  return {
    content: [{ type: "text" as const, text: JSON.stringify({ error: code, message }) }],
    isError: true,
  };
}

server.tool(
  "knowledge_search",
  "Search markdown knowledge files under ./knowledge (filename and body substring match).",
  {
    query: z.string().describe("Search string"),
    limit: z.number().int().min(1).max(50).optional(),
  },
  async ({ query, limit }) => {
    try {
      const result = await knowledge.search(query, limit ?? 10);
      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
      };
    } catch (e) {
      const message = e instanceof Error ? e.message : "search_failed";
      return toolError(message, "search_failed");
    }
  },
);

server.tool(
  "knowledge_read",
  "Read a single knowledge file by path relative to knowledge/ (e.g. methods/note.md).",
  {
    path: z.string().describe("Relative path under knowledge/"),
  },
  async ({ path: filePath }) => {
    try {
      const result = await knowledge.read(filePath);
      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
      };
    } catch (e) {
      const message = e instanceof Error ? e.message : "read_failed";
      return toolError(message, "read_failed");
    }
  },
);

server.tool(
  "knowledge_write",
  "Create or update a knowledge markdown file under knowledge/.",
  {
    path: z.string(),
    body: z.string(),
    frontmatter: z.record(z.unknown()).optional(),
    mode: z.enum(["create", "update"]).optional(),
  },
  async ({ path: filePath, body, frontmatter, mode }) => {
    try {
      const result = await knowledge.write(
        filePath,
        body,
        frontmatter ?? {},
        mode ?? "create",
      );
      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
      };
    } catch (e) {
      const message = e instanceof Error ? e.message : "write_failed";
      return toolError(message, "write_failed");
    }
  },
);

server.tool(
  "workflow_list",
  "List executable workflows from .cursor/workflows/**/*.yaml",
  {},
  async () => {
    try {
      const result = await workflows.list();
      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
      };
    } catch (e) {
      const message = e instanceof Error ? e.message : "list_failed";
      return toolError(message, "list_failed");
    }
  },
);

server.tool(
  "workflow_run",
  "Load a workflow by id and return skill step content for the Agent to execute (MVP).",
  {
    id: z.string().describe("Workflow id from workflow_list"),
    inputs: z.record(z.unknown()).optional(),
    session_id: z.string().optional(),
  },
  async ({ id, inputs }) => {
    try {
      const result = await workflows.run(id, inputs ?? {});
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(result, null, 2),
          },
        ],
      };
    } catch (e) {
      const message = e instanceof Error ? e.message : "run_failed";
      return toolError(message, "run_failed");
    }
  },
);

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
