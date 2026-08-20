# 06 — Matches survive the app closing

**What to build:** The point of the spec. Start a Match, enter some Rounds, kill the app from the app switcher, reopen it — the Match is on Home with its Entrants, its Rounds in order, and the same totals. And a player opening Sıra for the first time sees an empty Home rather than two strangers' games.

**Blocked by:** 05

**Status:** ready-for-agent

- [ ] Matches are stored on the device and loaded at launch
- [ ] Every mutation is followed by an explicit save rather than left to the framework's own schedule: adding a Round, accepting or declining a Rejoin, archiving, restoring and undoing all persist immediately
- [ ] A failed save keeps the in-memory state, tells the player, and never crashes mid-Match
- [ ] First launch shows an empty Home; the seeded Alice/Bob and Alice/Carol Matches move to previews and view tests, keeping their fixed 2026 dates so snapshots stay stable
- [ ] Previews run against an in-memory container carrying those fixtures
- [ ] Round trip: a Match comes back with its Game, Variant, Entrant mode, Entrants and Archived flag intact
- [ ] Round trip: Rounds return in entry order, proven with enough Rounds that a reordering would be visible
- [ ] Round trip: Çifte callers, the Okey atan, the losing Entrant, the Gösterge finder, raw deltas and Rejoins all survive
- [ ] Round trip: Standings after reloading equal Standings before — across Survival, Elimination and Fixed Rounds, including an Entrant who is Out and a Match that is already over
- [ ] Round trip: Okey 101's Setup-chosen Round count survives, so the Match still ends when it should
- [ ] Round trip: Undo after a reload removes the last Round and nothing else
- [ ] Tests needing real storage use a temporary location per test; tests needing only a database use an in-memory configuration
- [ ] Snapshot: an empty Home on first launch, in both themes — a state the app has never been able to show
