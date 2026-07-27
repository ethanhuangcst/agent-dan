import fs from "node:fs/promises";
import fsSync from "node:fs";
import path from "node:path";

export type KnowledgeHit = {
  path: string;
  title: string;
  snippet: string;
};

export type KnowledgeReadResult = {
  path: string;
  frontmatter: Record<string, unknown>;
  body: string;
};

function resolveJailed(root: string, baseDir: string, relativePath: string): string {
  const jailRoot = path.resolve(root, baseDir);
  const full = path.normalize(path.join(jailRoot, relativePath));
  if (full !== jailRoot && !full.startsWith(jailRoot + path.sep)) {
    throw new Error("path_outside_jail");
  }
  return full;
}

function parseFrontmatter(raw: string): {
  frontmatter: Record<string, unknown>;
  body: string;
} {
  const match = raw.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)$/);
  if (!match) {
    return { frontmatter: {}, body: raw };
  }
  const frontmatter: Record<string, unknown> = {};
  for (const line of match[1].split("\n")) {
    const idx = line.indexOf(":");
    if (idx === -1) continue;
    const key = line.slice(0, idx).trim();
    let val: unknown = line.slice(idx + 1).trim();
    if (typeof val === "string" && val.startsWith('"') && val.endsWith('"')) {
      val = val.slice(1, -1);
    }
    frontmatter[key] = val;
  }
  return { frontmatter, body: match[2] };
}

async function walkMarkdown(dir: string): Promise<string[]> {
  const out: string[] = [];
  let entries;
  try {
    entries = await fs.readdir(dir, { withFileTypes: true });
  } catch {
    return out;
  }
  for (const ent of entries) {
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) {
      out.push(...(await walkMarkdown(p)));
    } else if (ent.name.endsWith(".md") && ent.name !== "README.md") {
      out.push(p);
    }
  }
  return out;
}

export class KnowledgeService {
  constructor(private readonly root: string) {}

  private knowledgeDir(): string {
    return path.join(this.root, "knowledge");
  }

  async search(query: string, limit = 10): Promise<{ hits: KnowledgeHit[] }> {
    const q = query.toLowerCase().trim();
    const files = await walkMarkdown(this.knowledgeDir());
    const hits: KnowledgeHit[] = [];

    for (const file of files) {
      const rel = path.relative(this.knowledgeDir(), file);
      const raw = await fs.readFile(file, "utf8");
      const { frontmatter, body } = parseFrontmatter(raw);
      const title = String(frontmatter.title ?? rel);
      const haystack = `${title}\n${body}`.toLowerCase();
      if (!q || haystack.includes(q) || rel.toLowerCase().includes(q)) {
        const idx = q ? haystack.indexOf(q) : 0;
        const snippetStart = Math.max(0, idx - 40);
        const snippet = (idx >= 0 ? body : body.slice(0, 120)).slice(
          snippetStart,
          snippetStart + 160,
        );
        hits.push({ path: rel, title, snippet: snippet.replace(/\s+/g, " ").trim() });
      }
      if (hits.length >= limit) break;
    }

    return { hits };
  }

  async read(relativePath: string): Promise<KnowledgeReadResult> {
    const full = resolveJailed(this.root, "knowledge", relativePath);
    const raw = await fs.readFile(full, "utf8");
    const { frontmatter, body } = parseFrontmatter(raw);
    return {
      path: path.relative(this.knowledgeDir(), full),
      frontmatter,
      body,
    };
  }

  async write(
    relativePath: string,
    body: string,
    frontmatter: Record<string, unknown> = {},
    mode: "create" | "update" = "create",
  ): Promise<{ path: string; id: string }> {
    if (process.env.WORK_AGENT_READ_ONLY === "1") {
      throw new Error("read_only");
    }
    const full = resolveJailed(this.root, "knowledge", relativePath);
    await fs.mkdir(path.dirname(full), { recursive: true });
    if (mode === "create") {
      try {
        await fs.access(full);
        throw new Error("file_exists");
      } catch (e) {
        if (e instanceof Error && e.message === "file_exists") throw e;
      }
    }
    const fmLines = Object.entries(frontmatter).map(
      ([k, v]) => `${k}: ${JSON.stringify(v)}`,
    );
    const content =
      fmLines.length > 0
        ? `---\n${fmLines.join("\n")}\n---\n\n${body}`
        : body;
    await fs.writeFile(full, content, "utf8");
    const id = String(frontmatter.id ?? relativePath);
    return { path: path.relative(this.knowledgeDir(), full), id };
  }
}

export type WorkflowSummary = {
  id: string;
  title: string;
  description: string;
  path: string;
};

export type WorkflowStepResult = {
  stepId: string;
  type: string;
  status: "loaded" | "skipped" | "error";
  detail: string;
};

export class WorkflowEngine {
  constructor(private readonly root: string) {}

  private ideRoot(): string {
    return resolveIdeDir(this.root);
  }

  private workflowsDir(): string {
    return path.join(this.ideRoot(), "workflows");
  }

  private skillPath(ref: string): string {
    return path.join(this.ideRoot(), "skills", ref, "SKILL.md");
  }

  async list(): Promise<{ workflows: WorkflowSummary[] }> {
    const workflows: WorkflowSummary[] = [];
    const files = await this.collectYaml(this.workflowsDir());
    for (const file of files) {
      const raw = await fs.readFile(file, "utf8");
      const meta = this.parseSimpleYamlMeta(raw);
      const rel = path.relative(this.workflowsDir(), file);
      workflows.push({
        id: meta.id ?? path.basename(file, path.extname(file)),
        title: meta.title ?? meta.id ?? rel,
        description: meta.description ?? "",
        path: rel,
      });
    }
    return { workflows };
  }

  private async collectYaml(dir: string): Promise<string[]> {
    const out: string[] = [];
    let entries;
    try {
      entries = await fs.readdir(dir, { withFileTypes: true });
    } catch {
      return out;
    }
    for (const ent of entries) {
      const p = path.join(dir, ent.name);
      if (ent.isDirectory()) {
        out.push(...(await this.collectYaml(p)));
      } else if (ent.name.endsWith(".yaml") || ent.name.endsWith(".yml")) {
        out.push(p);
      }
    }
    return out;
  }

  /** Minimal YAML field extraction (no dependency). */
  private parseSimpleYamlMeta(raw: string): {
    id?: string;
    title?: string;
    description?: string;
  } {
    const pick = (key: string) => {
      const m = raw.match(new RegExp(`^${key}:\\s*(.+)$`, "m"));
      return m?.[1]?.replace(/^["']|["']$/g, "").trim();
    };
    return {
      id: pick("id"),
      title: pick("title"),
      description: pick("description"),
    };
  }

  async run(
    id: string,
    inputs: Record<string, unknown> = {},
  ): Promise<{
    status: string;
    workflowId: string;
    inputs: Record<string, unknown>;
    steps: WorkflowStepResult[];
    summary_markdown: string;
  }> {
    const files = await this.collectYaml(this.workflowsDir());
    let matched: string | undefined;
    let raw = "";
    for (const file of files) {
      const content = await fs.readFile(file, "utf8");
      const meta = this.parseSimpleYamlMeta(content);
      const fileId = meta.id ?? path.basename(file, path.extname(file));
      if (fileId === id) {
        matched = file;
        raw = content;
        break;
      }
    }
    if (!matched) {
      throw new Error(`workflow_not_found:${id}`);
    }

    const steps: WorkflowStepResult[] = [];
    const stepBlocks = raw.split(/\n\s*-\s+id:/).slice(1);
    const interactive = /^interactive:\s*true/m.test(raw);
    for (const block of stepBlocks) {
      const stepRaw = "id:" + block;
      const stepId = stepRaw.match(/^id:\s*(\S+)/)?.[1] ?? "unknown";
      const type = stepRaw.match(/type:\s*(\S+)/)?.[1] ?? "unknown";
      const ref = stepRaw.match(/ref:\s*(\S+)/)?.[1];
      const template = stepRaw.match(/template:\s*(\S+)/)?.[1];

      if (type === "skill" && ref) {
        const skillPath = this.skillPath(ref);
        try {
          const skillBody = await fs.readFile(skillPath, "utf8");
          steps.push({
            stepId,
            type,
            status: "loaded",
            detail: skillBody.slice(0, 12000),
          });
        } catch {
          steps.push({
            stepId,
            type,
            status: "error",
            detail: `Skill not found: ${ref}`,
          });
        }
      } else if (type === "prompt" && template) {
        const promptPath = path.join(this.workflowsDir(), template);
        try {
          const promptBody = await fs.readFile(promptPath, "utf8");
          steps.push({
            stepId,
            type,
            status: "loaded",
            detail: promptBody.slice(0, 12000),
          });
        } catch {
          steps.push({
            stepId,
            type,
            status: "error",
            detail: `Prompt template not found: ${template}`,
          });
        }
      } else {
        steps.push({
          stepId,
          type,
          status: "skipped",
          detail: `Unsupported or incomplete step (type=${type}).`,
        });
      }
    }

    const stepIds = steps.map((s) => s.stepId);
    const gateIndex = stepIds.indexOf("task-completion-gate");
    const closingSequence =
      gateIndex >= 0
        ? `\n**Required closing sequence:** ${stepIds.slice(gateIndex).join(" → ")}\nAt **task-completion-gate**, use **AskQuestion** with **Mark task done** / Not yet / Pause — do not treat research/store **yes** as task done.\n`
        : "";

    const summary = [
      `# Workflow: ${id}`,
      interactive
        ? "\n**Interactive workflow** — execute steps **in order** across multiple chat turns. Do not treat research/store confirmation as the final step; continue through task-completion-gate, samectx, and retrospective when defined in YAML.\n"
        : "",
      closingSequence,
      "Follow steps **in order**. Apply workflow inputs where relevant.",
      "",
      "```json",
      JSON.stringify(inputs, null, 2),
      "```",
      "",
      ...steps.map(
        (s) =>
          `## Step ${s.stepId} (${s.type}, ${s.status})\n\n${s.detail.slice(0, 8000)}`,
      ),
    ].join("\n");

    return {
      status: "ready_for_agent",
      workflowId: id,
      inputs,
      steps,
      summary_markdown: summary,
    };
  }
}

export function resolveWorkAgentRoot(): string {
  const env = process.env.WORK_AGENT_ROOT;
  if (env && env !== ".") {
    return path.resolve(env);
  }
  return process.cwd();
}

/** Project IDE asset root (e.g. .cursor, .claude) — see agent/ide-target */
export function resolveIdeDir(root: string): string {
  const env = process.env.WORK_AGENT_IDE_DIR?.trim();
  if (env) {
    return path.isAbsolute(env) ? env : path.join(root, env);
  }
  const target = path.join(root, "agent", "ide-target");
  try {
    const text = fsSync.readFileSync(target, "utf8");
    const m = text.match(/^IDE_DIR=(.+)$/m);
    if (m?.[1]) {
      return path.join(root, m[1].trim());
    }
  } catch {
    // default
  }
  return path.join(root, ".cursor");
}
