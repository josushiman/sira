# 07 — Okey standard Variant (Elimination)

**What to build:** Add Okey (standard) as a second Game/Variant, fully wired into every screen built in tickets 01–06: Variant picker, teams-only Setup, its own Round-entry form, and the `EliminationEngine`.

**Blocked by:** 06 — Home list: filter, archive, restore

**Status:** ready-for-agent

- [ ] Variant picker offers Okey (standard) alongside Gonga's variants, with its rule summary
- [ ] Setup is locked to Teams of 2 for this Variant (not user-choosable)
- [ ] Round entry for this Variant: pick which team lost the Round (applies −2 to their total)
- [ ] Gösterge: a stepper per team, capped at exactly 1 find per Entrant per Round, each find deducting 1 from the *other* team's total that Round
- [ ] Çifte toggle on this entry form doubles only the −2 loss penalty — Gösterge deductions are never doubled
- [ ] `EliminationEngine` computes `Standings`: counts down from the Variant's starting score, Match ends when any Entrant's total reaches 0, correct plain-language result
- [ ] Standings, Scoresheet, Undo, Archive/Restore, and the home list summary line all work for Okey-standard Matches with no Survival-specific assumptions leaking through
- [ ] `EliminationEngineTests` cover: the −2 penalty, Gösterge capped at 1 and applied to the other team, Çifte doubling only the penalty, and the Match ending at 0
