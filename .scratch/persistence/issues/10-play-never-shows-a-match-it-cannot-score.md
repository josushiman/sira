# 10 — Play never shows a Match it cannot score

**What to build:** A guarantee that the Play screen is never left standing in front of a Match it has no rules for. Today, if `Navigator` names a Match whose Variant id resolves to nothing, `PlayView` renders nothing at all — and because Play hides the navigation bar and keeps its own back button inside the header it didn't render, the result is a blank screen with no way off it.

This is the same instinct the spec already states for deletion — "the app can never present a Match that no longer exists" — applied to the other way a Match can stop being presentable.

**Blocked by:** 07, 08

**Status:** ready-for-human

- [x] A Match that cannot be scored is never presented by Play: the player lands on Home instead of a blank screen
- [x] That holds for both ways it can arise — a Variant id that resolves to nothing, and a Match deleted while it was open
- [x] The player is never stranded: whatever Play shows in this state, there is always a way back to Home
- [x] **Check first whether tickets 07 and 08 already deliver this.** 07 skips unresolvable Matches at load, so one should never reach a live `Navigator`; 08 clears a `Navigator` naming a deleted Match. If both hold, the remaining work is a test that pins the guarantee, not new behaviour — and this ticket closes as `wontfix` if it turns out to be fully redundant
- [x] A test covers a `Navigator` naming a Match Play cannot score

## Comments

Raised by the `/code-review` Spec axis while reviewing tickets 01–02. Not fixed there: ticket 02's `PlayView` guard is already structurally unreachable, because Home skips unresolvable Matches and so can't open one, and Setup only ever creates a Match from a Variant it is holding. Deferred here rather than fixed early, since 07 and 08 own both of the paths that would make it reachable.

**Not redundant — the check found a real gap, so this did not close as `wontfix`.** 07 turned out to skip unresolvable Matches at *display* rather than at load: they stay in the store deliberately (ADR 0007 — never deleted, so a downgrade stays recoverable), and Home filters them out of its list with `.scorable`. But Home's `navigationDestination` resolved the route's id against every stored Match, not the filtered ones, so a route naming an unresolvable Match still built `PlayView` — whose body draws nothing when the Variant doesn't resolve. That is exactly the blank screen described above, and nothing pinned it. 08's half held: a route naming a deleted Match was already cleared and tested.

The fix resolves that one route through a new `scorableMatch(_:)`, which returns nothing for either cause, and drops the route when it does — landing the player on Home rather than pushing a screen with nothing on it. `closeDeletedMatch` became `closeMatch`, since the remedy is the same whichever way the Match stopped being presentable and a second near-identical method would only have duplicated it.
