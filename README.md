# LLM Wiki Stack

Your AI agent is smart but it doesn't know anything about your life. This fixes that.

Every conversation, meeting, article, and signal flows into a personal knowledge base. Your agent reads it before every response and writes to it after every conversation. The wiki gets richer every day. You never start from zero.

This is [Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) made operational — extended with [gbrain's](https://github.com/garrytan/gbrain) entity-first architecture and production lessons from [LLM Wiki v2](https://gist.github.com/rohitg00/2067ab416f7bbe447c1977edaaa681e2).

---

## The Vision

Most LLM setups are RAG: the model retrieves from scratch, answers, and forgets. Nothing compounds.

This is different. Your agent **builds and maintains a wiki** — structured, interlinked markdown files it reads before every response and updates after every conversation. Add a source and the agent integrates it into 5–15 existing pages, updating entity pages, noting contradictions, strengthening cross-references. Ask a question and the agent files the synthesis back. Over months, the wiki becomes a second brain that knows your world — your people, your projects, your thinking.

**The key insight from Karpathy:** stop re-deriving. Start compiling. Pre-computed synthesis beats retrieval every time.

**What this repo adds:** an entity layer, schema conventions that make pages smarter over time, and a headless sync daemon so it runs continuously on a server without a GUI.

---

## The Stack

| Layer | Tool | Why |
|---|---|---|
| **Agent** | [OpenClaw](https://openclaw.ai) | Always-on daemon, reads/writes wiki continuously |
| **Wiki IDE** | [Obsidian](https://obsidian.md) | Graph view, backlinks, browse on any device |
| **Headless sync** | [obsidian-headless](https://github.com/obsidianmd/obsidian-headless) | Keeps vault synced on a server without a GUI |
| **Schema** | This repo | What makes the wiki compound instead of just grow |

No database. No embeddings required to start. Just markdown files, a schema, and an agent that follows it.

---

## Architecture

```
~/Vault/
  WIKI-SCHEMA.md              ← The rules. Agent reads this first.
  brain/                      ← Entity layer (one page per person, company, project)
    RESOLVER.md               ← Filing decision tree
    people/
    companies/
    projects/
    ideas/
    concepts/
    meetings/
    inbox/
    archive/
  wiki/
    index.md                  ← Master catalog, updated on every ingest
    log.md                    ← Append-only record of all activity
    entities/                 ← Named entities from research and synthesis
    topics/                   ← Cross-domain synthesis pages
    sources/                  ← One summary per ingested source
  originals/                  ← Your thinking, not what you found
  references/                 ← Raw source documents (immutable)
  inbox/                      ← Unprocessed captures

~/.config/systemd/user/
  obsidian-sync.service       ← Continuous sync daemon
```

---

## How It Works

Every conversation passes through this loop:

```
Signal arrives (message, source, meeting, question)
  ↓
Entity detection — who and what is this about?
  ↓
Brain-first lookup — check brain/ before answering
  ↓
Respond with full context
  ↓
Update brain pages with new information
  ↓
Sync — changes propagate to all devices
```

Each pass through the loop adds knowledge. After a meeting, the agent enriches the attendees' brain pages. Next time those people come up, the agent already has context. The difference compounds daily.

---

## Two Layers, One Vault

### The brain layer (`brain/`)

One page per entity — every person, company, and project that matters to you. The agent checks here before answering anything about a known entity.

Every brain page has two layers, separated by `---`:

```markdown
# [Name]

> One-line who this is and why they matter.

## State
Current facts. Always rewritten when new information arrives.

## Open Threads
Active items. Removed when resolved (moved to Timeline below).

---

## Timeline
- YYYY-MM-DD | Source — what happened (append-only, never edited)
```

**Above the line:** always current. If you read only this, you know the state of play.  
**Below the line:** the evidence log. Append-only. When an open thread resolves, it moves here with its resolution.

The synthesis is pre-computed. Unlike RAG, your agent doesn't re-derive context from scratch — the cross-references are already there.

### The RESOLVER

Before creating any brain page, the agent reads `brain/RESOLVER.md` — a decision tree that answers exactly one question: *where does this piece of knowledge belong?*

```
Person?                    → people/
Company or product?        → companies/
Actively being built?      → projects/
Just an idea?              → ideas/
Mental model or framework? → concepts/
A meeting?                 → meetings/
Doesn't fit?               → inbox/
```

One page per entity. One home per entity. No duplicates. The resolver prevents the failure mode that kills most knowledge bases: the same fact living in three places with three different versions.

### The wiki layer (`wiki/`)

For research, synthesis, and competitive intelligence — knowledge that spans entities and compounds from sources you ingest. Follows the Karpathy pattern strictly: index, log, entity pages, topic pages, source summaries.

---

## Schema Conventions

These conventions are baked into `WIKI-SCHEMA.md`. They make pages smarter over time.

### Confidence

Every significant claim carries context:

```markdown
- Uses Redis for caching (source: [[Redis Migration 2025-03]], last confirmed: 2025-11)
```

When you update a claim, note the date. Old unconfirmed claims decay — they don't disappear, but you know to treat them with appropriate skepticism.

### Supersession

When a claim changes, preserve the old version:

```markdown
- Auth uses JWT tokens (supersedes: [[Auth Decision 2024-03]] which used sessions)
```

The old page is preserved but marked stale. You get a full history of what you believed and when you changed your mind.

### Typed relationships

Not all connections are equal:

```markdown
## Relationships
- [[Redis]] — uses (caching layer)
- [[Postgres Migration 2025]] — caused (capacity issues triggered it)
- [[Legacy Session Auth]] — supersedes
```

Relationship types: `uses`, `depends-on`, `caused`, `fixed`, `supersedes`, `contradicts`, `inspired-by`.

### Originals

A place for your own thinking — separate from ingested sources:

```
originals/
  [date]-[slug].md
```

Format: what you think, why, what would change your mind. The goal is to capture the thinking that doesn't come from anywhere else. This is the layer most knowledge bases miss.

---

## Quick Install (headless Linux)

```bash
# Full install — everything from scratch
bash <(curl -fsSL https://raw.githubusercontent.com/joshuaboys/llm-wiki-stack/main/scripts/install.sh)

# Already have a vault? Just add headless sync
bash <(curl -fsSL https://raw.githubusercontent.com/joshuaboys/llm-wiki-stack/main/scripts/install-sync.sh)
```

**Prerequisites:** Ubuntu/Debian, Node.js ≥ 20, Obsidian Sync subscription, OpenClaw running.

---

## Configuration

Copy `schema/WIKI-SCHEMA.md` into your vault as `WIKI-SCHEMA.md`. Tell your agent:

> "Read WIKI-SCHEMA.md before any wiki work. Brain-first lookup on every entity. Update pages immediately when you learn something new."

That's it. Your agent will build the rest.

---

## Going Further: Automated Enrichment

The setup above requires you to prompt the agent to ingest sources. The next level is automatic enrichment — every email, calendar event, meeting, and social signal automatically touches the relevant brain pages without you having to ask.

[gbrain](https://github.com/garrytan/gbrain) implements the full production version of this: integrations for email, calendar, voice calls, and Twitter; a nightly dream cycle that sweeps entities, fixes citations, and consolidates memory; 20+ cron jobs running continuously.

If you want to build the enrichment pipeline yourself, [PocketFlow](https://github.com/The-Pocket/PocketFlow) provides the primitives — 100 lines, zero dependencies. The cookbook patterns map directly to enrichment tasks:

| What you want | PocketFlow pattern |
|---|---|
| Session memory (sliding window + retrieval) | [Chat Memory](https://github.com/The-Pocket/PocketFlow/tree/main/cookbook/pocketflow-chat-memory) |
| Deep research with iterative refinement | [Deep Research](https://github.com/The-Pocket/PocketFlow/tree/main/cookbook/pocketflow-deep-research) |
| Always-on monitoring with nested flows | [Heartbeat](https://github.com/The-Pocket/PocketFlow/tree/main/cookbook/pocketflow-heartbeat) |
| Batch entity enrichment with speedup | [Parallel](https://github.com/The-Pocket/PocketFlow/tree/main/cookbook/pocketflow-parallel-batch) |
| Reliability via supervision | [Supervisor](https://github.com/The-Pocket/PocketFlow/tree/main/cookbook/pocketflow-supervisor) |

---

## Acknowledgements

Built on the shoulders of:

- **[Andrej Karpathy](https://github.com/karpathy)** — the original [LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). The core insight: stop re-deriving, start compiling.
- **[Garry Tan](https://github.com/garrytan)** — [gbrain](https://github.com/garrytan/gbrain). The entity-first architecture, MECE directories, RESOLVER pattern, compiled truth + timeline, and the operational brain concept that extends Karpathy's research wiki into a full personal intelligence system.
- **LLM Wiki v2** ([rohitg00](https://gist.github.com/rohitg00/2067ab416f7bbe447c1977edaaa681e2)) — production lessons: confidence scoring, supersession, forgetting curves, and typed relationships.

---

## License

MIT
