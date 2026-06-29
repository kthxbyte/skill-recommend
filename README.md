# skill-recommend

> Helps you discover Claude skills you didn't know you needed — without ever getting in your way.

A lightweight, always-on skill for Claude Code. It quietly watches a session for
recurring patterns and, when it spots one that an official skill would genuinely
help with, drops a single end-of-response note: what the skill is, the plugin that
ships it, and the exact one-line command to install it.

No auto-installs. No interruptions. No follow-ups. At most one suggestion per session.

Built for the person who has never opened a skill marketplace — and never will.

---

## What it actually does

Most of the time, nothing. It stays silent until a pattern is unmistakable:

- You paste the same instructions more than once
- You correct Claude on the same thing twice
- A habit shows up across several sessions

Only then — and only when a strong match exists in Anthropic's official marketplace —
does it add a quiet aside at the **end** of a response (never mid-task):

> 💡 Side note: we've done this same PDF-tables-to-CSV extraction three times now.
> Anthropic's official `pdf` skill is built for exactly this. It ships in the
> `document-skills` plugin — if you want it:
>
> ```
> /plugin install document-skills@anthropic-agent-skills
> ```
>
> No rush — just there if it's useful.

You copy, paste, done. Or ignore it entirely — it won't bring it up again.

### Why it names the plugin

Official skills install by **plugin**, not one skill at a time. `pdf`, `docx`, `xlsx`,
and `pptx` all live inside the `document-skills` plugin; the design and authoring
skills live inside `example-skills`. skill-recommend gives you the command that
actually works — `/plugin install <plugin>@anthropic-agent-skills` — instead of a
bare skill name that wouldn't resolve.

It also never quotes star ratings or download counts. The marketplace publishes no
such numbers, so it doesn't invent them.

---

## When it stays quiet

Knowing when *not* to speak is the whole point. It will not nudge you when:

- **You're iterating on purpose** — trying five chart types in a row is exploration,
  not friction
- **A task is complex but one-off** — a single migration isn't a pattern worth a tool
- **The repeated thing is a preference, not a workflow** — "keep responses concise"
  belongs in your `CLAUDE.md`, so it offers to add it there instead of suggesting a skill
- **The matching skill's plugin is already installed**
- **No official skill is a strong match** — a weak suggestion is worse than none

---

## Install

```bash
# Via the Claude Code plugin system
/plugin marketplace add kthxbyte/skill-recommend
/plugin install skill-recommend@kthxbyte

# Or manually
git clone https://github.com/kthxbyte/skill-recommend ~/.claude/skills/skill-recommend
```

Then tell Claude to use it — add this to your `CLAUDE.md`:

```
Use the skill-recommend skill at the start of every session.
```

A bundled `SessionStart` hook caches Anthropic's official marketplace locally at
`~/.claude/skill-recommend/registry.json` (each skill mapped to the plugin that ships
it and its install command). The sync is gated: it makes a network call only when the
cache is missing or older than 7 days, and runs in the background so it never blocks
session startup. It installs nothing — it only caches metadata.

---

## Files

```
skill-recommend/
  hooks/
    hooks.json                          ← SessionStart hook that runs the registry sync
  skills/skill-recommend/
    SKILL.md                            ← core skill instructions
    scripts/
      sync-registry.sh                  ← caches the official marketplace (skill → plugin → install command)
    references/
      custom-skill-triggers.md          ← when to suggest installing vs. creating a skill
      pattern-examples.md               ← labeled pattern examples for calibration
```

---

## Token cost

| State | Cost |
|---|---|
| Idle (skill listed, not triggered) | ~80 tokens |
| Triggered (SKILL.md loaded) | ~1,600 tokens |
| Worst case (all reference files) | ~4,000 tokens |

Less than 1% of Claude's 200k context window in normal use.

---

## Validated behavior

This isn't just described behavior — it's tested. Across 16 simulated sessions, each
run as a fresh-context agent that wasn't told what was being measured:

- **Fires when it should** — 10/10 repetition and friction scenarios produced exactly
  one quiet, end-of-response nudge with the correct plugin-level install command.
- **Stays quiet when it should** — exploration, one-off tasks, and personal preferences
  produced **zero** skill suggestions (preferences were routed to `CLAUDE.md` instead).
- **Never fabricates popularity numbers** — 0 invented stats across all 12 firings.

These are scripted scenarios, not a guarantee for every real session — see
[TESTING.md](TESTING.md) for the full method, scenarios, results, and honest caveats.

---

## Compatibility

Built for Claude Code. The skill content itself follows the
[Agent Skills](https://agentskills.io) standard and should be portable to other agents
that support it (Cursor, GitHub Copilot, VS Code, Gemini CLI, and ~40 others).

**Platform: Linux / Unix-centric.** The registry sync (`scripts/sync-registry.sh`) and
the `SessionStart` hook assume a POSIX shell with `bash`, `curl`, `python3`, and a
Unix `date`. It runs on Linux and macOS. **It is unlikely to work on Windows** except
under WSL or Git Bash; native Windows support would require a separate sync
implementation. The skill's recommendations would still function without a synced
registry, but degraded — pattern detection works, matching does not.

---

## Author

Salvador Muñoz — [salvador.munoz@gmail.com](mailto:salvador.munoz@gmail.com)
GitHub: [@kthxbyte](https://github.com/kthxbyte)

---

## License

Apache 2.0 — see [LICENSE](LICENSE).
