# your assistant Wiki Schema

> This document governs how your assistant (the AI assistant) maintains the knowledge wiki in ~/Vault.
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
  projects/
    anvil/          — Anvil product wiki (primary)
    fealty/         — Fealty game design wiki
    openclaw/       — OpenClaw setup and tooling notes
  areas/
    business/       — Arkahna, EddaCraft business context
    personal/       — Personal context, goals
  references/       — Raw source documents (immutable — LLM reads, never modifies)
  inbox/            — Unprocessed items awaiting integration
  wiki/             — Cross-project synthesis pages (index, log, entity pages)
```

---

## Wiki Layer (~/Vault/wiki/)

The wiki layer is where your assistant writes. Structure:

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

## Entity Pages

One markdown file per named entity. Entities include:
- **People** — you, competitors' founders, analysts, advisors
- **Companies** — Arkahna, EddaCraft, Qodo, DAM Secure, Microsoft, etc.
- **Products** — Anvil, GitHub Copilot, Checkmarx, Credo AI, etc.
- **Concepts** — deterministic enforcement, early access, policy-as-code, etc.

### Entity page format
```markdown
# [Entity Name]

**Type:** person | company | product | concept
**Tags:** [relevant tags]
**Last updated:** YYYY-MM-DD

## Summary
One paragraph. What this entity is and why it matters.

## Key Facts
- Fact 1 (source: [[Source Title]])
- Fact 2 (source: [[Source Title]])

## Relationships
- [[Related Entity]] — how they relate
- [[Related Entity]] — how they relate

## Timeline
- YYYY-MM-DD: Event (source: [[Source Title]])

## Open Questions
- Question that needs a source to answer

## Contradictions
- Claim A (source X) vs Claim B (source Y) — unresolved
```

---

## Anvil Wiki (~/Vault/projects/anvil/)

The Anvil project wiki has additional structure:

### Core pages (always keep current)
- `Anvil Agent Context.md` — authoritative product context for agents (update on every major decision)
- `Competitive Landscape.md` — live competitor map (update on every market signal ingest)
- `Market Signals.md` — chronological funding, launches, analyst pieces
- `Positioning.md` — messaging decisions, axis choices, ICP
- `Benchmarks.md` — performance numbers with dates

### Update triggers
| Event | Pages to update |
|---|---|
| New competitor funding round | `Competitive Landscape.md`, `Market Signals.md`, entity page for company |
| New benchmark run | `Benchmarks.md`, `Anvil Agent Context.md` |
| Positioning decision made | `Positioning.md`, `GTM Hub.md` |
| New analyst piece | `Market Signals.md`, `Competitive Landscape.md` if relevant |
| Website copy change | `Positioning.md` (note the decision and rationale) |

---

## Ingest Workflow

When processing a new source:

1. **Read** the source fully
2. **Discuss** key takeaways with you if present (or infer if solo)
3. **Write** a summary page in `wiki/sources/`
4. **Update** relevant entity pages (create if missing)
5. **Update** relevant project pages using the update triggers above
6. **Update** `wiki/index.md` with new/modified pages
7. **Append** to `wiki/log.md`

A single source typically touches 5-15 pages. This is expected and correct.

---

## Query Workflow

When asked a question against the wiki:

1. **Read** `wiki/index.md` to find relevant pages
2. **Read** the relevant pages
3. **Synthesise** an answer with citations to source pages
4. **File** good answers back as a new page in `wiki/topics/` if they represent genuine synthesis
5. **Append** to `wiki/log.md`

Good answers that disappear into chat history are wasted. If it took real synthesis to produce, it belongs in the wiki.

---

## Fealty Wiki (~/Vault/projects/fealty/)

The Fealty wiki is smaller but follows the same pattern.

### Core pages
- `Fealty GDD v0.1.md` — authoritative design document (source of truth, do not modify — treat as raw source)
- `Systems Index.md` — living index of all systems with design status
- `Open Questions.md` — unresolved design questions, updated as discussions happen
- `Decisions.md` — design decisions made and rationale

### Update triggers
| Event | Pages to update |
|---|---|
| Design decision made | `Decisions.md`, relevant system page |
| Open question resolved | `Open Questions.md` (mark resolved + rationale) |
| New reference game analysed | entity page for the game, `Systems Index.md` if relevant |
| GDD section expanded | `Systems Index.md` |

---

## Lint Workflow

Run periodically (weekly or when wiki feels stale):

1. Check for orphan pages (no inbound links from any other page)
2. Check for contradictions between entity pages and source summaries
3. Check for entity pages that reference sources no longer in the raw collection
4. Check for important concepts mentioned but lacking their own page
5. Suggest new sources to investigate based on open questions
6. Append lint results to `wiki/log.md`

---

## What NOT to Do

- **Don't just create a new file and stop.** Every ingest must update related existing pages.
- **Don't leave good analysis in chat history.** File synthesis back into the wiki.
- **Don't modify raw sources.** `references/` and source documents are immutable.
- **Don't create stub pages with no content.** Either write the page or add it to the index as "needs page."
- **Don't overwrite contradictions — surface them.** The wiki's value is its honesty about what's uncertain.

---

## Maintenance Notes

- All pages use standard Obsidian wikilinks: `[[Page Name]]`
- Source citations use: `(source: [[Source Title]])`
- Dates use ISO format: YYYY-MM-DD
- The wiki is a git repo — changes are committed with meaningful messages
- Obsidian Sync propagates changes to all devices automatically

---

*Schema version: 1.0 — April 2026*
*Co-authored by you and your assistant*
*Evolve this document as we learn what works.*
