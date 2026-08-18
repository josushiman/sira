# 01 — Walking skeleton: play a Gonga Match start-to-finish

**What to build:** The thinnest possible end-to-end journey: from the app's home screen, start a Gonga Match, name the Entrants, play Rounds by entering keypad scores, watch standings update live, and see a clear Match-over banner once someone wins. One Game (Gonga), one Variant (pick either 101 or 151 — hardcode which), no theming polish, no filters/archive, no Scoresheet tab, no Undo, no Çifte, no Rejoin. Going Out is terminal for this ticket (Rejoin lands in ticket 02).

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `Game`, `Variant`, `Entrant`, `Round`, `Match`, and `Standings` types exist, matching the vocabulary in `CONTEXT.md`
- [ ] A `SurvivalEngine` computes `Standings` from a `Match`: accumulates each Entrant's total across Rounds, marks an Entrant Out once their total exceeds the Variant's limit, and reports the Match over once exactly one Entrant remains not-Out, with a plain-language result
- [ ] Home screen can start a new Gonga Match
- [ ] Setup screen collects Entrant names (2–4 players)
- [ ] Play screen's Standings view shows each Entrant's current total, ranked, with Out Entrants visibly marked
- [ ] Keypad Round entry lets the player enter each Entrant's Round score and save it
- [ ] Saving a Round updates standings immediately
- [ ] Match-over banner appears with the winner once the Win Condition is met, and no further Rounds can be entered
- [ ] Unit tests for `SurvivalEngine` cover: accumulation, an Entrant crossing the limit, and the Match ending with the correct winner
