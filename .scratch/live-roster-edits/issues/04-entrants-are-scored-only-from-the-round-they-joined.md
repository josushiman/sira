# 04 — Entrants are scored only from the Round they joined

**What to build:** Nothing a player can see. This is a prefactor that makes ticket 05 a small change instead of a risky one — "make the change easy, then make the easy change."

The Survival Engine gains the notion of a **join Round** per Entrant, defaulting to "seated at Setup", and omits an Entrant from Standings entirely for Rounds before it. Because no Match contains a join yet, every Entrant is joined from the first Round and the Standings that come out are identical to today's — the whole existing suite must stay green, unmodified.

This matters because the Scoresheet derives its cells by diffing Standings between Round prefixes. Without this rule, an Entrant who joins later would render as **zero** for Rounds they were not present for, rather than as absent — and no amount of view-level work can recover the distinction once the Engine has flattened it.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] The Engine omits an Entrant from Standings for every Round before their join Round, and includes them from it onward.
- [x] An Entrant seated at Setup is joined from the first Round, so all existing behaviour is preserved exactly.
- [x] The whole existing test suite passes **unmodified** — this is the acceptance test for the ticket. Any test that needs changing is a signal the rule has altered behaviour it shouldn't.
- [x] The Match-over determination counts only **joined** Entrants. An Entrant present in the Match but not yet joined must not keep a decided Match alive.
- [x] The everyone-busted tiebreak, which picks the lowest total when all remaining Entrants pass the limit in the same Round, considers only joined Entrants.
- [x] The Scoresheet's per-Round derivation seeds its previous totals only for joined Entrants, so an unjoined Entrant contributes no cell rather than a zero.
- [x] `rejoinTarget` continues to compute the highest total among Entrants still in, unchanged.
- [x] Covered at the existing `SurvivalEngine` seam, asserting on returned Standings rather than on how the Engine iterates. Prior art: `SurvivalEngineTests`, which already covers Rejoin replay in the same shape.
