import { describe, it } from "node:test";
import assert from "node:assert";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { KnowledgeService, WorkflowEngine, resolveIdeDir } from "./index.js";

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

describe("resolveIdeDir", () => {
  it("should_default_to_dot_cursor", () => {
    const dir = resolveIdeDir(repoRoot);
    assert.ok(dir.endsWith(`${path.sep}.cursor`));
  });

  it("should_use_WORK_AGENT_IDE_DIR_env", () => {
    const prev = process.env.WORK_AGENT_IDE_DIR;
    process.env.WORK_AGENT_IDE_DIR = ".claude";
    try {
      const dir = resolveIdeDir(repoRoot);
      assert.ok(dir.endsWith(`${path.sep}.claude`));
    } finally {
      if (prev === undefined) delete process.env.WORK_AGENT_IDE_DIR;
      else process.env.WORK_AGENT_IDE_DIR = prev;
    }
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
