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

**The check, and what it found.** 07 turned out to skip unresolvable Matches at *display* rather than at load: they stay in the store deliberately (ADR 0007 — never deleted, so a downgrade stays recoverable), and Home filters them out of its list with `.scorable`. But Home's `navigationDestination` resolved the route's id against every stored Match, not the filtered ones, so a route naming an unresolvable Match would have built `PlayView` — whose body draws nothing when the Variant doesn't resolve. 08's half held as described: a route naming a deleted Match was already cleared and tested.

**How reachable that was, honestly:** not at all, today. `openMatchID` is assigned in exactly one place, inside the `ForEach` over `filteredMatches`, which is already `.scorable` — so an unscorable Match has no card to tap. `Navigator` is in-memory only, so no route survives a relaunch, and a Match's Variant cannot stop resolving mid-session. The gap was one unfiltered lookup, not a live bug.

So the ticket's own rule — "the remaining work is a test that pins the guarantee, not new behaviour" — arguably pointed at a test alone. The `/code-review` Spec axis said exactly that, and it has a point. What shipped is a middle course: the route now resolves through `scorableMatch(_:)` in the binding that feeds the destination, so an unscorable id is never presented in the first place. That is one expression, it is the same expression the new tests exercise, and it turns "unreachable because no caller happens to do that" into "unreachable because the gate says so" — which is what the ticket's title asks for. A reviewer who wants the stricter reading should revert `scorableMatch` and keep the tests; nothing else depends on it.

**One correction to the premise above.** "Play hides the navigation bar and keeps its own back button inside the header it didn't render, the result is a blank screen with no way off it" overstates it: `.toolbar(.hidden, for: .navigationBar)` is applied inside `play(_:)`, the branch that only runs once the Variant *has* resolved. On the unresolved branch it never applies, so the pushed screen keeps its default back button. The blank screen was real; being stranded on it was not.

An earlier draft dropped the route from inside the destination with an `onAppear`, which pushed a blank screen and popped it again, and renamed `closeDeletedMatch` to `closeMatch` to serve that branch. Both are gone: gating the binding means nothing is ever pushed, and with the branch gone deletion is once again the only caller, so ticket 08's method keeps its name.
