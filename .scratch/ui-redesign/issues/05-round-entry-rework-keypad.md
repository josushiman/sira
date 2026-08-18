# 05 — Round-entry rework: keypad-based (Survival + Fixed Rounds)

**What to build:** A player adding a round to a Gonga (Survival) or Okey 101 (Fixed Rounds) Match gets the prototype's entry flow: a full-screen push (not a `.sheet`) showing every still-in Entrant at once, with a tap-to-focus active row that a shared keypad and quick-entry shortcuts write into — replacing the current one-entrant-at-a-time Next/Save Round flow.

**Blocked by:** 01 — Design-system foundation + Home reskin.

**Status:** ready-for-agent

- [ ] `RoundEntryView` is invoked via a full-screen push from Play's "Add Round" action instead of `.sheet`, with a Cancel/Save top bar matching the prototype.
- [ ] All still-in Entrants render as rows simultaneously (dot badge, name, current total, entered value), instead of one Entrant at a time.
- [ ] Tapping any Entrant row makes it "active"; the shared keypad (digits, `⌫`) and quick-entry shortcuts ("Won the round · 0", and "Never laid down · 101" where the Variant offers it) write into whichever row is active.
- [ ] The new state (per-Entrant entered values, active-Entrant selection, derived "ready to save" flag, derived Çifte-doubled preview) is extracted into a plain type with unit tests, independent of the view — analogous to existing `MatchTests`/`ScoresheetTests` coverage.
- [ ] Save is enabled once at least one value has been entered (matching the prototype's "ready" check), and produces the same per-Entrant Round deltas (doubled if Çifte is on) as the current implementation — no change to `SurvivalEngine`/`FixedRoundsEngine` behavior.
- [ ] Çifte toggle renders as the prototype's chip styling, with the doubled value previewed live per active row (e.g. "×2 → 24").
- [ ] Snapshot tests exist for the entry screen in both Paper and Felt, covering: no row active yet, a row active with a partial value entered, and Çifte on.
