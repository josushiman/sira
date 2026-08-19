# 03 — Okey atmak across all three Engines

**What to build:** Apply the modifier composition from ticket 02 in every Win Condition, so a joker finish scores correctly in Gonga 101/151, Okey 21 and Okey 101. Domain only.

**Blocked by:** 02 — Model Round modifiers as facts

**Status:** done

- [x] `SurvivalEngine`: a Round with an Okey atan doubles every Entrant's delta uniformly; Çifte is not offered in Gonga so it never contributes
- [x] `FixedRoundsEngine`: the full per-Entrant composition applies — this is the only Win Condition where Çifte's asymmetry is observable
- [x] `EliminationEngine`: the modifiers scale the losing team's −2 penalty only
- [x] Okey 21 — joker finish alone: −4
- [x] Okey 21 — Çifte alone: −4 (both of Çifte's branches collapse here, so the caller need not be recorded)
- [x] Okey 21 — both together: −8
- [x] **Gösterge deductions are never scaled by either modifier**, in any of the three cases above
- [x] `SurvivalEngine`: a Round doubled by a joker finish can push an Entrant Out, and `rejoinTarget` is computed from the doubled totals — Out and Rejoin gain no awareness of modifiers
- [x] Engine tests cover Okey atmak alone in both Survival and Fixed Rounds
- [x] Engine tests cover Okey atmak stacked with a losing Çifte caller: that Entrant ×4, everyone else ×2

## Outcome

Satisfied in full by f661d80, the commit for ticket 02, with no further
production code needed here.

Ticket 02 asked for "one shared internal derivation ... consumed by all three
Engines," and wiring that derivation into `SurvivalEngine`,
`FixedRoundsEngine` and `EliminationEngine` is the whole of the work this
ticket describes. Splitting the two was right on paper — 02 is the model, 03
is its application — but a shared derivation has no way to land in 02 without
its three consumers landing with it, or 02 would not have compiled.

Where each item is verified:

- Survival, Okey atmak uniform: `SurvivalEngineTests.test_okeyAtmakDoublesEveryEntrantsDeltaForThatRound`
- Fixed Rounds, full composition: `FixedRoundsEngineTests` — the three Çifte
  asymmetry cases, `test_okeyAtmakDoublesEveryEntrantsDeltaForThatRound`, and
  `test_losingCifteCallerInAnOkeyAtmakRoundTakesQuadrupleWhileOthersTakeDouble`
- Okey 21 −4 / −4 / −8, Gösterge unscaled in all three:
  `EliminationEngineTests.test_okeyAtmakDoublesOnlyTheLossPenalty`,
  `test_cifteDoublesOnlyTheLossPenalty`, `test_cifteCalledByTheWinningTeamDoublesTheSamePenalty`,
  `test_cifteAndOkeyAtmakTogetherTakeTheLossToMinusEight`
- Survival Out and Rejoin from doubled totals:
  `test_okeyAtmakRoundThatBustsAnEntrantAppliesTheDoubledTotal`,
  `test_rejoinTargetAfterAnOkeyAtmakRoundIsComputedFromTheDoubledTotals`

One item is guaranteed by the entry layer rather than the Engine: "Çifte is not
offered in Gonga so it never contributes." `SurvivalEngine` applies whatever
callers a Round carries; what keeps Gonga clear is `Variant.supportsCifte`
(`VariantTests.test_gongaHasNoCifteConcept`) and `RoundEntryView` guarding the
flag behind it. The Engine has no Gonga-specific block, and the ticket's wording
reads as accepting that.
