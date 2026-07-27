import { describe, it } from "node:test";
import assert from "node:assert";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { KnowledgeService, WorkflowEngine } from "./index.js";

const repoRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../../..",
);

describe("KnowledgeService", () => {
  it("should_reject_path_outside_jail_when_read", async () => {
    const kb = new KnowledgeService(repoRoot);
    await assert.rejects(() => kb.read("../../package.json"), /path_outside_jail/);
  });
});

describe("WorkflowEngine", () => {
  it("should_include_closing_sequence_in_learn_knowledge_summary", async () => {
    const engine = new WorkflowEngine(repoRoot);
    const result = await engine.run("learn-knowledge", { topic: "test" });
    assert.match(result.summary_markdown, /task-completion-gate/);
    assert.match(result.summary_markdown, /Required closing sequence/);
    assert.match(
      result.summary_markdown,
      /task-completion-gate → samectx-sync → retrospective/,
    );
    assert.doesNotMatch(
      result.summary_markdown,
      /until the user confirms research \(step summarize-and-confirm\) before storage/,
    );
  });
});
