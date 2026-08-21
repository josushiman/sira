# 06 — Matches survive the app closing

**What to build:** The point of the spec. Start a Match, enter some Rounds, kill the app from the app switcher, reopen it — the Match is on Home with its Entrants, its Rounds in order, and the same totals. And a player opening Sıra for the first time sees an empty Home rather than two strangers' games.

**Blocked by:** 05

**Status:** ready-for-human

- [x] Matches are stored on the device and loaded at launch
- [x] Every mutation is followed by an explicit save rather than left to the framework's own schedule: adding a Round, accepting or declining a Rejoin, archiving, restoring and undoing all persist immediately
- [x] A failed save keeps the in-memory state, tells the player, and never crashes mid-Match
- [x] First launch shows an empty Home; the seeded Alice/Bob and Alice/Carol Matches move to previews and view tests, keeping their fixed 2026 dates so snapshots stay stable
- [x] Previews run against an in-memory container carrying those fixtures
- [x] Round trip: a Match comes back with its Game, Variant, Entrant mode, Entrants and Archived flag intact
- [x] Round trip: Rounds return in entry order, proven with enough Rounds that a reordering would be visible
- [x] Round trip: Çifte callers, the Okey atan, the losing Entrant, the Gösterge finder, raw deltas and Rejoins all survive
- [x] Round trip: Standings after reloading equal Standings before — across Survival, Elimination and Fixed Rounds, including an Entrant who is Out and a Match that is already over
- [x] Round trip: Okey 101's Setup-chosen Round count survives, so the Match still ends when it should
- [x] Round trip: Undo after a reload removes the last Round and nothing else
- [x] Tests needing real storage use a temporary location per test; tests needing only a database use an in-memory configuration
- [x] Snapshot: an empty Home on first launch, in both themes — a state the app has never been able to show

## Comments

**2026-08-20** — Landed. Full suite green at 217 tests, with **no snapshot re-recorded**.

Three things worth a reader's attention:

**Ticket 11 landed inside this one, because saving made it fail.** With saves in place, `PlayViewSnapshotTests` went red on 7 of 8 cases: identical scores, but Alice's and Bob's dot-badge colours had swapped. That is exactly the reordering ticket 11 predicted — `context.save()` is enough to change the order of a relationship array, so the bug was never waiting for a relaunch. `Entrant` now carries a `sequence` stamped at Setup, `Match.storedEntrants` is the unordered relationship and `Match.entrants` sorts by seat, mirroring what ticket 03 did for Rounds. The snapshots went green again untouched, which is the evidence that the seating restored is the seating that was there before. Ticket 11's own checkboxes are ticked there.

**The save seam is injected.** `MatchStore` takes its save operation as a closure defaulting to `try $0.save()`, because SwiftData gives no way to make a real save fail on demand and "the disk is full" is the case worth pinning down. A failed save records a `SaveFailure`, keeps every pending change in memory, and the root view raises one alert wherever the player is standing.

**A Match cannot outlive its store.** Reading a Match through a `MatchStore` that has already been released traps inside SwiftData rather than reporting an error — the container's context is reset out from under it. `MatchStorePersistenceTests.launch(_:)` therefore hands the store to a closure and lets only value types back out, which is what stops a test from re-setting that trap. Worth knowing before ticket 08 writes more store-lifecycle tests.

Two things deliberately left for the tickets that own them: the app still crashes rather than recovering when the store cannot be opened (07 — the `fatalError` is in `MatchStore.forApp()` with a pointer to it), and an unresolvable Variant id is still `nil` at the point of use rather than being skipped at load (07).

**2026-08-20 (review)** — Two-axis review run against this ticket and the spec. Spec axis found no material creep and confirmed ticket 11's inclusion as forced rather than opportunistic; standards axis found no hard violation of any ADR, and confirmed the Engines still score without a database. Findings taken:

- **The fixtures shipped in the release binary.** Both axes caught it: `MatchStore.seeded()` lived in the app target with nothing but convention keeping Alice and Bob off a real player's Home. Now `#if DEBUG`. Worth knowing for next time: `#Preview` bodies are compiled in **every** configuration, so Home's fixture-backed previews needed the same guard — the Release build failed until they got it, and a Release build is now part of what "green" means for this branch.
- **Autosave is stated rather than assumed.** The spec says autosave stays on as a backstop; nothing said so in code. `MatchStore.init` now sets `autosaveEnabled` explicitly.
- **`SaveFailure` was `Identifiable` for nobody** — the alert presents on a `Bool` binding, so the `id` was dead weight. Gone, along with the redundant second `acknowledgeSaveFailure()` in the alert's button.
- **A declined Rejoin had no test.** The ticket asks for declining to persist immediately; declining correctly stores *nothing*, because being Out is what the already-saved Round says. That absence is now pinned by a test, so nobody later "fixes" a decline into a stored fact.

Not taken, with reasons: `sequence` / `withSequence(_:)` now exists on both `Round` and `Entrant` and was called Duplicated Code, but a protocol cannot own the `private(set)` stored property that makes the stamp unforgeable, and the two doc comments carry different reasoning — revisit at a third model rather than abstracting two. The storage-shaped `Match.init(storedEntrants:storedRounds:)` accepts unstamped objects and was called a latent trap; it is the initialiser whose stated contract is "already carry their sequence", `Round` has had the same shape since ticket 03, and its only caller is the test fixture that deliberately shuffles storage order.

One correction to the checklist above: the empty-Home snapshots in both themes were already recorded in ticket 05's commit, so that box credits earlier work rather than anything added here.
