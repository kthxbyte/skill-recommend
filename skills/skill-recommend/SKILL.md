---
name: skill-recommend
description: >
  Silently watches your session for recurring workflows and repeated friction, then
  gently mentions a relevant skill from the Anthropic official marketplace if one exists.
  Activate at the start of a Claude Code session. Triggers when the user repeats the
  same instructions, pastes similar boilerplate more than once, or corrects Claude on
  the same issue twice. Never interrupts, never installs anything, never suggests more
  than once per pattern per session. Just a quiet nudge at the right moment.
---

# skill-recommend

A lightweight, always-on skill that notices recurring patterns in your session and
occasionally mentions a skill that might help — along with how popular it is and
how to install it if you want to.

That's it. No installs, no interruptions, no pressure.

## Core Principle

A good recommendation feels like a colleague noticing something, not software selling
something. This skill says "hey, there's a tool for that" at the right moment, then
gets out of the way.

---

## Activation

Load at session start. Runs silently — no output unless a clear pattern has been
detected and a relevant skill exists. The user should never feel observed; they
should occasionally feel like Claude is paying attention.

---

## What to Notice

Watch for signals that suggest a task would be easier with an existing skill:

### Repetition signals
- User pastes the same block of instructions or boilerplate 2+ times
- User says "like before", "same as last time", "again", "as usual"
- Claude performs the same multi-step sequence it already performed this session

### Friction signals
- User corrects Claude on the same type of mistake twice in one session
- A task takes more than 5 back-and-forth turns to complete
- User expresses frustration: "no", "that's not what I meant", "again"

### Complexity signals
- A single task requires Claude to use 4+ tools in sequence
- The user describes something as simple but the setup takes many steps

These are signals, not triggers. A signal means pay attention. It does not mean
say something yet.

---

## Pattern Scoring

Score a pattern before deciding whether to say anything:

```
score = (repetitions × 3) + (friction_events × 2) + (complexity_flag × 1)
```

- **Score < 4**: Log quietly, say nothing
- **Score ≥ 4**: You may mention it once, briefly, at a natural pause — end of a
  response only. A higher score means more confidence the pattern is real, not a
  louder nudge: the mention stays the same quiet one-liner regardless of score.

One mention per pattern. One pattern per session. Never mid-task.

The score tells you when a pattern is real. Your judgment tells you whether it is
the right moment to mention it. When in doubt, wait.

### Cross-session patterns

`patterns.json` persists across sessions. If the same keyword cluster appears in
3+ prior sessions, treat it as a standing pattern: it is worth one mention on its
own, independent of this session's score. The same limits apply — one mention per
session, end of a response only.

---

## Registry Lookup

When score ≥ 4, check the local registry before saying anything.

### Local registry location

```
~/.claude/skill-recommend/
  ├── registry.json     ← cached skill metadata from Anthropic official marketplace
  ├── patterns.json     ← detected patterns across sessions (append-only log)
  └── last-sync.txt     ← ISO timestamp of last registry sync
```

### Registry sync

The registry is synced **automatically** by a bundled `SessionStart` hook
(`hooks/hooks.json` → `scripts/sync-registry.sh`), which refreshes the cache when
`last-sync.txt` is older than 7 days or missing. You do not normally run the sync
yourself — just read `registry.json`.

Fallback: if `registry.json` is missing when you need it (e.g. the hook hasn't run
in this environment), run `scripts/sync-registry.sh` once, then read the result.

Cache metadata only — skill name, parent plugin, description, keywords, install
command. Never cache full SKILL.md content; fetch on demand if needed.

Note: official skills are installed by **plugin**, not individually (e.g. `pdf`,
`docx`, `xlsx`, and `pptx` all ship in the `document-skills` plugin). Every registry
entry therefore carries its parent plugin and the corresponding install command.

### Matching

1. Extract 3–5 keywords from the repeated task or friction point
2. Search `registry.json` for skills whose description or keywords overlap
3. Rank candidates by semantic/keyword overlap with the pattern
4. Consider only the top match — do not surface multiple options at once

If the top match scores below 0.4 overlap, log the pattern silently and say nothing.
A weak match is worse than no mention at all.

The official marketplace exposes no per-skill popularity data (no stars, no install
counts). Do not rank by, cite, or invent popularity numbers.

---

## How to Mention a Skill

When score ≥ 4 and a strong registry match exists, add a brief note at the end
of a response — never in the middle of one, never as a standalone message.

### Tone

Casual. Informative. One observation, one recommendation, one install command.
State what the skill does and which plugin ships it. No pressure — let the user decide.

### Format

```
💡 Side note: we've extracted tables from a PDF a few times now. Anthropic's
official `pdf` skill is built for exactly this. It ships in the `document-skills`
plugin — if you want it:

    /plugin install document-skills@anthropic-agent-skills

No rush — just there if it's useful.
```

### Rules

- End of response only, never mid-task
- One suggestion per session maximum
- Never suggest a skill whose plugin is already installed (check `~/.claude/plugins/`)
- Always give the exact install command — official skills install by plugin, so it is
  `/plugin install <plugin>@anthropic-agent-skills`, not the skill name alone
- Never cite or invent popularity numbers — the marketplace exposes none
- Never frame it as urgent, necessary, or strongly recommended
- Never follow up on a suggestion that was ignored

---

## Pattern Logging

Append every detected pattern to `~/.claude/skill-recommend/patterns.json`,
whether or not a suggestion was made.

```json
{
  "timestamp": "2026-06-29T10:42:00Z",
  "session_id": "<hash>",
  "pattern_type": "repetition",
  "description": "User pasted PDF extraction instructions 3 times",
  "keywords": ["pdf", "extract", "tables"],
  "score": 9,
  "suggested": true,
  "registry_match": "pdf",
  "match_plugin": "document-skills",
  "user_response": "unknown"
}
```

`user_response` is filled when observable: "installed", "dismissed", "deferred",
or "unknown". Never infer intent — only log what was clearly expressed.

---

## What Not to Do

- Do not read or log the contents of private files — log task types only
- Do not log credentials, personal data, or file contents
- Do not suggest skills for one-off tasks, even complex ones
- Do not suggest more than once per session, regardless of how many patterns fire
- Do not interrupt a task in progress under any circumstances
- Do not follow up on a dismissed or ignored suggestion
- Do not install anything — ever
- Do not mention that you are watching — the observation is silent

---

## Reference Files

- `scripts/sync-registry.sh` — fetches and caches the Anthropic official skill registry
- `references/custom-skill-triggers.md` — when to suggest creating a skill vs installing one
- `references/pattern-examples.md` — labeled examples for calibrating gap detection
