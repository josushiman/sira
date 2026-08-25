# 02 — Rename an Entrant from their Standings row

**What to build:** In a **live** Match, tapping an Entrant's row in the Standings list opens a sheet where their name can be changed. Saving updates the name everywhere immediately — the Standings rows, the Play screen's tiles, every Scoresheet column, and the result line — including on Rounds played before the rename. No total moves, and no record of the previous name is kept.

This ticket also builds the **name validator**, the one new seam the feature introduces: a pure function over a candidate name and the Match's existing Entrants, returning whether the name is acceptable and why not if it isn't. Ticket 05 reuses it unchanged, so the two paths cannot drift.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Tapping an Entrant's Standings row on a live Match opens a rename sheet; saving applies the new name across every screen, including Rounds already played.
- [ ] Renaming leaves every total, delta, Out state and Round modifier untouched.
- [ ] An Entrant who is **Out** can be renamed.
- [ ] The sheet's copy says "team" where the Match's Entrant mode is teams and "player" otherwise, derived from existing state.
- [ ] Rename is unavailable on a Match already decided by its Win Condition, and available on an **Archived** Match that is still live — Archived is a visibility flag only.
- [ ] A name already used by another Entrant in the same Match is rejected, and the sheet says which name clashed so the player can resolve it without guessing.
- [ ] Comparison is on the **trimmed** name and is **case-insensitive using an explicitly pinned Turkish locale**, so dotted and dotless i fold the way a Turkish speaker expects. A test must assert the result is the same regardless of the device's own locale — the default folding maps `I` to `i` and is wrong here.
- [ ] Re-saving an Entrant under their own current name is accepted as a no-op, not rejected as a duplicate.
- [ ] Leaving the field blank materialises the seat-derived fallback the Setup screen already produces, numbered from the Entrant's **seat** rather than their position in a list.
- [ ] A hand-typed name that collides with an existing fallback name is rejected — the fallback is not exempt from uniqueness.
- [ ] A Match created before this rule that already contains two identically named Entrants still opens and scores normally; the clash only has to be resolved when one of them is edited.
- [ ] The validator is tested exhaustively as a pure function, with no Match, store or view involved. Prior art for pure-validation tests: `VariantParameterTests`.
- [ ] Snapshot coverage for the rename sheet in both player and team copy, and in its duplicate-name error state. Prior art: `RejoinSheetSnapshotTests`.
