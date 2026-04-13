---
name: wiki-debate
description: Resolves contradictions in brain or wiki pages. When a brain page has conflicting claims in its Contradictions section, or when two entity pages disagree on the same fact, run this skill to debate the claims and write a verdict back to the page. Use when asked to "resolve contradictions", "clean up the wiki", or "settle a dispute" on an entity page.
---

# Wiki Debate Skill

Resolve contradictions in brain/wiki pages using adversarial debate.

## When to use

- A brain page has items in its `## Contradictions` section
- Two entity pages disagree on the same fact
- A claim in State contradicts an entry in Timeline
- You're asked to "settle" or "resolve" a disputed fact

## Process

### 1. Extract the contradiction

Read the page. Identify the two conflicting claims:
- Claim A: what it says, source, date
- Claim B: what it says, source, date

### 2. Run the debate internally

**Advocate for Claim A:**
- What evidence supports it?
- How recent is it?
- How authoritative is the source?

**Advocate for Claim B:**
- Same questions

**Judge:**
Score each claim (1-10) on:
- Recency (newer = more likely current)
- Source authority (primary source > secondary)
- Corroboration (how many sources agree?)

### 3. Write the verdict back

**Winner:** rewrite the State section with the winning claim.

**Loser:** move to Timeline with supersession note:

```markdown
- YYYY-MM-DD | Superseded — [winning claim]. Previous claim: [losing claim] (source: [[X]])
```

**Update the Contradictions section:** remove the resolved item. If it's now empty, remove the section entirely.

**Append to wiki/log.md:**
```
## YYYY-MM-DD | debate | [Entity Name] — [one sentence describing what was resolved]
```

## Example

**Before:**
```markdown
## Contradictions
- Entire raised $60M seed (source: [[TechCrunch Apr 2026]]) vs $50M (source: [[Crunchbase Mar 2026]])
```

**After debate:**
- TechCrunch Apr 2026 is more recent and primary source → winner
- State updated to $60M
- Timeline entry: `2026-04-13 | Superseded — $60M confirmed (TechCrunch). Previous claim: $50M (Crunchbase Mar 2026)`
- Contradictions section removed

## Rules

- Never delete a losing claim — move it to Timeline with its source preserved
- If genuinely unable to determine a winner (equal evidence, equal recency): keep both in Contradictions with a note explaining why it's unresolvable, and add an Open Question
- Always append to wiki/log.md
