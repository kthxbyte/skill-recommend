# Testing skill-recommend

skill-recommend makes two promises that are easy to claim and hard to trust:

1. It **speaks up** when an official skill would genuinely help.
2. It **stays quiet** the rest of the time — no nagging, no false alarms, no invented stats.

Because the whole value is *good judgment about when to talk*, the skill was validated
behaviorally rather than by assertion, following the subagent pressure-testing approach
from the `superpowers:writing-skills` methodology.

---

## Method

Each test is one **fresh-context agent** given:

- the live skill files (`SKILL.md` + both reference files) as active instructions, and
- a realistic multi-turn session transcript that ends just before the agent must respond.

The agent then writes the next message it would send the user. Crucially, agents were
**not told what was being measured** — so the behavior is unbiased by the test itself.
Each transcript is engineered to *tempt* a specific outcome (over-trigger, miss, or
fabricate), and we read every response by hand rather than pattern-matching for keywords.

Two rounds were run:

- **Round 1 — coverage:** one run of each of six scenarios (the firing cases, the
  suppression cases, and a no-skill control).
- **Round 2 — reliability:** the two firing scenarios repeated 5× each, to measure
  whether the *wording and mechanics* are stable or just lucky on a single sample. Low
  variance across reps is the signal that the guidance is actually binding.

Total: **16 runs.**

---

## Scenarios & results

### Should fire

| Scenario | Setup | Expected | Result |
|---|---|---|---|
| **Repetition** | Same PDF table→CSV instructions pasted 3× | One nudge for `pdf`, correct command | ✅ 5/5 reps fired correctly |
| **Friction** | Same "use real heading styles, not bold" correction 2× | One nudge for `docx`, correct command | ✅ 5/5 reps fired correctly |

Every one of the 12 firings (2 in round 1 + 10 in round 2):

- placed the note at the **end** of the response, never mid-task;
- gave the **plugin-level** install command `/plugin install document-skills@anthropic-agent-skills`
  (never an invalid bare-skill command like `pdf@…`);
- cited **no** star ratings or download counts;
- converged on the same shape — `💡 Side note → one observation → exact install command → low-pressure closer`.

### Should stay quiet

| Scenario | Setup | Expected | Result |
|---|---|---|---|
| **Exploration** | User iterates a chart through 4 different types | No suggestion (intentional iteration) | ✅ Stayed silent |
| **One-off complexity** | A single, many-step legacy migration | No suggestion (not a pattern) | ✅ Stayed silent |
| **Preference, not workflow** | "Keep responses concise" asked twice | Offer a `CLAUDE.md` entry, not a skill | ✅ Offered `CLAUDE.md`, no skill suggested |

### Control (no skill)

The repetition scenario was also run **without** the skill loaded. Baseline Claude *did*
mention a `pdf` skill on the third repeat — but vaguely, with **no install command and no
plugin name** ("want me to point you to it?").

This is the most honest finding in the whole exercise: the instinct to mention a skill
already exists. What skill-recommend actually adds is **correct, actionable mechanics and
restraint** — the exact working install command, one suggestion per session, end-of-response
only, no fabricated numbers, and correct *suppression* in the ambiguous cases above.

---

## Summary

| Property | Result |
|---|---|
| Fires on real patterns | 12/12 |
| Correct plugin-level install command | 12/12 |
| Fabricated popularity numbers | 0/12 |
| False fires on suppression scenarios | 0/3 |
| Preference correctly routed to CLAUDE.md | 1/1 |
| Wording variance across reps | Low (converged) |

---

## Honest caveats

- **Simulated, not live.** These are scripted transcripts run by subagents, not a
  guarantee of behavior in every real session. They demonstrate the skill's guidance is
  sound and reliable on the cases tested — not that it is infallible.
- **Priming.** Agents were instructed to treat the skill as active. This tests the skill's
  *content* (does it produce the right behavior when loaded?), not its activation.
- **Limited suppression controls.** The "stay quiet" scenarios were run with the skill
  active; a baseline Claude would likely also stay silent on pure exploration. So those
  runs prove the skill **does not induce** over-triggering — not that the skill alone is
  responsible for the silence.
- **Coverage, not exhaustiveness.** Five scenario types were tested. Real sessions contain
  patterns these don't cover; the calibration in `references/pattern-examples.md` is the
  living source of truth and is where new edge cases should be added.

Reproducing or extending these tests is straightforward: load the skill files into a
fresh agent, hand it one of the transcripts above (or a new one), and read what it does.
