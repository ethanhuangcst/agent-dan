# Learn Knowledge (draft)

Production workflow: [`.cursor/workflows/discovery/learn-knowledge.yaml`](../../.cursor/workflows/discovery/learn-knowledge.yaml)  
Workflow id: **`learn-knowledge`** (replaces `learn-new-knowledge`).

## Purpose

Interactive learning: research with user in the loop, confirm, then persist to `./knowledge/`.

## Steps

| Step | Type | Behavior |
| --- | --- | --- |
| 1. clarify-topic | prompt | Ask what to learn if `topic` input empty; use chat context |
| 2. research | skill `/research-ops` | Evidence from web/search + user messages |
| 3. summarize-and-confirm | prompt | Summary in chat; ask yes or feedback |
| 4. revision-loop | prompt | Re-research on feedback until user says yes |
| 5. store | skill `/knowledge-ops` | Dedupe, consolidate |
| 6. store-instructions | prompt | MCP `knowledge_write` to `./knowledge/` |

## Natural language

- “Run **learn-knowledge** workflow.”
- “Start learn-knowledge on social media marketing.”

## MCP

`workflow_run` with `{ "id": "learn-knowledge", "inputs": { "topic": "optional" } }` — then follow loaded steps across **multiple chat turns** until storage.
