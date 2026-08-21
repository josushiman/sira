# 09 — Finish the Okey 21 rename in code

**What to build:** Ticket 01 renamed Okey 21's Variant *id* from `okey-standard` to `okey-21`, because the id was about to become a persistence contract. The Swift symbols were deliberately left alone — they aren't stored, so they were not urgent, and moving them touches snapshot directories. This ticket finishes the job so the codebase says "Okey 21" everywhere the glossary does.

Nothing a player can see changes. `CONTEXT.md` already names the four Variants as Gonga 101, Gonga 151, **Okey 21** and Okey 101; only the code still says "standard".

**Blocked by:** None — but best done when no other branch is mid-flight, since it renames files the snapshot suites key off.

**Status:** ready-for-human

- [x] `Variant.okeyStandard` becomes `Variant.okey21`
- [x] `RoundEntryStyle.okeyStandard` becomes `RoundEntryStyle.okey21`, along with its doc comment
- [x] `OkeyStandardRoundEntryView` becomes `Okey21RoundEntryView`, and its file is renamed to match
- [x] Doc comments and inline prose stop saying "Okey standard" — `Variant.swift`'s entrant-mode and entry-style comments and `SetupView`'s entrant-count comment are the ones that do
- [x] Test names follow: `test_okeyOffersStandardAnd101`, `test_okeyStandardCountsDownFromTwentyOne`, `test_okeyStandardIsLabelledOkey21` and the `OkeyStandardRoundEntryViewSnapshotTests` cases all read "okey21"
- [x] **No snapshot is re-recorded.** Snapshot PNGs are named after their test function and live in a directory named after their test class, so both are renamed on disk with `git mv` — a re-record would hide any visual change the rename accidentally caused
- [x] The renamed snapshot files are byte-identical to the ones they replace
- [x] Full suite green

## Comments

Raised by the `/code-review` Standards axis while reviewing tickets 01–02: the id was renamed but `static let okeyStandard` was not, so the diff half-fixed the mismatch its own commit message described. Kept out of that branch because the rename reaches `RoundEntryStyle`, a view, a view file, a snapshot test class and a snapshot directory — churn that would have buried a domain change under a rename.
