# When to Suggest a Custom Skill vs Installing One

Use this reference when a pattern is detected but no registry match scores above 0.4.

---

## Suggest installing a known skill when:

- The task type is generic and widely used (PDF handling, Word docs, code review)
- A registry match has high semantic overlap (≥ 0.5) with the detected pattern
- The matched skill is present in the current marketplace snapshot (an actively
  published official skill)
- The user's workflow is standard — no company-specific logic or unusual constraints

**Suggestion phrasing:** "There's an official skill for this."

---

## Suggest creating a custom skill when:

- The pattern involves domain-specific terminology (your stack, your team's conventions)
- The user has repeated the same system-level instructions 3+ times across sessions
- The workflow has a fixed sequence that Claude keeps having to re-learn
- No registry match scores above 0.4
- The user has already installed all plausible registry candidates

**Suggestion phrasing:** "This feels like something worth capturing as a skill.
Want me to help you create one?"

If the `skill-creator` skill is available, invoke it to walk through the process.
Otherwise mention how to get it: `/plugin install example-skills@anthropic-agent-skills`.

---

## Do not suggest creating a custom skill when:

- The pattern has only appeared once (score below the threshold of 4)
- The task is exploratory — the user is still figuring out what they want
- The user has dismissed a skill suggestion for the same pattern this session
- The workflow is inherently one-off (e.g., migrating a legacy codebase once)

---

## Escalation path

```
pattern detected
    │
    ├─ registry match ≥ 0.4  →  suggest install
    │
    ├─ registry match < 0.4
    │       │
    │       ├─ pattern fired 3+ sessions  →  suggest skill-creator
    │       │
    │       └─ pattern fired < 3 sessions →  log silently, wait
    │
    └─ skill already installed  →  log silently, consider CLAUDE.md entry instead
```

---

## Suggesting a CLAUDE.md entry (alternative)

If the pattern is a persistent preference rather than a workflow (e.g., "always use
TypeScript strict mode", "always respond in Spanish"), suggest adding it to `CLAUDE.md`
rather than creating a skill. Skills encode *procedures*; CLAUDE.md encodes *preferences*.
