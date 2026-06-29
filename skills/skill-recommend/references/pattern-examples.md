# Pattern Examples — Calibration

Labeled examples to help calibrate skill-recommend's pattern detection.
Each example shows the raw signal, the pattern type, score, and correct action.

Scoring formula (from SKILL.md):
`score = (repetitions × 3) + (friction_events × 2) + (complexity_flag × 1)`,
threshold to consider a mention is **4**.

---

## SHOULD trigger a suggestion

### Example 1 — Repetition (score: 9)
**Signal:** User pastes this block three times in one session:
> "Extract all tables from the PDF, convert to CSV, keep the headers, skip blank rows."

**Pattern type:** repetition
**Keywords:** pdf, extract, tables, csv
**Score:** 3 repetitions × 3 = 9
**Action:** Suggest `pdf` (ships in the `document-skills` plugin). Offer the install command.

---

### Example 2 — Friction (score: 4)
**Signal:** Claude generates a Word document. User says "no, use proper heading styles".
Claude fixes it. Later, Claude generates another document. User says "again, use heading styles".

**Pattern type:** friction (same correction twice)
**Keywords:** docx, headings, styles, word
**Score:** 2 friction events × 2 = 4 — exactly at threshold
**Action:** Suggest `docx` (ships in the `document-skills` plugin).

---

### Example 3 — One-off complexity (score: 1 — below threshold)
**Signal:** User says "set up a new React component with tests, storybook entry, and types".
Claude uses 6 tools across 8 steps. It happens once.

**Pattern type:** complexity
**Keywords:** react, component, tests, storybook, typescript
**Score:** complexity flag (1) = 1 — no repetition, so it stays under the threshold
**Action:** Do not suggest. A single complex task is not a pattern. If the user sets up
components like this repeatedly, the repetition term carries the score over 4 — only then
search the registry for a frontend/React skill.

---

### Example 4 — Cross-session standing pattern
**Signal:** `patterns.json` shows the user has asked Claude to summarize GitHub PRs
in 4 separate sessions over the past 2 weeks.

**Pattern type:** cross-session standing pattern (≥ 3 prior sessions)
**Keywords:** github, pr, summary, review
**Score:** n/a — a standing pattern (the same cluster in 3+ prior sessions) warrants one
mention on its own, regardless of this session's score.
**Action:** Suggest a registry match if one exists; otherwise consider `skill-creator`.

---

## Should NOT trigger a suggestion

### Example 5 — One-off complexity
**Signal:** User asks Claude to migrate a legacy PHP codebase to Node.js.
Task is complex (10+ tools, 20+ turns) but clearly a one-time project.

**Pattern type:** none
**Score:** 0 (no repetition, no friction, one-off framing)
**Action:** No suggestion. Log nothing.

---

### Example 6 — Exploratory session
**Signal:** User tries several different approaches to a data visualization,
asking Claude to redo it 4 times with different chart types.

**Pattern type:** none (exploration, not friction)
**Score:** 0 — user is deliberately iterating, not stuck
**Action:** No suggestion. The repetition is intentional.

---

### Example 7 — Already installed
**Signal:** User asks Claude to read a PDF. The `pdf` skill's plugin (`document-skills`)
is already installed under `~/.claude/plugins/`.

**Pattern type:** covered
**Action:** No suggestion. The skill already handles this. Silently verify it's active.

---

### Example 8 — Personal preference, not a workflow
**Signal:** User reminds Claude twice to "keep responses concise".

**Pattern type:** preference (not a workflow)
**Score:** 0 — this belongs in CLAUDE.md, not a skill
**Action:** Suggest adding to CLAUDE.md instead: "Want me to add 'keep responses concise'
to your CLAUDE.md so I remember this automatically?"
