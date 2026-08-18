# 03 — Undo

**What to build:** Let the player remove the most recently saved Round, with every downstream computation — totals, Out status, and any Rejoin — recalculating as if that Round never happened.

**Blocked by:** 02 — Rejoin

**Status:** ready-for-agent

- [ ] An Undo action is available on the Play screen whenever the Match has at least one Round
- [ ] Undo removes the last Round (including any Rejoin event attached to it) and standings recompute immediately
- [ ] Undo correctly reverses an Entrant going Out, and correctly reverses a Rejoin if the undone Round is the one that triggered it
- [ ] Undo is implemented generically against `Standings`/`Round` (not Survival-specific), so later Engines inherit it without extra work
- [ ] Tests assert `Standings` before appending a Round and after appending-then-undoing it are identical
