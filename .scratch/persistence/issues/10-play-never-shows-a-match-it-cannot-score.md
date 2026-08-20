# 10 — Play never shows a Match it cannot score

**What to build:** A guarantee that the Play screen is never left standing in front of a Match it has no rules for. Today, if `Navigator` names a Match whose Variant id resolves to nothing, `PlayView` renders nothing at all — and because Play hides the navigation bar and keeps its own back button inside the header it didn't render, the result is a blank screen with no way off it.

This is the same instinct the spec already states for deletion — "the app can never present a Match that no longer exists" — applied to the other way a Match can stop being presentable.

**Blocked by:** 07, 08

**Status:** ready-for-agent

- [ ] A Match that cannot be scored is never presented by Play: the player lands on Home instead of a blank screen
- [ ] That holds for both ways it can arise — a Variant id that resolves to nothing, and a Match deleted while it was open
- [ ] The player is never stranded: whatever Play shows in this state, there is always a way back to Home
- [ ] **Check first whether tickets 07 and 08 already deliver this.** 07 skips unresolvable Matches at load, so one should never reach a live `Navigator`; 08 clears a `Navigator` naming a deleted Match. If both hold, the remaining work is a test that pins the guarantee, not new behaviour — and this ticket closes as `wontfix` if it turns out to be fully redundant
- [ ] A test covers a `Navigator` naming a Match Play cannot score

## Comments

Raised by the `/code-review` Spec axis while reviewing tickets 01–02. Not fixed there: ticket 02's `PlayView` guard is already structurally unreachable, because Home skips unresolvable Matches and so can't open one, and Setup only ever creates a Match from a Variant it is holding. Deferred here rather than fixed early, since 07 and 08 own both of the paths that would make it reachable.
