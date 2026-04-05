---
name: llm-wiki-stack
description: Use when ingesting sources into a knowledge wiki, maintaining a compounding knowledge base, querying accumulated knowledge, or running wiki health checks. Also use when setting up the LLM wiki stack (obsidian-headless, ByteRover, obsidian-mind) on a new machine.
---

# LLM Wiki Stack

A compounding personal knowledge base maintained by an AI assistant. The wiki gets richer with every ingest — not a retrieval index, a compounding artifact.

**Key distinction:** RAG retrieves from scratch every time. This wiki is built once and kept current.

---

## Core Operations

### Ingest a Source

When adding a new source (URL, article, document, market signal):

1. **Read** the source fully
2. **Write** a summary page → `wiki/sources/<title>.md`
3. **Update** relevant entity pages in `wiki/entities/` (create if missing)
4. **Update** relevant project pages using the schema's update triggers
5. **Update** `wiki/index.md` — add/modify entries
6. **Append** to `wiki/log.md` — `## [YYYY-MM-DD] ingest | Source Title`

A single source typically touches 5-15 pages. This is expected and correct.

**Never just create one file and stop.** Every ingest must update related existing pages.

### Query the Wiki

1. Read `wiki/index.md` to find relevant pages
2. Read the relevant pages
3. Synthesise answer with citations: `(source: [[Source Title]])`
4. **File good answers back** as `wiki/topics/<topic>.md` — don't let synthesis disappear into chat history
5. Append to `wiki/log.md` — `## [YYYY-MM-DD] query | Question asked`

### Lint the Wiki

Run periodically or when wiki feels stale:

- Orphan pages (no inbound links)
- Contradictions between entity pages and source summaries  
- Important concepts mentioned but lacking their own page
- Missing cross-references
- Suggest new sources based on open questions

Append results to `wiki/log.md`.

---

## Entity Page Format

```markdown
# [Entity Name]

**Type:** person | company | product | concept
**Last updated:** YYYY-MM-DD

## Summary
One paragraph.

## Key Facts
- Fact (source: [[Source Title]])

## Relationships
- [[Related Entity]] — how they relate

## Timeline
- YYYY-MM-DD: Event (source: [[Source Title]])

## Open Questions
- Question needing a source to answer

## Contradictions
- Claim A (source X) vs Claim B (source Y) — unresolved
```

---

## Source Page Format

```markdown
# [Source Title]

**Type:** article | paper | announcement | analyst-piece
**URL:** 
**Date:** YYYY-MM-DD

## Summary
2-3 sentences.

## Key Takeaways
- Takeaway 1

## Pages Updated
- [[Page]] — what changed
```

---

## ByteRover Commands

ByteRover handles structured domain/project knowledge (context tree with recency decay).

```bash
# Add knowledge
brv curate "factual statement about a project or domain" 

# Query knowledge  
brv query "what do we know about X?"

# Sync to cloud
brv push

# Check status
brv status
```

**When to use ByteRover vs wiki:**
- **ByteRover** — structured project/domain facts (what Anvil does, benchmark numbers, ICP)
- **Wiki** — cross-domain synthesis, competitor landscape, market signals, research that spans projects

---

## Stack Setup (New Machine)

```bash
# 1. Install obsidian-headless
npm install -g obsidian-headless
ob login

# 2. Set up vault sync
ob sync-setup --vault "VaultName" --path ~/Vault --device-name "$(hostname)"

# 3. Install sync daemon
cp systemd/obsidian-sync.service ~/.config/systemd/user/
# Edit ExecStart paths to match your node binary location
systemctl --user daemon-reload && systemctl --user enable --now obsidian-sync.service

# 4. Install ByteRover
npm install -g byterover-cli
brv providers connect openai --api-key YOUR_KEY

# 5. Install obsidian-mind (personal memory)
git clone https://github.com/breferrari/obsidian-mind.git ~/Vault-mind
```

Find the node binary path with: `which node`
Find the obsidian-headless cli.js path with: `npm root -g`

---

## Schema

The vault's `WIKI-SCHEMA.md` (or named after your assistant) governs domain-specific update triggers — which pages to touch when specific events happen (competitor funding, benchmark run, positioning decision). Read it at the start of every wiki session.

**Repo:** github.com/joshuaboys/llm-wiki-stack
