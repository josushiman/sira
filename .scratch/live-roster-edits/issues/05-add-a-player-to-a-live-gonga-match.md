# 05 — Add a player to a live Gonga Match

**What to build:** Someone arrives two Rounds into a Gonga Match and there's a free seat. A dashed **Add player** row at the foot of the Standings list adds them without abandoning the Match. Before committing, the row previews the score they'd start on — "joins on 61" — so the table can agree the number out loud. The new player enters on **the highest total among Entrants still in**, takes the next free seat, keeps that seat's dot-badge colour for the rest of the Match, and is scored from that Round onward like everyone else.

The Scoresheet tells the truth about them: Rounds played before they arrived show an em-dash, not a zero, because they weren't at the table. Their join Round renders the way a **Rejoin** does, because the two are the same kind of event.

A join is recorded against the latest Round, which means **Undo** reverses a mistaken add exactly as it reverses a mistaken score.

**Blocked by:** 02 (the name validator), 04 (the Engine's join-Round rule).

**Status:** ready-for-agent

- [ ] The Add row appears at the foot of the Standings list on a live Gonga Match with a free seat, and adding a player scores them from that Round onward.
- [ ] The joiner enters on the highest total among Entrants **still in**. Entrants who are **Out** are excluded from that maximum — an Out Entrant typically holds the highest total on the table, and inheriting it could start the newcomer beyond everyone actually playing, or even Out.
- [ ] The entering total reuses the existing Rejoin target rather than a parallel implementation, and keeps its cap at the Match's limit and its everyone-busted fallback.
- [ ] The previewed number is derived at render time, not cached when the screen opens: it moves as Rounds are scored and as Entrants go Out, with the sheet still on screen.
- [ ] The joiner is stamped with the next free seat; no existing Entrant's seat moves.
- [ ] Adding is refused at the Variant's maximum, and the Add row is **hidden entirely** — never shown-and-disabled — when the table is full, when the Game is Okey, or when the Match is decided. Okey falls out of the free-seat rule; nothing in the code should name Gonga.
- [ ] Adding before any Round has been scored appends the Entrant directly on zero, which is the same rule rather than a second one: with no Rounds, the highest total still in *is* zero.
- [ ] Undoing the Round a join sits on removes the join with it. The Entrant remains seated but is omitted from Standings — an accepted orphan, so ADR 0006's "Entrants cannot be removed from a Match" stays a flat rule rather than a conditional one.
- [ ] Scoresheet Rounds before a join carry **no entry** for the joiner, distinguishable from a zero delta, and render as an em-dash.
- [ ] The join Round renders the joiner's entering total the way a Rejoin does today; later Rounds carry ordinary deltas.
- [ ] Names go through the same validator as Rename, including Turkish-locale uniqueness and the blank-to-seat-fallback rule.
- [ ] A Match containing a join survives a full store round-trip with the event and the added Entrant intact, seat included. Prior art: `MatchStorePersistenceTests`.
- [ ] Snapshot coverage for the Add row with its preview, and for its absence in each of the three hidden cases.
