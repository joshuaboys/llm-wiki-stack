# WIKI-SCHEMA.md

> This document governs how your AI assistant maintains the knowledge wiki in ~/Vault.
> Read this at the start of every session involving research, competitive intel, or knowledge capture.
> The wiki is a compounding artifact — not a retrieval index.

---

## Core Principle

When adding new knowledge, **integrate** — don't just append. Every ingest should:
1. Update existing entity and concept pages
2. Note where new information contradicts or strengthens existing claims
3. Add cross-references from related pages
4. File good answers and analysis back into the wiki (not just chat history)

---

## Directory Structure

```
~/Vault/
  brain/                — Entity knowledge base (people, companies, projects)
  projects/             — Project-specific wikis (one subdirectory per project)
  areas/                — Ongoing areas of life and work
  references/           — Raw source documents (immutable — never modify)
  inbox/                — Unprocessed items awaiting integration
  wiki/                 — Cross-project synthesis pages
```

---

## Wiki Layer (~/Vault/wiki/)

```
wiki/
  index.md          — Master catalog of all wiki pages (updated on every ingest)
  log.md            — Append-only chronological record of ingests, queries, lints
  entities/         — One page per named entity (person, company, product, concept)
  topics/           — Synthesis pages on themes that span entities
  sources/          — One summary page per ingested source
```

### index.md format
```
## [Category]
- [[Page Title]] — one-line summary (source count: N)
```

### log.md format
```
## [YYYY-MM-DD] ingest | Source Title
## [YYYY-MM-DD] query | Question asked
## [YYYY-MM-DD] lint | Health check run
```

---

## Brain Layer (~/Vault/brain/)

One page per entity. Before answering anything about a person, company, or project — check the brain first.

- **Person mentioned?** → `brain/people/<firstname-lastname>.md`
- **Company or product?** → `brain/companies/<name>.md`
- **Active project?** → `brain/projects/<name>.md`
- **Creating a new page?** → Read `brain/RESOLVER.md` first

### Brain page format

```markdown
# [Name]

> One-line who/what this is and why it matters.

## State
Current facts — always rewritten when things change.

## Open Threads
Pending actions or follow-ups.

---

## Timeline
- YYYY-MM-DD | Source — event or note (append-only, never edit)
```

**Above the line:** always current — rewrite freely when new info arrives.
**Below the line:** append-only — never edit past entries, only add new ones.

---

## Entity Pages (wiki/entities/)

For named entities that come up in research and synthesis (broader than the brain layer):

```markdown
# [Entity Name]

**Type:** person | company | product | concept
**Last updated:** YYYY-MM-DD

## Summary
One paragraph. What this entity is and why it matters.

## Key Facts
- Fact (source: [[Source Title]])

## Relationships
- [[Related Entity]] — how they relate

## Timeline
- YYYY-MM-DD: Event (source: [[Source Title]])

## Open Questions
- Question that needs a source to answer

## Contradictions
- Claim A (source X) vs Claim B (source Y) — unresolved
```

---

## Project Wikis (projects/)

Each active project gets a subdirectory. Minimum pages:

- `[Project].md` — current state, key decisions, open risks
- `Competitive Landscape.md` — if relevant
- `Market Signals.md` — funding, launches, analyst pieces (if relevant)

### Update triggers (adapt to your projects)

| Event | Pages to update |
|---|---|
| Major decision made | Project main page + relevant entity pages |
| New competitor signal | Competitive Landscape, Market Signals, entity page |
| Positioning change | Project main page |
| New source ingested | wiki/sources/, relevant entity pages, index |

---

## Ingest Workflow

1. **Read** the source fully
2. **Write** a summary page in `wiki/sources/`
3. **Update** relevant entity pages (create if missing)
4. **Update** relevant project pages
5. **Update** `wiki/index.md`
6. **Append** to `wiki/log.md`

A single source typically touches 5–15 pages. This is expected and correct.

---

## Query Workflow

1. Read `wiki/index.md` to find relevant pages
2. Read the relevant pages
3. Synthesise an answer with citations: `(source: [[Source Title]])`
4. **File good synthesis back** as `wiki/topics/<topic>.md`
5. Append to `wiki/log.md`

Good answers that disappear into chat history are wasted.

---

## Lint Workflow

Run periodically or when the wiki feels stale:

1. Orphan pages (no inbound links)
2. Contradictions between entity pages and source summaries
3. Important concepts mentioned but lacking their own page
4. Missing cross-references
5. Suggest new sources based on open questions

Append results to `wiki/log.md`.

---

## Rules

- **Don't just create one file and stop.** Every ingest updates related existing pages.
- **Don't leave good analysis in chat.** File synthesis back into the wiki.
- **Don't modify raw sources.** `references/` is immutable.
- **Don't create stub pages.** Either write the page or mark it as "needs page" in the index.
- **Don't overwrite contradictions.** Surface them — the wiki's value is its honesty.

---

## Maintenance Notes

- All pages use Obsidian wikilinks: `[[Page Name]]`
- Source citations: `(source: [[Source Title]])`
- Dates: ISO format `YYYY-MM-DD`
- Obsidian Sync propagates changes to all devices automatically

---

*Adapt this schema to your domains. The more specific the update triggers, the better the compounding.*
