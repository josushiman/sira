# Okey 101 ends when the table chooses

Status: ready-for-agent

## Problem Statement

Okey 101 currently asks the table to choose a Round count before play and automatically finishes the Match when that count is reached. Tables often decide how long to play as they go and may want to continue beyond a conventional count. The current flow forces an unnecessary decision at Setup, stops scoring before the table wants to stop, and provides no explicit way to end and later Resume the same Match.

The app also presents target-dependent information throughout the flow. Removing the Setup control alone would leave misleading copy, an invalid Match under current routing rules, and no reliable final-result lifecycle.

## Solution

Make Okey 101 open-ended. Setup asks only who is playing, and the table can keep scoring Rounds until it explicitly chooses End match. There is no target, standard-count milestone, extension prompt, or Match-level Round cap. Lowest Total replaces Fixed Rounds as the Win Condition: scoring stays the same, the lowest cumulative total wins, and tied lowest totals share the result.

End match is a secondary action available from both Play tabs after at least one currently scored Round. It previews the prospective result in a confirmation. Cancel changes nothing; confirm ends and archives the Match together, then shows final standings in Play. The table can review Standings and Scoresheet or return Home.

An Ended Match is read-only. Resume match explicitly reopens and unarchives the same Match with its scores preserved, enabling further Rounds and corrections without spending another Free Match. Opening an Ended Match for review never resumes it. Live Matches can still be Archived and Restored without ending them.

Gonga and Okey retain their current Setup parameters, scoring and automatic endings.

## User Stories

1. As an Okey 101 player, I want to select my Variant without choosing a Round target, so that I can decide how long to play at the table.
2. As an Okey 101 player, I want Setup to retain player count and names, so that preparing the table remains familiar.
3. As an Okey 101 player, I want the picker and Setup to explain manual ending and lowest-score victory, so that I understand the rules before starting.
4. As an Okey 101 player, I want to continue adding Rounds beyond conventional counts and the old 50-Round maximum, so that the app follows my table's decision to keep playing.
5. As an Okey 101 player, I want to see Rounds played instead of Rounds left, so that the statistic describes actual play without implying a target.
6. As an Okey 101 player, I want Home and Play to omit target metadata, so that neither screen suggests an agreed Match length.
7. As an Okey 101 player, I want existing Round scoring and modifiers to behave as before, so that changing the ending flow does not change my scores.
8. As an Okey 101 player, I want live standings to show the current leader without declaring a final winner, so that I can keep playing until the table ends the Match.
9. As an Okey 101 player, I want End match available from both Standings and Scoresheet, so that I can finish from whichever view I am using.
10. As an Okey 101 player, I want to preview the prospective result before confirming End, so that I can check the outcome before declaring it final.
11. As an Okey 101 player, I want the End confirmation to identify every tied winner, so that a tie is represented accurately.
12. As an Okey 101 player, I want to cancel the End confirmation without changing scores, lifecycle or visibility, so that an accidental tap does not affect the Match.
13. As an Okey 101 player, I want ending to require at least one scored Round, so that the app cannot declare a result for an unplayed Match.
14. As an Okey 101 player, I want End to become unavailable if Undo removes every Round, so that the same eligibility rule applies while correcting scores.
15. As an Okey 101 player, I want confirming End from either tab to show final Standings, so that I immediately see the declared result.
16. As an Okey 101 player, I want ending to archive the Match automatically, so that finished play leaves my Active list without another action.
17. As an Okey 101 player, I want a way Home from the final result, so that I can finish reviewing when I choose.
18. As an Okey 101 player, I want to find ended results in All and Archived, so that automatic archiving does not make my history inaccessible.
19. As an Okey 101 player, I want tapping an Ended Match to open its read-only result, so that reviewing history does not restart play.
20. As an Okey 101 player, I want to read the complete Scoresheet after ending, so that I can inspect how the final totals were reached.
21. As an Okey 101 player, I want Ended Matches to prevent score entry, Undo and renaming until Resume, so that a declared result is not changed accidentally.
22. As an Okey 101 player, I want the result banner, result tile and Home summary to agree about tied winners, so that the outcome is consistent wherever I read it.
23. As an Okey 101 player, I want Resume match in place of the disabled bottom scoring button, so that I can deliberately continue from the result screen without another confirmation.
24. As an Okey 101 player, I want Home to offer Resume instead of Restore for an Ended Match and open live Play afterward, so that continuing from history is direct.
25. As an Okey 101 player, I want to Resume an older Ended Match even if it was never Archived, so that legacy visibility does not block continuation.
26. As an Okey 101 player, I want Resume to preserve the Match's identity, start date, Entrants, Rounds and totals, so that continuing does not create a different Match or lose its history.
27. As an Okey 101 player, I want Resume to unarchive the Match, so that it returns to my Active list when play resumes.
28. As an Okey 101 player, I want to correct scores or names after Resume and end the Match again, so that a mistaken final result can be deliberately revised.
29. As an Okey 101 player, I want to add further Rounds after Resume and declare a new final result, so that continuing beyond an earlier ending is ordinary play.
30. As a Locked player, I want to Resume an existing Match without purchasing an Unlock or consuming another Free Match, so that access to a Match I already Started remains intact.
31. As an Okey 101 player, I want Undo back to zero Rounds and subsequent scoring to preserve Started and my Free Match usage, so that correcting history never charges me twice.
32. As an Okey 101 player, I want to Archive a live Match without declaring a result, so that I can put it aside temporarily.
33. As an Okey 101 player, I want Restore on a live Archived Match to change visibility only, so that restoration does not alter its lifecycle or scores.
34. As an Okey 101 player, I want a live Archived Match to remain scorable, so that archiving continues to be a visibility choice.
35. As an Okey 101 player, I want Home's filters and original start-date ordering to stay consistent after Resume, so that my history remains predictable.
36. As an Okey 101 player, I want the ending, archive state and resumed scores to survive quitting and reopening the app, so that a relaunch does not change the status of my Match.
37. As an existing Okey 101 player, I want previously completed Matches to retain their final results after updating, so that old outcomes are not silently reopened.
38. As an existing Okey 101 player, I want unfinished Matches to lose their old targets while retaining their scores, so that ongoing play adopts manual ending immediately.
39. As an existing Okey 101 player, I want updating to preserve each Match's existing archive visibility, so that the update does not unexpectedly hide old results or restore hidden Matches.
40. As an existing Okey 101 player, I want migration to retain Started Matches whose Rounds were all undone, so that previously played history and Free Match accounting are preserved.
41. As an existing player, I want migration to preserve Entrant Seats, Round order, raw scores, modifiers and stored events, so that my tables and totals remain trustworthy.
42. As an Okey 101 player, I want long Scoresheets and three-digit Round numbers to remain readable and usable, so that open-ended play is practical.
43. As an Okey 101 player, I want the existing per-Round score-entry limits to remain familiar, so that removing Match-length limits does not unexpectedly change score input.
44. As a Gonga or Okey player, I want my existing Setup choices, automatic endings and lifecycle controls to keep working, so that this Okey 101 change does not disrupt my Variant.

## Implementation Decisions

- **Scope and terminology:** Okey 101 uses Lowest Total instead of Fixed Rounds. This is a change to ending semantics, not Round scoring, Çifte, Okey atmak, roster rules or per-Round input bounds. No Match-level count limit or advisory count remains.
- **Variant parameters:** The Variant declares whether it needs a VariantParameter. Gonga retains its Survival limit and Okey its Elimination starting score; Okey 101 needs none. Setup state, Match creation, validity checks, Home routing, Play routing and engine dispatch must accept a target-free Okey 101 Match. Absence of a required parameter for the other Variants remains invalid; unresolved Variant identities retain the existing non-destructive handling.
- **Result and lifecycle:** Keep the result derived from the existing ordered Rounds and Entrant totals, but persist whether an Okey 101 Match is Ended independently of Archived and Started. Neither Round count nor archive state can stand in for an explicit ending. Live standings are provisional; only Ended standings declare the final result. Tied lowest totals identify every tied winner.
- **Shared mutation boundary:** Extend MatchStore with End and Resume operations used by Play and Home. Enforce the current-Round requirement and Ended mutation restrictions at the existing domain/store boundary, not only by disabling buttons. A successful End persists Ended and Archived together; a successful Resume clears both together. Preserve Match identity, start date, Seats, Round sequence and all scoring facts.
- **Ended read-only behavior:** Before Resume, prevent adding Rounds, Undo and renames through the ordinary mutation paths as well as the UI. Reviewing Standings or Scoresheet, returning Home and existing deletion behavior remain available. Ending or resuming a Match must not introduce a new roster-editing capability.
- **Creation flow:** Keep the Okey Variant picker. Update Okey 101's rule description and remove its presets, custom Round-count field and count validation. Setup retains player count and names, with the explanation: “Keep playing until your table decides to end. Lowest score wins.” Keep Gonga and Okey parameter controls intact.
- **Live Play:** Add round remains the primary action. End match is a secondary action available from both tabs once at least one current Round exists, including while a live Match is Archived. With zero current Rounds, End is unavailable and leaving Play remains possible. Replace Rounds left with Rounds played and omit target metadata.
- **End interaction:** Show a confirmation previewing the prospective winner or tied result. Cancel performs no lifecycle, archive or score mutation. Confirm ends and archives together, dismisses the confirmation, selects Standings and shows the final result in the existing Play screen. Keep Home available rather than immediately navigating away from the result.
- **Result review and Resume:** Opening an Ended Match never resumes it. Both tabs remain readable, with mutation controls unavailable and no Scoresheet invitation to Undo. Resume match replaces the disabled bottom button and needs no additional confirmation. It reopens and unarchives the same Match and returns to live Play. Subsequent Rounds, corrections, Undo and repeated End/Resume cycles use that same Match.
- **Home actions:** Ended Okey 101 cards offer Resume instead of Restore, regardless of archive visibility; invoking it resumes and opens Play. Live Archived Matches retain Restore as a visibility-only action. Manual Archive remains available for live Matches without declaring a result.
- **Home presentation:** Preserve Active / All / Archived filter meanings and original start-date ordering. Newly Ended Matches are absent from Active and discoverable in All and Archived. Resuming returns a Match to Active without moving its start date or reordering history by recent activity. Home and Play omit Okey 101 target metadata and consistently show declared results.
- **Access accounting:** Resume neither creates nor Starts a Match and requires no Unlock, even when the Free Matches are exhausted. Started remains permanent after Undo removes all Rounds; scoring again on the same Started Match must not spend another Free Match. End, Resume, Archive and Restore do not change the tally.
- **Schema migration:** Introduce schema V2 and preserve the old schema's stored shape. Determine each existing Okey 101 Match's completion from its old target before discarding that target's meaning. Matches that had reached the target become Ended; unfinished Matches become target-free and live. Preserve each Match's previous archive visibility in either case. Automatic archiving applies to newly performed End actions, not retroactively to migrated results.
- **Migration integrity:** Preserve Entrants and their Seats, ordered Rounds, raw deltas, modifiers, stored events, start dates, Started state, existing access accounting and other Variants' parameters and behavior. Account for the pre-existing Started/tally reconciliation obligations during migration without refunding or double-spending a Free Match. A legacy Started Match with zero current Rounds must remain Started and live. Reopening an already migrated store must not repeat legacy completion inference after the user has resumed it.
- **Long history:** Remove count assumptions throughout the flow. Verify Scoresheet calculation and rendering beyond the old Setup maximum and with three-digit Round numbers. Address calculation or layout problems exposed by that verification without adding a product cap or introducing an unrelated Scoresheet redesign.
- **Implementation sequence:** First implement domain, store and migration behavior with tests; then target-free creation and routing; then Play's End/result/Resume flow; then Home actions and long-history presentation. Keep lifecycle logic shared rather than introducing separate screen-specific implementations.

## Testing Decisions

- **Confirmed test seams:** The user approved the existing MatchStore boundary as the primary seam for lifecycle, read-only enforcement, persistence/migration and Free Match accounting, supplemented by the existing screen snapshot approach. Prefer these seams to new test-only interfaces. This spec does not require a new automated UI interaction framework.
- **Good-test standard:** Drive public operations and assert behavior visible to the table: scores, declared results, permitted actions, visibility, retained history and Free Match usage. Do not test private helper structure, method-call order, storage-field naming or an implementation-shaped state machine. Assert outcomes through the same store, model queries and presentation projections the app uses.
- **Store lifecycle coverage:** Follow the existing MatchStore tests and FreeMatchTests. Exercise creation without a parameter, scoring beyond old targets, End with one or more Rounds, refusal to end with zero Rounds, read-only mutation enforcement, Resume, correction, further scoring and re-ending. Verify scores and identity are retained, End/Resume change ending and archive state together, and accounting never changes after the first Start. Include exhausted Free Matches and Undo back to zero after Resume.
- **Archive distinctions:** Through the same store seam, verify live Archive/Restore changes visibility alone, live Archived Matches remain scorable, End works on a live Archived Match, and Resume works for both Archived and unarchived Ended Matches. Exercise the shared operations used by both Home and Play rather than duplicating lifecycle logic in tests.
- **Durability and migration:** Follow MatchStorePersistenceTests' temporary on-disk store and two-launch pattern. Write a real V1 store, close it, open it with the current migration plan and assert retained behavior and facts; do not simulate migration by directly setting final V2 fields. Include completed and unfinished Matches across both archive states, tied results, custom old targets, Started Matches with no current Rounds, Round ordering, Seats, modifiers and stored events. Reopen after Resume and further scoring to prove migration inference does not run again. Keep Gonga, Okey and existing access accounting represented in the fixture.
- **Recovery compatibility:** Follow the existing MatchStoreRecoveryTests to ensure migration does not replace valid legacy data with an empty store or silently discard history through the recovery path. Verify legacy data is successfully read, not merely that opening returns a working container.
- **Scoring and presentation prior art:** Reuse the existing engine, Scoresheet, MatchSummary, HomeCard, PlayStats, MatchFilter and Navigator test patterns only where their external outputs change or an existing regression needs coverage. Preserve multiplier behavior, cumulative totals and lowest-total ties. Verify Rounds played, target-free metadata, consistent tied-result output, read-only card opening, Resume navigation and original start-date ordering. Avoid duplicating the full lifecycle matrix at every projection.
- **Snapshots:** Follow SetupViewSnapshotTests, VariantPickerViewSnapshotTests, PlayViewSnapshotTests and HomeViewSnapshotTests using the existing paper/felt theme fixtures and fixed-size rendering. Replace obsolete Okey 101 count-control snapshots with target-free Setup. Cover live Play, zero-Round End eligibility, End confirmation with a unique winner and a tie, Ended Standings, read-only Scoresheet, Resume and Home's state-aware actions. Use the existing snapshot rendering approach for the confirmation content; do not introduce a lower-level seam just for it.
- **Interaction verification:** Verify End is accessible on both tabs, cancel leaves the Match untouched, confirm from Scoresheet selects final Standings, reviewing history does not implicitly Resume, and both Resume entry points open live Play. Use existing navigation/state tests where available and a focused app walkthrough for presentation behavior that snapshots cannot prove.
- **Long-history verification:** Exercise more than 50 Rounds and a history with at least 100 Rounds through the primary seam; verify totals, retained ordering and continued End/Resume behavior. Inspect three-digit Round layout and perform a focused responsiveness check on Scoresheet. Prefer observable correctness and a representative usability check to fragile timing assertions or a new benchmark subsystem.
- **Regression scope:** Run the focused store, persistence/migration, affected scoring/projection tests and updated snapshots. Retain relevant Gonga/Okey Setup, automatic-ending and archive behavior coverage. Broaden testing only when changes or failures justify it.

## Out of Scope

- Changes to Gonga or Okey's Setup parameters, automatic endings, scoring or lifecycle controls.
- Advisory Round counts, conventional-count prompts, extension workflows, configurable Okey 101 targets or a replacement Match-level Round cap.
- New tie-break rules, altered Round modifiers, widened per-Round score input, Entrant removal, late Okey 101 Joins or other roster changes.
- Starting a new Match to continue an old result, resetting scores during Resume, spending additional Free Matches or changing purchase/Unlock behavior.
- Home sorting by recent activity, new filters, changing existing filter meanings or moving resumed Matches to the top.
- A separate result-screen architecture, broad visual redesign, export/sharing, new history analytics or a new automated UI-testing/benchmark framework.
- Splitting implementation tickets, implementing app code, publishing a build, merging branches or releasing the change as part of this specification task.

## Further Notes

- All product decisions above were agreed during the grill-with-docs session; the user subsequently confirmed the proposed test seams while producing this specification.
- This specification replaces the earlier planning draft at the same local issue-tracker entry and is marked ready-for-agent. It is the implementation handoff; the app change itself has not been implemented.
- The domain glossary records Lowest Total, Ended, Resume and Okey 101's absence of a VariantParameter. [ADR 0012](../../docs/adr/0012-okey101-ends-by-table-decision.md) records the persistence/lifecycle decision and partially supersedes [ADR 0008](../../docs/adr/0008-variants-carry-shape-matches-carry-values.md). Other ADR contracts remain in force.
- Important implementation risks are legacy completion inference before dropping targets, accidental resumption while reviewing results, incomplete read-only enforcement, inconsistent tied-winner text and long-history Scoresheet calculation/rendering. The testing decisions above target these risks.
