# 01 — Fix the ×4 Çifte multiplication

**What to build:** A pure bug fix, under the existing `cifte: Bool` model, making a Çifte Round score ×2 instead of ×4. No new rules, no new fields — this lands alone so that the tests can distinguish this bug from anything built on top of it.

**Blocked by:** nothing

**Status:** ready-for-agent

Today `RoundEntryState.deltas` multiplies entered values by 2 when Çifte is on, and `FixedRoundsEngine` then multiplies the same Round by 2 again from `round.cifte`. Okey 101 Çifte Rounds score ×4. Gonga escapes only because `supportsCifte` is false, so the bug is currently invisible in three of four Variants.

The fix direction is set by ADR 0005: raw in the model, multiplied in the Engine.

- [ ] `Round.deltas` holds the **raw** entered counts — the values the player typed, never pre-multiplied
- [ ] `RoundEntryState`'s saved output is raw; its doubling logic survives only as the on-screen preview
- [ ] The naming makes the split obvious, so a reader can't confuse the preview value with the saved value
- [ ] The Engines are the only place a multiplier is applied — a grep for doubling arithmetic outside `sira/Engines/` comes back empty
- [ ] A Çifte Round in Okey 101 totals ×2 in `FixedRoundsEngineTests` — the regression test for this bug
- [ ] `RoundEntryStateTests` asserts that what the state hands to `onSave` is raw with Çifte on
- [ ] Existing Engine and entry tests still pass; snapshots re-recorded only if the preview's rendering actually changed
