# RESOLVER.md — Brain Filing Decision Tree

Walk this tree before creating any new brain page. Every piece of knowledge has exactly one home.

---

## Step 1: Is it about a specific person?

**Yes → `people/`**
- One page per human being
- Includes Josh's family, colleagues, advisors, investors, competitors, founders
- If they're also relevant to a company, their company gets a `companies/` page — but their *primary* home is `people/`

---

## Step 2: Is it about an organisation, product, or institution?

**Yes → `companies/`**
- Includes: companies (Arkahna, EddaCraft, competitors), products (Anvil, AGT), VC funds, institutions
- NOT for a project Josh is actively running — that goes in `projects/`

---

## Step 3: Is it something being actively built with a repo, spec, or team?

**Yes → `projects/`**
- Includes: Anvil, ark-data, anvil-agent-protocol, openclaw-workspace, get-started-with-openclaw
- Must have active work happening — if it's just an idea, use `ideas/`
- When a project ends or is shelved → move to `archive/`

---

## Step 4: Is it a raw possibility nobody is building yet?

**Yes → `ideas/`**
- Could become a project later — the graduation moment is when work actually starts
- dev-guardrails, kindling, any future product directions go here until they have a repo

---

## Step 5: Is it a mental model, framework, or concept you could teach?

**Yes → `concepts/`**
- Things like: APS planning, agent-kernel pattern, Ascension Protocol, BaC, MECE reasoning
- If it's a draft essay or doc → `writing/` (not yet, add directory when needed)

---

## Step 6: Is it a processed meeting record?

**Yes → `meetings/`**
- One page per meeting Josh shares or describes
- Always links to all attendees' `people/` pages

---

## Step 7: Doesn't fit anything above?

**→ `inbox/`**
Capture it there and flag for filing. That's a signal the schema needs to evolve.

---

## Key disambiguation rules

- **Person vs company:** Is it about the *human*? → `people/`. Is it about the *org*? → `companies/`. Both pages cross-link.
- **Project vs idea:** Is anyone actively working on it (has a repo/spec/branch)? → `projects/`. Just a possibility? → `ideas/`.
- **Competitor vs concept:** A specific company (Qodo, AGT, Astrix)? → `companies/`. A market pattern or strategic frame? → `concepts/`.
- **One page per entity.** Never duplicate. If a page exists, update it.
