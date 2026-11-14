# 04 — Resume from Play or Home

**What to build:** A table deliberately resumes an Ended Okey 101 Match from Play or Home, keeping its history and returning it to Active. It can correct or add scores and end again without spending another Free Match. Archiving a live Match remains a separate visibility-only action.

**Blocked by:** [03 — End, archive and review an Okey 101 Match](03-end-archive-and-review-a-match.md).

**Status:** complete

- [x] Ended Play replaces the disabled bottom scoring button with Resume match, available while reviewing Standings or Scoresheet. No additional confirmation is required.
- [x] Play and Home use the same MatchStore Resume operation to reopen and unarchive together. Preserve Match identity, creation date, Entrants, Seats, Rounds, raw scores, modifiers and totals.
- [x] Resume returns to live Play, re-enables permitted scoring, Undo and renaming, and replaces the final outcome with provisional standings. Scoring more Rounds or correcting an existing total supports another explicit End with a newly derived result.
- [x] Home offers Resume instead of Restore for an Ended Okey 101 Match, including a migrated Ended Match that was never Archived. Its action resumes and opens Play; merely opening the card continues to show the read-only result.
- [x] Home's full card content remains a review target separate from its action control. Keep the date, status and result readable before the swipe/action is revealed, following the approved mockup's reviewed state.
- [x] A resumed Match returns to Active without changing its original start-date position. All/Archived semantics remain unchanged, and repeated End/Resume cycles retain correct visibility.
- [x] A live Match can still be manually Archived without ending it. Restore on a live Archived Match changes visibility only, and the Match remains scorable while Archived. Use state-aware actions without changing Gonga/Okey controls.
- [x] Resume, subsequent scoring and re-ending require no Unlock even with exhausted Free Matches. They neither create nor Start another Match, refund a Free Match nor spend another one.
- [x] Undoing all Rounds after Resume leaves Started permanent and the Match live; End is unavailable until another Round is scored. That next Round does not spend a Free Match again.
- [x] Persist resumed state and further scores across relaunch. Migration completion inference must not re-end a resumed legacy Match on later launches, including after Undo or additional Rounds.
- [x] Cover both Resume entry points, legacy Ended/unarchived Matches, repeated cycles, correction, archive distinctions, retained ordering and exhausted-access accounting through the existing store and presentation/navigation seams. Reopen the on-disk store to prove resumed state and history survive.
- [x] Update Paper/Felt snapshots for final review, live Play and Home's state-aware actions. Walk through End → review → Resume → score/correct → End from both entry points; no new UI-automation framework is required.

## Scope and handoff

Reuse ticket 03's End and read-only behavior; do not duplicate lifecycle logic between screens or introduce a new Match, reset workflow, activity-date sorting or new roster capability. Long-history presentation improvements remain in ticket 05, which is independently unblocked by ticket 02.

[Feature spec](../spec.md) · [ADR 0012](../../../docs/adr/0012-okey101-ends-by-table-decision.md)

Spec stories: 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 44.

## Relevant approved mockups

[Interactive flow](../mockups/flow.html) · [Mockup guide](../mockups/README.md)

In Home history, reveal the existing swipe action or action control in the interactive preview to see Resume; the static reference intentionally starts with the full card visible.

The [tied result in Felt](../mockups/tied-result-felt.png) also shows the Resume placement for a shared result.

![Resume from final standings](../mockups/final-result-paper.png)

![Home review and action discovery](../mockups/home-history-paper.png)

![Return to live Play](../mockups/live-play-paper.png)

## Comments

### Implementation handoff — 2026-11-14

- Completed in `809bd4136c00c72c157d66df0fb98778273df12d` on `feature/okey101-manual-ending-plan`. Parent verified the commit, shared Resume/Home wiring, native screenshots, checks/reviews and cleanup.
- Distinct Match/MatchStore Resume clears ending and archive state together while preserving identity, date, Started, Seats, history/modifiers and accounting. Play offers Resume on both result tabs; Home resolves the current Match by id before Resume and navigation. Main-card opening stays read-only. Live Archive/Restore and other Variants retain their behavior.
- Checks: focused regressions 257/257; full normal-order suite 568 tests, 466 passed, the exact same 102 inherited image mismatches as ticket 03. All 29 feature references pass, including 13 changed/new Resume references. Standards/Spec reviews and whitespace check are clear.
- Real V1 archived/unarchived results were resumed, scored or Undone to zero, and reopened across three launches without reapplying old-target completion. Covered repeated endings, correction while Locked, no-op Resume, save failures, date ordering and unchanged Free Match usage.
- Native Paper/Felt walkthrough verified both Play Resume entry points, review-only main-card opening, full card readability before reveal, Home swipe Resume, scoring/rename/Undo after Resume, correction changing the final winner, repeated End, Undo-zero eligibility, live Archive/Restore and app relaunch. Fourteen screenshots and raw flows are in `/private/tmp/sira-ticket04-20261114/native-walkthrough/`; exact harness assumptions corrected during observation are documented in `native-notes.txt`.
- Evidence: `/private/tmp/sira-ticket04-20261114/` (`handoff.txt`, `test-evidence.json`, `validation-commands.txt`, `review.txt`, `cleanup-verification.json`).
- Cleanup: dedicated iPhone 18 Pro Max / iOS 27.0 (24A434), UDID `2812C2AF-EFD1-4DA7-B2E8-DFEE787B13B6`, deleted; all 15 original states unchanged; no unexpected devices or task processes; Simulator app stayed closed. Parent read back cleanup evidence.
- Ticket 05 is next. Keep stable snapshot hosts and the working native End/Resume lifecycle, and preserve the documented inherited snapshot-failure distinction while improving long-history rendering/calculation.
