# 07 — Bad data never blocks launch

**What to build:** Sıra opens even when its stored data cannot be read, and nothing it fails to understand is ever destroyed. A player whose store is corrupt gets a working, empty app rather than one that won't start, and their old data is still on the device.

Demoable by corrupting the store by hand and launching.

**Blocked by:** 06

**Status:** ready-for-human

- [x] The container is built explicitly rather than through the convenience that crashes the app on failure
- [x] A store that cannot be opened is moved aside under a timestamped name and a fresh one opened; the app launches normally
- [x] Data that could not be read is never deleted — after recovery it is still present under its moved-aside name
- [x] There is no silent in-memory fallback: the app must never look like it is working while saving nothing
- [x] A stored Match naming a Variant id that resolves to nothing is skipped, and its stored data is left untouched
- [x] Skipping one such Match leaves every other Match loading and scoring normally
- [x] Tests cover both recovery paths: an unopenable store yields a working empty store with the old data still present, and an unknown Variant id is skipped with its data still on disk

## Comments

**2026-08-20** — Landed. Full suite green at 224 tests with no snapshot re-recorded, and the Release build checked too.

Three notes for a reader:

**Recovery is one extra chance, not a fallback.** `MatchStore.init(recoveringAt:)` opens the store; if it can't, it moves the files aside under `Sira-unreadable-<stamp>.store` and opens a fresh one in their place. `forApp()` now goes through it. The `fatalError` is still there but means something much narrower than before: the store could not be opened *and* could not be replaced, which is a device that isn't writable. There is deliberately no in-memory fallback — `test_aRecoveredStoreWritesToTheDeviceRatherThanFallingBackToMemory` writes a Match after recovering and finds it on the launch after that, which is what would fail if one were ever added.

**Moving aside takes the sidecars.** SQLite keeps `-wal` and `-shm` files beside the store, and they are as much the data as the store file is — leaving them behind would hand the fresh store the tail of the old one. The timestamp carries milliseconds so that two recoveries in quick succession cannot collide on a name and turn a recoverable launch into a failed one.

**The unknown-Variant rule was already in Home; it now has a name.** `HomeView` was skipping unresolvable Matches with an inline `compactMap`, so the behaviour existed but was a view detail no test could reach. It is now `Sequence<Match>.scorable`, applied in exactly one place and asserted through the same function the app calls. Nothing about the stored Match changes — a skipped Match keeps its Entrants and its Rounds on disk, which is what the test checks after a relaunch.

Worth carrying to **ticket 10**: with skipping named and pinned here, and Home the only route into Play, an unscorable Match still cannot reach a live `Navigator`. 10 looks like a test rather than new behaviour, as its own checklist predicted.

**2026-08-20 (review)** — Two-axis review run against this ticket and the spec. No hard standards violation and no material scope creep; both axes independently caught the same thing, which is that two comments claimed more than the code delivered. Findings taken:

- **A name collision could have failed the very launch this exists to rescue.** The comment said a millisecond stamp meant two recoveries "cannot collide"; in fact a collision would make `moveItem` throw, and that error travels straight out to `forApp()`'s `fatalError`. The name is now checked against the directory and disambiguated if taken, so the claim is enforced rather than asserted. Other move failures — an unwritable device — still abort the launch, which is documented as the honest outcome: nothing can be moved out of the way, so nothing can be safely put in its place either.
- **The sidecars were moved but never tested.** The only corruption fixture wrote a bare `Sira.store`, so two thirds of that loop never ran. A test now writes `-wal` and `-shm` alongside and proves all three are set aside together. It asserts by **content**, not by absence: the fresh store immediately creates sidecars of its own at exactly those paths, so "the file is gone" is not a fact this test can check — the first draft of it failed for precisely that reason. A second test recovers twice and finds both sets of data still there.
- **"Never scored under a substitute" was not the domain's guarantee to make.** `SurvivalEngine` and friends will happily score a Match whose Variant is `nil` against `?? .max`, because there is nothing else for them to read. `scorable`'s doc now says what is actually true — it is a gate that keeps such a Match away from every screen, not an invariant the Engines enforce — and points at ticket 10 for the one route that does not come through it. That weakens the hand-off note above: **ticket 10 should confirm rather than assume** that `PlayView` is unreachable for an unscorable Match.
- Renames for honesty: `for sidecar in ["", "-wal", "-shm"]` called the store file a sidecar, and is now `storeFileSuffixes` with the empty case explained; `unreadableStamp` is a formatter and is now `unreadableNameFormatter`; one test named an internal design choice ("rather than falling back to memory") and now names what a player would see.

Not taken, with reasons: the `(match:, variant:)` tuple was called a type waiting to be born — it is, but it predates this ticket in `HomeView` and two of its three consumers are tests, which is not domain pressure; a third real caller should force it. `MatchStoreRecoveryTests` duplicates `MatchStorePersistenceTests`'s temporary-directory and `launch(_:)` shape — deliberately, because the two suites tell different launch stories (relaunching versus recovering) and a shared base would couple them at exactly the point one of them is meant to vary.

One correction to the checklist: the first box — the container being built explicitly rather than through `.modelContainer(for:)` — was already true before this ticket, having landed with the conversion in 05. It is ticked as a statement of the state of the code, not as work done here.

Also worth stating plainly: no automated test covers `forApp()` or `defaultStoreURL()` themselves, since they name a real Application Support directory. The recovery they perform is tested through `init(recoveringAt:)`; that the app wires them together is left to the manual demo the ticket describes.
