# 03 — End, archive and review an Okey 101 Match

**What to build:** A table explicitly ends an Okey 101 Match from either Play tab, checks the prospective result, and confirms or cancels. A confirmed ending archives the Match and shows its read-only final standings; opening it from Home reviews the result without restarting play.

**Blocked by:** [02 — Start and score target-free Okey 101 Matches](02-start-and-score-target-free-matches.md).

**Status:** complete

- [x] Add round remains primary. End match is a secondary action available from both Standings and Scoresheet, including for a live Archived Match.
- [x] End is unavailable with zero currently scored Rounds, both immediately after Setup and after Undo removes every Round. Explain that a Round must be scored first; leaving Play remains possible. Enforce eligibility through the shared domain/store boundary as well as the UI.
- [x] End opens a focused confirmation showing the current Round count and prospective winner or all tied lowest-total Entrants. Explain that confirmation archives the Match and it can later Resume.
- [x] Cancel leaves scores, ending state, archive state and the selected Play tab unchanged.
- [x] Confirm uses a shared MatchStore End operation that persists ending and archiving together. It dismisses the confirmation, selects Standings even if invoked from Scoresheet, and shows the final result without automatically returning Home.
- [x] Final standings remain in the existing Play screen, with a way Home and a readable Scoresheet. Banner, result tile, confirmation and Home summary consistently identify every tied winner.
- [x] Ended Matches refuse score entry, Undo and renaming at the ordinary mutation boundary and in the UI. The read-only Scoresheet must not advertise Undo. This protection applies to migrated completed Matches as well as newly Ended ones.
- [x] Newly Ended Matches leave Active and are discoverable in All and Archived. Tapping the main content of the Home card opens the read-only result without changing ending or archive state. Keep Home's filter meanings and start-date ordering.
- [x] Avoid exposing an Ended Match's old Restore action as a substitute for Resume. Ticket 04 supplies the deliberate Resume affordances and complete state-aware Home actions; keep live Archive/Restore and Gonga/Okey behavior working during this slice.
- [x] A relaunch retains the final result, scores, read-only behavior and archive state. Ending or reviewing consumes no additional Free Match and does not change Started.
- [x] Exercise End eligibility, cancellation, confirmation from both tabs, unique/tied results, guarded mutations and persisted outcomes using the approved store seam and existing presentation/navigation patterns. Use real on-disk reopen coverage for durability.
- [x] Snapshot the confirmation and Ended views in Paper/Felt, including a tie and read-only Scoresheet. Verify focused sheet behavior, readable copy, 44-point effective touch targets, Reduce Motion and native navigation without adding a UI-testing framework.

## Scope and handoff

The final-result mockups include the Resume button implemented by ticket 04; do not require that ticket's action in this slice. Keep its place in the final design clear while preserving a coherent read-only review screen. This ticket does not change Round scoring, other Variants' endings or roster capabilities.

[Feature spec](../spec.md) · [ADR 0012](../../../docs/adr/0012-okey101-ends-by-table-decision.md)

Spec stories: 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 36, 44.

## Relevant approved mockups

[Interactive flow](../mockups/flow.html) · [Mockup guide](../mockups/README.md)

Also use the [zero-Round eligibility reference](../mockups/zero-rounds-paper.png) when verifying that End is unavailable before scoring or after Undo removes every Round.

![End confirmation](../mockups/end-confirmation-paper.png)

![Final standings](../mockups/final-result-paper.png)

![Tied result in Felt](../mockups/tied-result-felt.png)

![Archived result on Home](../mockups/home-history-paper.png)

## Comments

### Implementation handoff — 2026-11-14

- Completed in `cf69abe6b085705e23648eb0da4d714d117cfc62` on `feature/okey101-manual-ending-plan`. Parent verified the commit, mutation boundaries, native confirmation/tied-result references, test/review evidence and cleanup.
- Shared End persists ending and archive state together. Pure LowestTotalResult supplies every tied winner consistently. Both tabs expose End with current-Round eligibility; cancel preserves tab/state, confirm selects final Standings and remains in Play. Ended score, Undo, rename, roster/event and Restore mutations are refused at store/model boundaries; Home card opening remains review-only.
- Checks: focused regressions 250/250; full normal-order suite 555 tests, 453 passed, exactly the same 102 inherited snapshot mismatches as ticket 02. All 23 new/affected feature references pass; no new failures. Standards/Spec reviews and whitespace check are clear.
- Native ordinary-UI Maestro walkthrough verified zero-Round guidance on both tabs, scoring, cancel/confirm from both tabs, read-only controls and Scoresheet, Active removal/Archived discovery, main-card review, Undo to zero, four-way tied results in Felt and unchanged Start accounting. Accessibility-extra-large scrolling reaches all four winners and both actions; Reduce Motion was enabled and tab interaction verified.
- Evidence, exact commands and reusable temporary flow scripts: `/private/tmp/sira-ticket03-20261114/` (`handoff.txt`, `test-evidence.json`, `review.txt`, `validation-commands.txt`, `native-walkthrough/`).
- Cleanup: dedicated iPhone 18 Pro Max / iOS 27.0 (24A434), UDID `A7F4FF00-B6A4-4D75-A7FD-47BE67299B61`, deleted; all 15 original states unchanged; no task processes or unexpected devices; Simulator app stayed closed. Parent read back `cleanup-verification.json`.
- Ticket 04: add distinct store/model Resume clearing `ended` and `archived` together; do not weaken Restore's read-only guard. `HomeCard.isReadOnly` is a value projection; resolve current Match by id at action time. The shared Play bottom chrome owns End confirmation. Keep snapshot host isolation and End-only adaptive DecisionSheet scrolling; Resume is deliberately still absent in this completed slice.
