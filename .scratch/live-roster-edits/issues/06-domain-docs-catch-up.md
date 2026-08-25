# 06 — Domain docs catch up

**What to build:** The glossary and decision record describe the app as it now behaves. A reader coming to `CONTEXT.md` cold should find **Join** defined, should not be told that Entrants can never be added, and should not be given a list of Variants the code stopped shipping some time ago.

Deferred to the end deliberately: the shape of Join is only settled once it is built, and writing the ADR before the orphan behaviour was proven would have recorded an intention rather than a decision.

**Blocked by:** 05.

**Status:** ready-for-agent

- [ ] New **Join** glossary entry: an Entrant added to a live Match after Setup, entering on the highest total among Entrants still in, recorded against a Round so Undo reverses it. It must distinguish Join from **Rejoin**, which returns an Entrant who was already in the Match — the two are easy to conflate and the app now does both.
- [ ] **Rejoin** amended to point at its new sibling.
- [ ] **Closest to out** amended to stop being singular, matching ticket 01.
- [ ] **Entrant** amended: may now be added mid-Match, but still never removed.
- [ ] **Archived** amended to say explicitly that it is orthogonal to whether a Match is live — it is a visibility flag, and a live Archived Match accepts Rounds and roster edits alike.
- [ ] New ADR recording that Join is a Round-attached event mirroring Rejoin, rather than a direct mutation of the Match's Entrants, so that Undo and Engine replay both fall out for free. It must also record the accepted seated orphan and why ADR 0006 was left intact rather than weakened to "cannot be removed once they have scored" — that invariant is load-bearing for `Round.deltas`, `cifteCallers` and `RejoinEvent`, all of which key on an Entrant's id with no referential integrity behind them.
- [ ] New **Seat** glossary entry, or a decision to retire the word. Raised by the ticket 02 review: "seat" is used throughout the spec, the tickets and now in code — `EntrantName.seat`, "the seat-derived fallback", "the next free seat" — while the stored property is `Entrant.sequence` and `CONTEXT.md` pins **sequence** as this project's word for position (see the **Round** entry). A synonym that has reached an API parameter is either a concept worth defining or one worth renaming; pick one and apply it.
- [ ] **Unrelated staleness fixed in the same pass:** `CONTEXT.md` still describes four Variants — Gonga 101, Gonga 151, Okey 21, Okey 101 — while the code has carried three since the Customisable Variants change: Gonga, Okey, Okey 101. Entries that quote the old names or the old table sizes need correcting, including the **Entrant** and **Win Condition** entries.
- [ ] No stale term survives: a search of `CONTEXT.md` for the retired Variant names returns nothing outside deliberate historical notes.
- [ ] **Unrelated code fix carried in the same pass:** `SurvivalEngine` announces a winner on `stillIn.count == 1` without consulting `isOver`, so a Match with exactly one Entrant still in but not yet decided would return a result line on open Standings. Raised by both axes of the ticket 04 review, and pre-existing — `match.entrants.count > 1` used to be what kept it out of reach, and the join rule replaced that with `joinedEntrants.count > 1` without changing the shape. Unreachable in the app either way: Setup seats at least two, and a Join implies two were seated already. Guard the result branch on `isOver` so the two cannot disagree, and cover the one-Entrant Match at the `SurvivalEngine` seam — it is a behaviour change for that Match, which is why it is here rather than folded into 04.
