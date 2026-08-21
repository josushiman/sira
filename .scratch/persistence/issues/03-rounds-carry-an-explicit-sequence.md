# 03 — Rounds carry an explicit sequence

**What to build:** A Round knows where it sits in its Match, rather than that being implied by its position in an array. Nothing a player can see changes — but once Rounds come back from a database, order is no longer something the language guarantees, and every total in the app depends on it.

Prefactoring: this lands while the domain types are still value types, so the SwiftData conversion in ticket 05 cannot quietly change scoring by reordering Rounds.

**Blocked by:** None — can start immediately

**Status:** ready-for-human

- [x] A Round carries an integer sequence, assigned when it is added to its Match
- [x] Everything that reads a Match's Rounds in order does so by that sequence, never by array position
- [x] Undo frees the highest sequence, and the next Round added takes it again — no renumbering, since only the last Round is ever removed
- [x] Cumulative totals, the delta from the last Round, Scoresheet row numbering and Match summaries all read identically before and after, for every Win Condition
- [x] A test proves order is carried by the sequence and not by position: a Match whose Rounds are held out of order still scores and reads in sequence order
- [x] Full suite green; snapshots re-recorded only if nothing visual moved
