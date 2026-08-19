# 01 — Fix the ×4 Çifte multiplication

**What to build:** A pure bug fix, under the existing `cifte: Bool` model, making a Çifte Round score ×2 instead of ×4. No new rules, no new fields — this lands alone so that the tests can distinguish this bug from anything built on top of it.

**Blocked by:** nothing

**Status:** ready-for-agent

Today `RoundEntryState.deltas` multiplies entered values by 2 when Çifte is on, and `FixedRoundsEngine` then multiplies the same Round by 2 again from `round.cifte`. Okey 101 Çifte Rounds score ×4. Gonga escapes only because `supportsCifte` is false, so the bug is currently invisible in three of four Variants.

The fix direction is set by ADR 0005: raw in the model, multiplied in the Engine.

- [x] `Round.deltas` holds the **raw** entered counts — the values the player typed, never pre-multiplied
- [x] `RoundEntryState`'s saved output is raw; its doubling logic survives only as the on-screen preview
- [x] The naming makes the split obvious, so a reader can't confuse the preview value with the saved value
- [x] The Engines are the only place a multiplier reaches a *saved* score — the sole remaining doubling outside `sira/Engines/` is `doubledPreview`, which is presentation-only and documented as such
- [x] A Çifte Round in Okey 101 totals ×2 in `FixedRoundsEngineTests` — the regression test for this bug
- [x] `RoundEntryStateTests` asserts that what the state hands to `onSave` is raw with Çifte on
- [x] Existing Engine and entry tests still pass; snapshots re-recorded only if the preview's rendering actually changed

## Comments

**Done.** `RoundEntryState.deltas` is now `rawDeltas` and returns the entered counts unscaled; `doubledPreview` is unchanged and documented as presentation-only; `RoundEntryView.save` passes raw counts plus the Çifte flag, and the Engine applies the doubling.

The regression test lives in `FixedRoundsEngineTests` and deliberately **crosses the seam** — it drives a `RoundEntryState` the way a player would, builds the Round that entry actually produces, and scores it. That crossing is the point: neither existing suite could catch this bug, because the Engine tests build `Round` fixtures by hand and the entry tests never reach an Engine, so each half was individually green while the pair was wrong.

Both new tests were verified red against the old behaviour by temporarily reintroducing the doubling: Alice scored 40 instead of 20. Reverted, full suite green — 133 tests, 0 failures, on iPhone 17 / iOS 26.5.

One checklist item was amended rather than ticked as written: the grep for doubling outside `sira/Engines/` is not empty, because `doubledPreview` necessarily still multiplies. It cannot reach a saved score, which is the property that actually matters.

Note for ticket 02: `test_undoReversesADoubledCifteRound` in `SurvivalEngineTests` still exercises a Çifte Round in **Gonga**, which no longer offers Çifte (`supportsCifte: false`). It passes and was left alone here to keep this ticket a pure bug fix, but it asserts a combination the app can't produce and should be revisited when `cifte: Bool` is replaced.
