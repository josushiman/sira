# 02 — Model Round modifiers as facts, with one shared multiplier derivation

**What to build:** Replace `Round.cifte: Bool` with the set of Entrants who called Çifte, add the Entrant who finished on the joker, and introduce the single shared derivation that turns those facts into a per-Entrant multiplier. Domain only — no UI in this ticket.

**Blocked by:** 01 — Fix the ×4 Çifte multiplication

**Status:** ready-for-agent

`MatchStore` is in-memory with no `Codable` anywhere in `sira/`, so there is nothing to migrate. Both new fields default to empty/nil so existing construction sites and test fixtures stay readable.

- [ ] `Round` records the Çifte callers as a set of Entrant IDs and the Okey atan as an optional Entrant ID; `cifte: Bool` is gone
- [ ] One shared internal derivation maps a Round plus the Match's Entrants to a per-Entrant multiplier, consumed by all three Engines
- [ ] Çifte: a caller who **lost** doubles themselves; a caller who **won** doubles everyone else
- [ ] An Entrant doubles if *any* caller's rule applies to them — Çifte's contribution caps at ×2 however many called
- [ ] Okey atmak doubles every Entrant uniformly
- [ ] The two contributions multiply, so a single Entrant can reach ×4 and no further
- [ ] "Won the Round" means an entered value of 0 in the keypad Variants, and being the team that isn't the recorded loser in Okey 21
- [ ] The derivation is internal — tested through the Engines, not exposed as its own tested surface
- [ ] `FixedRoundsEngineTests.test_cifteDoublesEveryEntrantsDeltaForThatRound` is **rewritten**, not extended: it currently asserts the wrong rule
- [ ] Engine tests cover: caller wins (everyone else ×2, caller ×1); caller loses (caller ×2 only); two callers, one winning one losing (the loser is ×2, not ×4)
- [ ] The Okey atan may also be a Çifte caller with no validation — their doubled 0 is still 0
