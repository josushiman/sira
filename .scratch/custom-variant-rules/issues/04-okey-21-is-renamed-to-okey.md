# 04 — Okey 21 is renamed to Okey

**What to build:** Nothing a player can see beyond a label. The Variant called "Okey 21" becomes "Okey", because ticket 05 makes its starting score a Setup choice and a name that quotes a value it no longer guarantees is worse than no name. The Okey Picker reads Okey / Okey 101.

This reverts `.scratch/persistence/issues/09-finish-the-okey-21-rename-in-code.md`, which renamed the other way. That rename existed to fix an id that did not match its label; with the label no longer a number, the reasoning inverts. The id moves too — `okey-21` becomes `okey-standard` — which supersedes ADR 0007's original rename. Same device-data gate as ticket 03 applies, for the same reason.

Swift identifiers follow the label, but stay qualified: `Variant.okeyStandard`, `RoundEntryStyle.okeyStandard`, `OkeyStandardRoundEntryView`. Deliberately **not** `Variant.okey` or `RoundEntryStyle.okey` — `Game.okey` already exists, and two `okey` members one type apart is a collision that reads fine on the day it is written and gets misresolved later, by humans and agents alike. The user-facing label is "Okey"; the identifier is not.

Best done when no other branch is mid-flight: it renames files the snapshot suites key off, and it edits Setup, which ticket 02 also edits.

**Blocked by:** None — can start immediately, though see the note above about running it alongside 02.

> **Gate before starting:** same as ticket 03 — this deletes the id `okey-21`. Confirm nothing is stored on any device first.

**Status:** done

- [x] The Variant id is `okey-standard` and its label is "Okey"; `okey-21` no longer exists
- [x] `Variant.okey21` becomes `Variant.okeyStandard`
- [x] `RoundEntryStyle.okey21` becomes `RoundEntryStyle.okeyStandard`, along with its doc comment
- [x] `Okey21RoundEntryView` becomes `OkeyStandardRoundEntryView`, and its file is renamed to match
- [x] Doc comments and inline prose stop saying "Okey 21" — including `Variant.swift`'s entrant-mode and entry-style comments and `SetupView`'s entrant-count comment
- [x] Test names follow, and `Okey21RoundEntryViewSnapshotTests` is renamed with its subject
- [x] `VariantTests` asserts the new id explicitly, as ADR 0007 requires
- [x] **No snapshot is re-recorded.** Snapshot PNGs are named after their test function and live in a directory named after their test class, so both are renamed on disk with `git mv` — a re-record would hide any visual change the rename accidentally caused
- [x] The renamed snapshot files are byte-identical to the ones they replace, except where the "Okey 21" label itself is rendered
- [x] Full suite green

## Comments

Implemented on branch feature/match-owns-number.

Every snapshot under OkeyStandardRoundEntryViewSnapshotTests was renamed with git mv and passed byte-identical, so the rename caused no visual change of its own. Four snapshots did have to be re-recorded — SetupViewSnapshotTests.test_okeyStandard_teamsOnlyVariant_{paper,felt} and VariantPickerViewSnapshotTests.test_okey_bothVariants_{paper,felt} — because they render the label itself. Both pairs were compared against the originals by eye: the only difference is OKEY 21 -> OKEY in the Setup header and Okey 21 -> Okey on the Picker card.

CONTEXT.md and docs/adr/0007 still say Okey 21; that is ticket 07's scope. Full suite: 310 tests, 0 failures.
