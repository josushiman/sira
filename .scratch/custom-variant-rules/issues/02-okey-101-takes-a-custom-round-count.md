# 02 — Okey 101 takes a custom Round count

**What to build:** An Okey 101 table that plays five Rounds can say so. The Round count chips become `8 · 12 · Custom` with **12** preselected, and choosing Custom reveals a numeric field. Enter 5, start the Match, and it ends when the fifth Round is scored — Rounds left counts down against 5 throughout.

A number outside 1–50 does not start a Match. Start is disabled and says why, and the number the player typed is left exactly as typed — never silently corrected to something they did not choose.

This is the first slice, so it pays for the machinery the next two get free. It introduces **`VariantParameter`**: one view-independent value type holding which kind of number a Variant takes, its preset chips, which is preselected, its legal range, whether a value is startable and why not, and the phrase it displays as. Modelled directly on `RoundEntryState` — a struct owning interactive state and its rules with no SwiftUI involved, tested by driving it directly.

Setup gains a rule blurb under the control, derived from the current selection, so picking 5 immediately reads back the rules with 5 in them. And the chosen number becomes visible outside Setup: Home's entrants line reads `4 players · 12 rounds` and Play's header carries the same phrase under the label. The phrase form is what distinguishes a Round count from a score, so no unit label is needed — and the label itself is never fused with the number, in any context.

`VariantCard`'s muted numeric tag goes at the same time. The Picker runs before Setup, so no number has been chosen; the tag could only ever show decoration, and after this it would show a value the player is about to be asked for.

**Blocked by:** 01.

**Status:** done

- [x] `VariantParameter` exists in the domain layer, holds kind, chips, preselection, range, startability, reason and display phrase, and touches no SwiftUI
- [x] Okey 101's Setup offers `8 · 12 · Custom` with 12 preselected
- [x] Selecting Custom reveals a numeric field; selecting a preset afterwards discards the custom value
- [x] A Round count of 1–50 starts a Match; anything outside disables Start with a visible reason and leaves the entered value untouched
- [x] The Match ends on the chosen Round, and Rounds left counts against it
- [x] The "never laid down" shortcut stays 101 whatever the Round count
- [x] Setup shows a rule blurb that updates live with the selection
- [x] Home's card and Play's header show `12 rounds` in the metadata line, never fused into the label
- [x] `VariantCard`'s numeric tag is removed
- [x] New `VariantParameterTests` drives the type directly — chips and preselection per Variant, custom entry, discarding on return to a preset, both range boundaries and the values just outside them, preservation of out-of-range input, the reason string, and the phrase per kind
- [x] `FixedRoundsEngineTests` covers a custom Round count ending the Match; `PlayStatsTests` covers Rounds left against it; `HomeCardTests` covers the metadata line
- [x] `SetupViewSnapshotTests`, `VariantPickerViewSnapshotTests`, `HomeViewSnapshotTests` and `PlayViewSnapshotTests` re-recorded per ADR 0004, in this ticket rather than after it, with new cases for a preset selection, a revealed Custom field and a non-startable state, in both themes
