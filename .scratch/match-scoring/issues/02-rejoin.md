# 02 — Rejoin

**What to build:** When an Entrant goes Out, offer them a Rejoin instead of silently ending their participation. Accepting re-enters them at the highest score still held by any Entrant still in; declining is permanent for the rest of the Match.

**Blocked by:** 01 — Walking skeleton: play a Gonga Match start-to-finish

**Status:** ready-for-agent

- [ ] The moment `SurvivalEngine` reports a newly-Out Entrant (Out this call, not Out on the prior call), the UI presents a Rejoin sheet for that Entrant
- [ ] Accepting Rejoin sets that Entrant's total to the highest score currently held by any Entrant still in, and clears their Out status
- [ ] Declining ("They're out") leaves the Entrant permanently Out for the rest of the Match — no further Rejoin offers for them
- [ ] The Rejoin event is recorded against the Round that triggered it (not as a mutation of history), so future Undo can reverse it cleanly
- [ ] `SurvivalEngineTests` cover: accepting a Rejoin resets total and Out correctly; declining leaves the Entrant Out; a second pass over the limit after rejoining offers Rejoin again
