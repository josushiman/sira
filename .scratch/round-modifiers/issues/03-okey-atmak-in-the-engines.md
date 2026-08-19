# 03 — Okey atmak across all three Engines

**What to build:** Apply the modifier composition from ticket 02 in every Win Condition, so a joker finish scores correctly in Gonga 101/151, Okey 21 and Okey 101. Domain only.

**Blocked by:** 02 — Model Round modifiers as facts

**Status:** ready-for-agent

- [ ] `SurvivalEngine`: a Round with an Okey atan doubles every Entrant's delta uniformly; Çifte is not offered in Gonga so it never contributes
- [ ] `FixedRoundsEngine`: the full per-Entrant composition applies — this is the only Win Condition where Çifte's asymmetry is observable
- [ ] `EliminationEngine`: the modifiers scale the losing team's −2 penalty only
- [ ] Okey 21 — joker finish alone: −4
- [ ] Okey 21 — Çifte alone: −4 (both of Çifte's branches collapse here, so the caller need not be recorded)
- [ ] Okey 21 — both together: −8
- [ ] **Gösterge deductions are never scaled by either modifier**, in any of the three cases above
- [ ] `SurvivalEngine`: a Round doubled by a joker finish can push an Entrant Out, and `rejoinTarget` is computed from the doubled totals — Out and Rejoin gain no awareness of modifiers
- [ ] Engine tests cover Okey atmak alone in both Survival and Fixed Rounds
- [ ] Engine tests cover Okey atmak stacked with a losing Çifte caller: that Entrant ×4, everyone else ×2
