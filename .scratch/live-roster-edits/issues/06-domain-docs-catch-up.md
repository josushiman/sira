# 06 — Domain docs catch up

**What to build:** The glossary and decision record describe the app as it now behaves. A reader coming to `CONTEXT.md` cold should find **Join** defined, should not be told that Entrants can never be added, and should not be given a list of Variants the code stopped shipping some time ago.

Deferred to the end deliberately: the shape of Join is only settled once it is built, and writing the ADR before the orphan behaviour was proven would have recorded an intention rather than a decision.

**Blocked by:** 05.

**Status:** done

- [x] New **Join** glossary entry: an Entrant added to a live Match after Setup, entering on the highest total among Entrants still in, recorded against a Round so Undo reverses it. It must distinguish Join from **Rejoin**, which returns an Entrant who was already in the Match — the two are easy to conflate and the app now does both.
- [x] **Rejoin** amended to point at its new sibling.
- [x] **Closest to out** amended to stop being singular, matching ticket 01.
- [x] **Entrant** amended: may now be added mid-Match, but still never removed.
- [x] **Archived** amended to say explicitly that it is orthogonal to whether a Match is live — it is a visibility flag, and a live Archived Match accepts Rounds and roster edits alike.
- [x] New ADR recording that Join is a Round-attached event mirroring Rejoin, rather than a direct mutation of the Match's Entrants, so that Undo and Engine replay both fall out for free. It must also record the accepted seated orphan and why ADR 0006 was left intact rather than weakened to "cannot be removed once they have scored" — that invariant is load-bearing for `Round.deltas`, `cifteCallers` and `RejoinEvent`, all of which key on an Entrant's id with no referential integrity behind them.
- [x] New **Seat** glossary entry, or a decision to retire the word. Raised by the ticket 02 review: "seat" is used throughout the spec, the tickets and now in code — `EntrantName.seat`, "the seat-derived fallback", "the next free seat" — while the stored property is `Entrant.sequence` and `CONTEXT.md` pins **sequence** as this project's word for position (see the **Round** entry). A synonym that has reached an API parameter is either a concept worth defining or one worth renaming; pick one and apply it.
- [x] **Unrelated staleness fixed in the same pass:** `CONTEXT.md` still describes four Variants — Gonga 101, Gonga 151, Okey 21, Okey 101 — while the code has carried three since the Customisable Variants change: Gonga, Okey, Okey 101. Entries that quote the old names or the old table sizes need correcting, including the **Entrant** and **Win Condition** entries.
- [x] No stale term survives: a search of `CONTEXT.md` for the retired Variant names returns nothing outside deliberate historical notes.
- [x] **Unrelated code fix carried in the same pass:** `SurvivalEngine` announces a winner on `stillIn.count == 1` without consulting `isOver`, so a Match with exactly one Entrant still in but not yet decided would return a result line on open Standings. Raised by both axes of the ticket 04 review, and pre-existing — `match.entrants.count > 1` used to be what kept it out of reach, and the join rule replaced that with `joinedEntrants.count > 1` without changing the shape. Unreachable in the app either way: Setup seats at least two, and a Join implies two were seated already. Guard the result branch on `isOver` so the two cannot disagree, and cover the one-Entrant Match at the `SurvivalEngine` seam — it is a behaviour change for that Match, which is why it is here rather than folded into 04.

## Comments

Delivered on `feature/live-roster-edits`. 412 tests, 0 failures.

**The glossary.** `CONTEXT.md` gains **Join** and **Seat**, and amends **Rejoin**, **Entrant**, **Room left** (which is where *Closest to out* is defined) and **Archived**. Join and Rejoin now each carry an _Avoid_ line pointing at the other, since the pair is the conflation the ticket was worried about: they land an Entrant on the same number by the same rule, and differ in whether the Match already had them.

**Seat was defined, not retired.** The code votes overwhelmingly for the word — 162 uses of "seat" across `sira/` and `siraTests/` against a handful of `Entrant.sequence` — and the two are not actually synonyms at the domain level: a Round's sequence is freed by Undo and reused, a Seat never is, because it decides a dot-badge colour. So Seat is the concept and it has an entry. The stored property keeps the name `sequence`: renaming a `@Model` property is a schema change, and `SiraSchema.swift` has already absorbed two additive changes into v1.0.0 and says the next one cuts a v2 — spending that on a synonym is a bad trade. Both the glossary entry and the property's doc comment say so explicitly, so a reader hitting the mismatch finds it already answered rather than looking like drift.

**ADR 0009** records the Round-attached shape, the two-source arrangement `Entrant.arrivedMidMatch` + `JoinEvent` that survives Undo, and the seated orphan. It also records the rejected weakening of 0006 — "cannot be removed **once they have scored**" — on the grounds that a conditional invariant has to be re-evaluated correctly at every future call site, "has scored" is a question asked of every Round, Çifte caller list and RejoinEvent rather than a property of an Entrant, and the wrong answer is silent. Trading a visible orphan for a silent one is the bad direction. ADR 0006 is annotated with a forward pointer following the 0007→0008 precedent, marked *still current* rather than superseded.

**The Variant staleness was already gone.** The ticket says `CONTEXT.md` still describes four Variants; it does not, and has not since `.scratch/custom-variant-rules/issues/07`, which rewrote **Variant**, **Entrant**, **Win Condition** and the rest in the same pass. Verified rather than assumed: a search of `CONTEXT.md` for `Gonga 101`, `Gonga 151` and `Okey 21` returns nothing, the **Entrant** entry's table sizes (8 and 4) match `Variant.maxEntrants`, and **Win Condition** names Gonga / Okey / Okey 101. The ticket line was itself the stale thing.

**The `SurvivalEngine` fix** is TDD'd at the Engine seam: `test_aMatchWithOneEntrantIsNotOverAndAnnouncesNoWinner` was red on `result == "Alice wins!"` before the guard and green after. The result branch now reads `if !isOver` first, so `isOver` is the single thing that decides whether there is anything to announce and the two answers cannot disagree. Unreachable in the app as the ticket says — Setup seats at least two, and a Join implies two were seated already — so nothing a player can see changed, and no snapshot moved.
