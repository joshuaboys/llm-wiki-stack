# LLM Wiki Stack

A production implementation of [Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — a compounding personal knowledge base maintained by an AI assistant running continuously on a headless Linux server.

---

## Quick Install (headless Linux)

```bash
# Full install — everything from scratch
bash <(curl -fsSL https://raw.githubusercontent.com/joshuaboys/llm-wiki-stack/main/scripts/install.sh)

# Already have a vault? Just add headless sync
bash <(curl -fsSL https://raw.githubusercontent.com/joshuaboys/llm-wiki-stack/main/scripts/install-sync.sh)

# Just want ByteRover structured knowledge
bash <(curl -fsSL https://raw.githubusercontent.com/joshuaboys/llm-wiki-stack/main/scripts/install-byterover.sh)
```

> **Note:** `bash <(curl ...)` preserves your TTY for interactive prompts. Scripts also support fully non-interactive mode via env vars.

```bash
VAULT_PATH=~/Vault VAULT_NAME="My Vault" BRV_PROVIDER=openai BRV_API_KEY=sk-... \
  bash <(curl -fsSL .../install.sh)
```

---

## What This Is

Most LLM + knowledge setups are RAG: you upload files, the LLM retrieves chunks at query time, generates an answer, and forgets everything. Nothing compounds.

This stack is different. The LLM **builds and maintains a persistent wiki** — structured, interlinked markdown files that sit between you and your raw sources. When you add a source, the LLM reads it, extracts what matters, and integrates it into existing pages — updating entity pages, noting contradictions, strengthening cross-references. The wiki gets richer with every ingest. Good answers get filed back. Knowledge compounds.

---

## The Stack

| Layer | Tool | Purpose |
|---|---|---|
| **Assistant** | [OpenClaw](https://openclaw.ai) | Always-on AI assistant running as a daemon |
| **Wiki IDE** | [Obsidian](https://obsidian.md) | Browse, follow links, graph view |
| **Sync** | [obsidian-headless](https://github.com/obsidianmd/obsidian-headless) | Continuous sync daemon (no GUI required) |
| **Personal memory** | [obsidian-mind](https://github.com/breferrari/obsidian-mind) *or* LLM Wiki v2 pattern | Session context, decisions, people (see below) |
| **Entity layer** | Brain pattern (this repo) | Structured entity knowledge — people, companies, projects |
| **Domain knowledge** | [ByteRover](https://github.com/campfirein/byterover-cli) | Structured hierarchical knowledge (context tree) |
| **Wiki layer** | This repo's schema | Compounding cross-domain synthesis |

---

## Memory Layers — Pick Your Approach

### Option A: obsidian-mind

[obsidian-mind](https://github.com/breferrari/obsidian-mind) is a structured personal memory vault built for Claude Code. It handles 1:1s, decisions, brag doc, people notes, and performance tracking via slash commands and hooks.

Best for: teams, engineering managers, people who need structured work history and review prep.

### Option B: LLM Wiki v2 pattern

[LLM Wiki v2](https://gist.github.com/rohitg00/2067ab416f7bbe447c1977edaaa681e2) extends Karpathy's original pattern with lessons from running it in production:

- **Confidence scoring** — every fact carries a score (source count, recency, contradictions). Decays with time, strengthens with reinforcement.
- **Supersession** — when a claim is updated, the old version is preserved but marked stale, linked to the new one.
- **Forgetting curves** — architecture decisions decay slowly, transient facts decay fast. The wiki stays signal-rich.
- **Consolidation tiers** — working memory → episodic → semantic → procedural. Facts are promoted as evidence accumulates.
- **Typed relationships** — "A caused B" is more useful than "A relates to B". Cross-links carry semantic weight.

Best for: personal use, founders, researchers — anyone building a long-lived knowledge base that needs to stay relevant.

Both options work alongside the wiki layer and entity layer. They're not mutually exclusive.

---

## The Brain Pattern (Entity Layer)

The brain pattern gives your assistant a structured entity knowledge base — one page per person, company, or project that matters to you.

```
brain/
  RESOLVER.md        — Filing decision tree (where does this knowledge belong?)
  people/            — One page per person
  companies/         — Companies, products, institutions
  projects/          — Active projects with a repo or spec
  ideas/             — Raw possibilities not yet being built
  concepts/          — Mental models and frameworks
  meetings/          — Processed meeting notes
  inbox/             — Quick captures awaiting filing
  archive/           — Completed or shelved items
```

### How it works

Before answering anything about a person or project, the assistant checks the brain first — no search needed, just direct navigation. Pages use a two-layer format:

```markdown
# [Name]

> One-line who this is and why they matter.

## State
Current facts — always rewritten when things change.

---

## Timeline
- YYYY-MM-DD: Event (append-only — never edit, only add)
```

**Above the line:** always current — rewrite freely.  
**Below the line:** append-only — preserves the full history.

### RESOLVER.md

The resolver is a decision tree that answers: *where does this piece of knowledge belong?*

```
Is it about a specific person?          → people/
Is it about a company or product?       → companies/
Is it actively being built?             → projects/
Is it an idea with no active work?      → ideas/
Is it a mental model or framework?      → concepts/
Is it a meeting record?                 → meetings/
Doesn't fit?                            → inbox/
```

One page per entity. One home per entity. No duplicates.

The resolver is what makes the brain *navigable by the agent* — because the schema is known, the assistant goes straight to `brain/people/garry-tan.md` rather than searching everything.

---

## Architecture

```
~/Vault/
  WIKI-SCHEMA.md                 ← Governs how the LLM maintains the wiki
  brain/                         ← Entity knowledge base (brain pattern)
    RESOLVER.md
    people/
    companies/
    projects/
    ideas/
    concepts/
    meetings/
    inbox/
    archive/
  wiki/
    index.md                      ← Master catalog (updated on every ingest)
    log.md                        ← Append-only chronological record
    entities/                     ← One page per named entity
    topics/                       ← Cross-domain synthesis pages
    sources/                      ← One summary page per ingested source
  projects/                       ← Project-specific wikis
  references/                     ← Raw sources (immutable)
  inbox/                          ← Unprocessed items

~/.config/systemd/user/
  obsidian-sync.service           ← Continuous vault sync daemon
```

---

## Setup

### Prerequisites

- Ubuntu/Debian Linux (headless or desktop)
- Node.js >= 20
- An Obsidian account with Sync subscription
- OpenClaw installed and running

### 1. Install obsidian-headless

```bash
npm install -g obsidian-headless
ob login
```

### 2. Create and configure your vault

```bash
# Clone the vault template
git clone https://github.com/joshuaboys/llm-wiki-stack.git
cp -r llm-wiki-stack/vault-template ~/Vault

# Connect to existing Obsidian Sync vault (or create new)
ob sync-setup --vault "Vault" --path ~/Vault --device-name "$(hostname)"

# Initial sync
ob sync --path ~/Vault
```

### 3. Install the sync daemon

```bash
cp llm-wiki-stack/systemd/obsidian-sync.service ~/.config/systemd/user/

# Edit ExecStart paths to match your node binary and vault path
nano ~/.config/systemd/user/obsidian-sync.service

systemctl --user daemon-reload
systemctl --user enable --now obsidian-sync.service
systemctl --user is-active obsidian-sync.service
```

### 4. Choose your personal memory layer

**Option A — obsidian-mind:**
```bash
git clone https://github.com/breferrari/obsidian-mind.git ~/Vault-mind
ob sync-setup --vault "Mind" --path ~/Vault-mind --device-name "$(hostname)"

cp llm-wiki-stack/systemd/obsidian-sync-mind.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now obsidian-sync-mind.service
```

**Option B — LLM Wiki v2 pattern:**
Add a `brain/` directory to your vault using the brain pattern template in this repo:
```bash
cp -r llm-wiki-stack/vault-template/brain ~/Vault/brain
```
Then ask your assistant to seed it: *"Read my USER.md and create brain pages for the people and projects I mentioned."*

### 5. Install ByteRover (optional)

```bash
npm install -g byterover-cli
brv providers connect openai --api-key YOUR_KEY
```

### 6. Configure your assistant

Copy `schema/WIKI-SCHEMA.md` into your vault and adapt it to your domains. This is the most important step — it's what makes the assistant a disciplined wiki maintainer.

---

## Usage

### Ingest a source

```
"Ingest this article: [URL or paste content]"
```

The LLM reads the source → writes a summary page → updates entity pages → updates the index → appends to the log. A single source typically touches 5–15 pages.

### Query the wiki

```
"What do we know about [topic]?"
```

The LLM reads the index → reads relevant pages → synthesises an answer → files good synthesis back as a `topics/` page.

### Lint

```
"Run a wiki lint"
```

Checks for orphan pages, contradictions, stale claims, missing cross-references.

---

## Going Further

- [LLM Wiki v2](https://gist.github.com/rohitg00/2067ab416f7bbe447c1977edaaa681e2) — confidence scoring, supersession, forgetting curves, typed relationships, hybrid search
- [ByteRover paper](https://arxiv.org/abs/2604.01599) — hierarchical context trees with adaptive knowledge lifecycle
- [obsidian-mind](https://github.com/breferrari/obsidian-mind) — session context and performance tracking for Claude Code

---

## Acknowledgements

Built on the shoulders of:

- **[Andrej Karpathy](https://github.com/karpathy)** — the original [LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). Stop re-deriving, start compiling.
- **[Garry Tan](https://github.com/garrytan)** — [gbrain](https://github.com/garrytan/gbrain), the entity-first approach to agent memory that inspired the brain pattern and RESOLVER concept in this repo.

---

## License

MIT
