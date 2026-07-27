import { describe, it } from "node:test";
import assert from "node:assert";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { KnowledgeService } from "./index.js";

const repoRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../../../..",
);

describe("KnowledgeService", () => {
  it("should_reject_path_outside_jail_when_read", async () => {
    const kb = new KnowledgeService(repoRoot);
    await assert.rejects(() => kb.read("../../package.json"), /path_outside_jail/);
  });
});
