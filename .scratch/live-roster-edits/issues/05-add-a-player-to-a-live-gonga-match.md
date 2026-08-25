# 05 — Add a player to a live Gonga Match

**What to build:** Someone arrives two Rounds into a Gonga Match and there's a free seat. A dashed **Add player** row at the foot of the Standings list adds them without abandoning the Match. Before committing, the row previews the score they'd start on — "joins on 61" — so the table can agree the number out loud. The new player enters on **the highest total among Entrants still in**, takes the next free seat, keeps that seat's dot-badge colour for the rest of the Match, and is scored from that Round onward like everyone else.

The Scoresheet tells the truth about them: Rounds played before they arrived show an em-dash, not a zero, because they weren't at the table. Their join Round renders the way a **Rejoin** does, because the two are the same kind of event.

A join is recorded against the latest Round, which means **Undo** reverses a mistaken add exactly as it reverses a mistaken score.

**Blocked by:** 02 (the name validator), 04 (the Engine's join-Round rule).

**Status:** done

- [x] The Add row appears at the foot of the Standings list on a live Gonga Match with a free seat, and adding a player scores them from that Round onward.
- [x] The joiner enters on the highest total among Entrants **still in**. Entrants who are **Out** are excluded from that maximum — an Out Entrant typically holds the highest total on the table, and inheriting it could start the newcomer beyond everyone actually playing, or even Out.
- [x] The entering total reuses the existing Rejoin target rather than a parallel implementation, and keeps its cap at the Match's limit and its everyone-busted fallback.
- [x] The previewed number is derived at render time, not cached when the screen opens: it moves as Rounds are scored and as Entrants go Out, with the sheet still on screen.
- [x] The joiner is stamped with the next free seat; no existing Entrant's seat moves.
- [x] Adding is refused at the Variant's maximum, and the Add row is **hidden entirely** — never shown-and-disabled — when the table is full, when the Game is Okey, or when the Match is decided. Okey falls out of the free-seat rule; nothing in the code should name Gonga.
- [x] Adding before any Round has been scored appends the Entrant directly on zero, which is the same rule rather than a second one: with no Rounds, the highest total still in *is* zero.
- [x] Undoing the Round a join sits on removes the join with it. The Entrant remains seated but is omitted from Standings — an accepted orphan, so ADR 0006's "Entrants cannot be removed from a Match" stays a flat rule rather than a conditional one.
- [x] Scoresheet Rounds before a join carry **no entry** for the joiner, distinguishable from a zero delta, and render as an em-dash.
- [x] The join Round renders the joiner's entering total the way a Rejoin does today; later Rounds carry ordinary deltas.
- [x] Names go through the same validator as Rename, including Turkish-locale uniqueness and the blank-to-seat-fallback rule.
- [x] A Match containing a join survives a full store round-trip with the event and the added Entrant intact, seat included. Prior art: `MatchStorePersistenceTests`.
- [x] Snapshot coverage for the Add row with its preview, and for its absence in each of the three hidden cases.

## Comments

Delivered on `feature/live-roster-edits`. 411 tests, 0 failures.

The one new seam is `RosterAddition` — the Add row's whole offer, and its
whole gate. It answers `nil` when there is no seat to give away, which is
what hides the row rather than disabling it, and it carries the seat and
the total together so the row and the sheet cannot quote different
numbers. The total is `SurvivalEngine.rejoinTarget` called directly, not
reimplemented, so the cap and the everyone-busted fallback come along
unchanged.

**Two deviations from the ticket, both deliberate.**

The first is the Okey rule. The ticket says "Okey falls out of the
free-seat rule", and that is only true of `okeyStandard`, which seats
exactly two teams. `okey101` has `maxEntrants: 4` and is played by two to
four individuals, so a free-seat gate alone would have shown the Add row
on a three-handed Okey 101. The gate implemented instead is that the
Match must be able to say what a newcomer starts on, which only Survival
can — a Match counting down, or one racing a fixed number of Rounds, has
no highest total still in to inherit. That covers both Okey Variants,
still names no Game, and is asserted by
`test_thereIsNoOfferOnAnOkey101MatchEvenWithSeatsToSpare`. The ticket line
is the half that was wrong.

The second is `Entrant.arrivedMidMatch`, a new stored property that the
ticket did not ask for and that turned out to be load-bearing. Ticket 04
derived "who arrived later" from the `JoinEvent`s on the Match's Rounds.
Undo removes the Round and the JoinEvent with it — which is exactly what
this ticket asks Undo to do — and at that point nothing was left to
distinguish the joiner from someone seated at Setup, so they came back as
a ranked player on zero rather than as the omitted orphan the ticket
calls for. The Entrant now records *that* they arrived, which no Undo
takes back; the Round still records *where*, which Undo still takes with
it. The reconciliation between the two sits in `Match`'s designated
initializer, so no way of building a Match can lose an arrival.

Both review axes independently found the same weak invariant — the
stamping living in only one of the two initializers — and it is fixed
above rather than carried.

**Carried to 06.** `CONTEXT.md` gains no vocabulary here: "arrival", the
seat as distinct from a Round's sequence, and the fact that a join and a
Rejoin land on one shared target are documented only in code. The
**Entrant** glossary entry also still reads as though a roster is fixed at
Setup. `SiraSchema.swift` now carries a note that version 1.0.0 has
absorbed two additive defaulted properties — `Round.joins` from 04 and
`Entrant.arrivedMidMatch` from here — and that a third is the point to cut
a v2 rather than a third run of luck. There is no migration test.

**Accepted, and worth knowing.** After the Undo that orphans a joiner,
Play's subtitle still counts them ("3 players"), because that phrase is
shared verbatim with Home's card and reads off the roster rather than the
Standings. Fixing it in Play alone would split the two.
