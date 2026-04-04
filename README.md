# LLM Wiki Stack

A production implementation of [Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — a compounding personal knowledge base maintained by an AI assistant running continuously on a headless Linux server.

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
| **Personal memory** | [obsidian-mind](https://github.com/breferrari/obsidian-mind) | 1:1s, decisions, brag doc, people |
| **Domain knowledge** | [ByteRover](https://github.com/campfirein/byterover-cli) | Structured hierarchical knowledge (context tree) |
| **Wiki layer** | This repo's schema | Compounding cross-domain synthesis |

### Why three memory layers?

Each layer does something different:

- **ByteRover** — structured project/domain knowledge. Hierarchical context tree with importance scoring and recency decay. What the LLM *knows* about your projects.
- **obsidian-mind** — personal work memory. 1:1s, decisions, brag doc, people notes. What happened *to you* at work.
- **Wiki layer (Karpathy pattern)** — cross-domain synthesis. Competitor analysis, market signals, research. Knowledge that *compounds* from sources you ingest.

They don't overlap. Together they give the assistant persistent, queryable memory that survives session restarts and compounds over time.

---

## Architecture

```
~/Vault/                          ← Obsidian vault (synced via obsidian-headless)
  MORGAN-WIKI-SCHEMA.md           ← Governs how the LLM maintains the wiki
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
  obsidian-sync-mind.service      ← Continuous obsidian-mind sync daemon
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

# Create a remote vault (or connect to existing)
ob sync-create-remote --name "Vault" --encryption e2ee

# Set up sync (will prompt for E2E password)
ob sync-setup --vault "Vault" --path ~/Vault --device-name "$(hostname)"

# Initial sync
ob sync --path ~/Vault
```

### 3. Install the sync daemon

```bash
cp llm-wiki-stack/systemd/obsidian-sync.service ~/.config/systemd/user/

# Edit the service file to point to your node binary and vault path
nano ~/.config/systemd/user/obsidian-sync.service

systemctl --user daemon-reload
systemctl --user enable obsidian-sync.service
systemctl --user start obsidian-sync.service
systemctl --user is-active obsidian-sync.service
```

### 4. Install obsidian-mind (optional but recommended)

```bash
git clone https://github.com/breferrari/obsidian-mind.git ~/Vault-mind

# Set up a second remote vault for personal memory
ob sync-create-remote --name "Mind" --encryption e2ee
ob sync-setup --vault "Mind" --path ~/Vault-mind --device-name "$(hostname)"

# Copy the mind sync service
cp llm-wiki-stack/systemd/obsidian-sync-mind.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable obsidian-sync-mind.service
systemctl --user start obsidian-sync-mind.service
```

### 5. Install ByteRover (optional but recommended)

```bash
npm install -g byterover-cli

# Connect your LLM provider
brv providers connect openai --api-key YOUR_KEY
# or: brv providers connect anthropic --api-key YOUR_KEY

# Create a context directory per project
mkdir -p ~/brv-context && cd ~/brv-context
brv status
```

### 6. Configure your assistant

Copy `schema/WIKI-SCHEMA.md` into your vault as `MORGAN-WIKI-SCHEMA.md` (or whatever you name your assistant) and adapt it to your domains and projects. This is the most important step — it's what makes the LLM a disciplined wiki maintainer rather than a generic chatbot.

Tell your assistant to read the schema at the start of every research session.

---

## The Schema

The schema (`schema/WIKI-SCHEMA.md`) is the configuration file that governs how the LLM maintains the wiki. It defines:

- Directory structure conventions
- Entity page format
- Ingest workflow (what to update when a source is added)
- Query workflow (file good answers back into the wiki)
- Lint workflow (periodic health checks)
- Project-specific update triggers

**The key insight from Karpathy:** without a schema, the LLM is just a chatbot that happens to write files. With a schema, it becomes a disciplined wiki maintainer. Adapt the schema to your domains — the more specific it is, the better the compounding.

---

## Usage

### Ingest a source

```
"Ingest this article: [URL or paste content]"
```

The LLM will: read the source → discuss key takeaways → write a summary page → update entity pages → update project pages → update the index → append to the log.

### Query the wiki

```
"What do we know about [topic]?"
"Summarise the competitive landscape for [product]"
"What decisions have we made about [thing]?"
```

Good answers get filed back as topic pages, not lost in chat history.

### Run a lint

```
"Run a wiki lint"
```

Checks for orphans, contradictions, stale content, and missing cross-references.

---

## Credits

- [Andrej Karpathy](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — the LLM Wiki pattern
- [obsidian-mind](https://github.com/breferrari/obsidian-mind) — personal memory vault template
- [ByteRover](https://github.com/campfirein/byterover-cli) — agent-native memory architecture ([paper](https://arxiv.org/abs/2604.01599))
- [obsidian-headless](https://github.com/obsidianmd/obsidian-headless) — headless sync daemon
- [OpenClaw](https://openclaw.ai) — the always-on assistant layer

---

## License

MIT
