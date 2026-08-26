# 06 — The unstarted sweep runs from a view initialiser

**Type:** task

**Status:** ready-for-agent

**What's wrong:** `MatchStore.forApp()` deletes every Match with no Rounds — `discardUnstartedMatches()`, added with ticket 01 so that a Match set up and never scored is tidied away rather than left unreachable. It is called from `ContentView.init()` (`sira/ContentView.swift:27`).

A view's `init` is not a place with a guaranteed number of runs. `ContentView` is the `WindowGroup`'s root, so in practice it is built once and a re-evaluation is uncommon — this is exposure rather than a reproduction. But every re-run opens a second `ModelContainer` over the same `Sira.store` and sweeps again, and what the sweep now deletes is data. Before ticket 01 a second init wasted a container; now it can take a Match with it.

The concrete loss: a player is in Setup or Play on a Match that `store.add(match)` has already saved and no Round has been entered against yet. That Match has no Rounds, so a sweep deletes it out from under the live screen.

Separately and definitely: `#Preview { ContentView() }` at `sira/ContentView.swift:86` runs the sweep against the real on-disk store in the preview simulator. That one needs no re-evaluation to happen — opening the preview is enough.

**Found by:** `/code-review high` on `feature/paywall-01-started`, 2026-08-26. Reported alongside four findings in `UnlockStore` and `HomeView`, all three of the accepted ones fixed on that branch; this was left out because it belongs to ticket 01's launch path rather than the paywall, and a destructive sweep deserves its own change.

**What to do**

- [ ] The sweep runs once per launch, at scene setup, rather than wherever a view happens to be initialised — an explicit one-shot, or a flag on the store that makes a second call a no-op
- [ ] Opening a SwiftUI preview cannot delete anything from the player's real store
- [ ] A Match that has been Started but not yet scored is never swept, whatever the sweep is called from — this is the case that turns a tidy-up into data loss
- [ ] Covered by a test that calls the launch path twice over the same store and asserts what survives

**Worth deciding while in there:** whether `forApp()` should have a destructive side effect at all, or whether the sweep should be a named call the app makes deliberately. A factory that quietly deletes is a factory whose name does not say what it does.
