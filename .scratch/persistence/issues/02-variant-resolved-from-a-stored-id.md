# 02 — A Match resolves its Variant from a stored id

**What to build:** A Match stops carrying its own copy of a Variant and instead names the one it is played under. Resolution happens against the Variant constants shipped in the app, so a rule correction reaches every Match rather than only new ones.

Prefactoring: this lands while the domain types are still value types, with no database involved. It is the whole of the Variant decision, verifiable on its own, and it removes that work from the SwiftData conversion in ticket 05.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [x] A Match holds its Variant's id, plus the Round count chosen at Setup where the Variant takes one
- [x] `Match.variant` becomes a computed property resolving that id against the Variants for its Game and applying the stored Round count
- [x] A Match naming an id that resolves to nothing yields no Variant, rather than a substitute or a crash
- [x] Setup records the id and the Round count for Okey 101's 8-or-12 choice; the Variant-copying helper that exists for that choice either moves into resolution or goes away
- [x] Every Win Condition still scores identically: Standings, Scoresheet rows, Home summaries and Match summaries are unchanged for Gonga 101, Gonga 151, Okey 21 and Okey 101
- [x] Okey 101 still ends after the Round count chosen at Setup, not the Variant's default
- [x] Tests cover resolution for all four Variants, the Round count override, and the unresolvable-id case
- [x] Full suite green; snapshots re-recorded only if nothing visual moved
