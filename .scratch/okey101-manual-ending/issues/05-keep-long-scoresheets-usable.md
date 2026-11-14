# 05 — Keep long Scoresheets readable and responsive

**What to build:** Tables can inspect and continue an Okey 101 history beyond 100 Rounds without losing column context, breaking Round labels or waiting on repeated history calculations. Open-ended play stays practical without adding a new count limit.

**Blocked by:** [02 — Start and score target-free Okey 101 Matches](02-start-and-score-target-free-matches.md).

**Status:** complete

- [x] Exercise a history beyond the old 50-Round maximum and a representative history of at least 104 Rounds. Scoresheet deltas and totals match the engine, all saved Rounds remain accessible, and ordering follows Round sequence.
- [x] Three-digit Round numbers fit without clipping, overlap or stealing readable player-score columns at compact phone widths. “Total” remains on one line and four-digit sample totals remain legible.
- [x] Keep player-column names visible while scrolling long history, following the approved reviewed mockup. Preserve correct alignment between names, per-Round scores and totals.
- [x] Scoring another Round and Undo update history and totals correctly, including zero-Round recovery, existing modifiers and stored events. Do not widen raw score-entry bounds, introduce late Okey 101 Joins or add a replacement Match cap.
- [x] Check responsiveness with the representative long history. Avoid repeatedly replaying every prefix or eagerly constructing the entire offscreen history when it causes a material problem; make any calculation/rendering changes preserve the external Scoresheet contract and other Variants' behavior.
- [x] Verify long history and totals survive saving and reopening through the existing MatchStore seam. Reuse existing Scoresheet/engine tests for observable rows and totals; do not test the chosen cache or rendering algorithm's internals.
- [x] Add the focused compact-layout snapshot coverage and inspect Paper/Felt, longer names and larger text. Use a focused responsiveness walkthrough rather than fragile wall-clock assertions or a new benchmark subsystem.
- [x] If ticket 03 or 04 has already landed, verify long-history review and End/Resume with those operations; their lifecycle remains owned and tested by those tickets. Their completion is not a prerequisite for delivering correct, usable long-history scoring and inspection here.

## Scope and handoff

This ticket can start after ticket 02 and does not depend on tickets 03 or 04. Keep the existing screen composition, native scrolling and scoring rules; no broad Scoresheet redesign, new history controls or analytics are needed.

[Feature spec](../spec.md) · [ADR 0012](../../../docs/adr/0012-okey101-ends-by-table-decision.md)

Spec stories: 4, 20, 42.

## Relevant approved mockups

[Interactive flow](../mockups/flow.html) · [Mockup guide](../mockups/README.md)

The compact reference shows the final rows of a 104-Round Match with player headers retained and “Total” unbroken. End/Resume controls in the complete flow belong to their respective tickets.

![Compact long-history Scoresheet](../mockups/long-scoresheet-paper.png)

## Comments

### Implementation handoff — 2026-11-14

- Completed in `78fde3f4a04fae0dd09ef49d8d4c801258c240ad` on `feature/okey101-manual-ending-plan`. Parent verified source, acceptance evidence, native screenshots, commit, reviews and cleanup before reconciling this ticket.
- Lowest Total owns a linear history-delta calculation shared with its scoring arithmetic. The default supplied-engine implementation retains Standings differences for Survival/Elimination Join, Rejoin and Out events. Sparse raw entries remain zero for seated Entrants; scores, ordering, identities and totals retain their external contract.
- Scoresheet uses lazy rows and native pinned player headers under the existing single vertical scroller. Three-digit labels, modifier values, “Total” and four-digit totals fit compact widths. Default names use identifiable P1–P4/T1–T2 labels with full accessible names. Existing Standings composition and other Variants' rules remain intact.
- Checks: initial focused engine/store regressions 113/113; expanded focused run 353 tests, 341 passed and 12 inherited Standings image mismatches. Final normal-order full suite: 575 tests, 476 passed, 99 inherited image mismatches and no new failing names. All 13 new/affected Scoresheet references and all 29 prior feature references pass. Three previously failing shared Scoresheet references now pass after the intentional layout change. Independent Standards/Spec reviews report zero findings; whitespace check passed.
- Public-seam tests cover 104 ordered Rounds with modifiers and sparse scores, four on-disk reopenings, End/Resume, Round 105, Undo to 104 and zero, re-scoring, and unchanged Free Match usage. Existing Join/Rejoin/Out coverage remains passing.
- Native Paper/default-name and Felt/long-name/XXXL walkthroughs verified responsive scrolling with pinned headers at Rounds 91–104, aligned totals, End preview, final Standings, read-only review, Resume, Round 105, Undo and relaunch. The long-history fixture was generated through MatchStore and installed only in the disposable simulator. [Representative final captures](../verification/README.md) are stored with this tracker.
- Raw evidence: `/private/tmp/sira-ticket05-20261114/` (`handoff.txt`, `test-evidence.json`, `validation-commands.txt`, `review.txt`, `native-notes.txt`, `native-walkthrough/`, `cleanup-verification.json`). The final Paper capture is `long104-corrected-paper.png`; an earlier settling capture is not used as final evidence.
- Cleanup: dedicated iPhone 18 Pro Max / iOS 27.0 (24A434), UDID `4D43ADFF-45C1-4253-A5AB-863942736A2B`, deleted; all 15 original device states unchanged; no unexpected devices or remaining task build/automation sessions; Simulator app stayed closed. Parent read back the final cleanup evidence.
- This completes the five-ticket sequence. No implementation or cleanup blockers remain; the inherited snapshot mismatches are documented for review rather than reported as passing.
