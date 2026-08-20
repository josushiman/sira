# 11 — Entrant order is not guaranteed once a Match is loaded

**What to build:** Whatever it takes for a Match's Entrants to come back in the order they were entered at Setup — most likely the same treatment Rounds got in ticket 03, an explicit integer on `Entrant` assigned at Setup and sorted on read.

**Raised by:** ticket 05, during the SwiftData conversion. Not fixed there because it is a schema field the ticket did not ask for, and because nothing can observe it while the container is in memory.

**Blocked by:** None — but it must land no later than 06, which is the ticket that first puts Entrants on disk.

**Status:** needs-triage

## Why this is a real problem

Ticket 03 gave Rounds an explicit sequence precisely because "a to-many relationship array is not a dependable ordering guarantee". `Match.entrants` is now exactly such an array, and nothing was done about it.

Round order was load-bearing for every total in the app, which is why it was worth a prefactor of its own. Entrant order is load-bearing for less, but not for nothing:

- `PlayView.badgeIndex(for:)` reads an Entrant's position in `match.entrants` to pick its dot-badge colour, and `keypadRoundEntry` builds `badgeIndices` the same way. If the array comes back in a different order, Alice is blue one launch and red the next, in a Match whose scores are unchanged.
- Setup writes the names top to bottom, so the entered order is the order the player expects to see.

Scoring itself is safe: Standings are sorted by Out-then-total, Elimination picks the winning team by id rather than by position, and every per-Entrant score is keyed by `Entrant.ID` rather than by index. So this is a cosmetic bug, not a wrong tally — which is why it is being filed rather than fixed inside 05.

## Why it is invisible today

Ticket 05 runs the app on an in-memory container that is populated in one session and never reloaded, so the array order is simply the insertion order and the snapshot suites pass unchanged. The first launch that reads Entrants back off disk is the first chance for this to appear, and it may well appear intermittently rather than on every load — the worst kind to chase later.

- [ ] A Match's Entrants come back in the order they were entered at Setup
- [ ] Whatever carries that order is part of schema v1, not a later migration — the same "do it while it is free" reasoning as tickets 01 and 44
- [ ] A test that writes a Match with enough Entrants for an accidental reordering to be visible, discards the store, reads it back and asserts the order
- [ ] Dot-badge colours are stable for a Match across a reload
