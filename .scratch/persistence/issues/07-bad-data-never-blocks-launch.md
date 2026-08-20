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
