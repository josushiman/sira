# 04 — Persist to disk, durably

**What to build:** The point of the spec. Matches are stored on the device, saved after every mutation, and loaded at launch. First launch is empty, and an unreadable store never stops the app from opening.

**Blocked by:** 03 — The domain types become SwiftData models

**Status:** ready-for-agent

- [ ] The container is built explicitly against on-disk storage, not via the `.modelContainer(for:)` convenience, which `fatalError`s on failure
- [ ] Every mutation is followed by an explicit save; autosave stays enabled as a backstop
- [ ] A failed save keeps the in-memory state, surfaces the failure to the player, and never crashes mid-Match
- [ ] Adding a Round, accepting or declining a Rejoin, archiving, restoring and undoing all persist immediately
- [ ] First launch shows an empty Home; `seeded()` becomes the fixture builder for previews and view tests, keeping its fixed 2026 dates
- [ ] Previews get an in-memory container carrying the seeded fixtures
- [ ] A store that cannot be opened is moved aside to a timestamped name and a fresh one opened, so the app launches and the old data survives for recovery — never a `fatalError`, never a silent in-memory fallback
- [ ] A Match whose stored Variant id cannot be resolved is skipped and its data left untouched on disk
- [ ] Round-trip test: write through a store, discard it, rebuild over the same storage, and assert the Match's Game, Variant, Entrant mode, Entrants and Archived flag came back
- [ ] Round-trip test: Rounds return in entry order, with enough Rounds that a reordering would be visible
- [ ] Round-trip test: Çifte callers, Okey atan, losing Entrant, Gösterge finder, raw deltas and Rejoins all survive
- [ ] Round-trip test: Standings after a reload equal Standings before the store was discarded, across Survival, Elimination and Fixed Rounds — including an Entrant who is Out and a Match that is over
- [ ] Round-trip test: Okey 101's Setup-chosen Round count survives, so the Match still ends when it should
- [ ] Round-trip test: Undo after a reload removes the last Round and nothing else
- [ ] Test: an unopenable store yields a working empty store, with the unreadable data still present under its moved-aside name
- [ ] Test: a stored Match naming an unknown Variant id is skipped and its data is still on disk afterwards
- [ ] Tests needing real storage use a temporary location per test; tests needing only a database use an in-memory configuration
- [ ] Snapshot: an empty Home on first launch, in both themes — a state the app has never been able to show
