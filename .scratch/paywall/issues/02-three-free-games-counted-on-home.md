# 02 — Three free games, counted on Home

**What to build:** The player can see how many of their three free games are left, and watch the count rise as they play. Nothing is blocked yet — this ticket only makes the limit visible, so that when the wall arrives in ticket 03 it is something the player watched approaching rather than something that ambushed them.

**Blocked by:** 01

**Status:** done

- [x] A monotonic count of Started Matches is stored alongside the Matches, and is what the free-game limit is measured against
- [x] It increments as a Match Starts, in the same save as the Round that caused it, so the two can never disagree
- [x] Nothing decrements it: undoing a Round, deleting a Match and archiving one all leave it exactly where it was
- [x] It survives a relaunch, proved the way persistence already proves things — a second store opened over the same file, as in `MatchStorePersistenceTests`
- [x] A fresh store starts with three free games, which is the reinstall case and is deliberate: the count is not hidden in the Keychain to survive the app being deleted
- [x] A save that fails while the count changes surfaces through the existing `SaveFailure` path and the change stands in memory, following `test_aDeletionThatCannotBeSavedIsSurfacedAndStillStands`
- [x] Home shows the free-game meter beside the "Your games" heading, filling as games are consumed
- [x] The meter reads as "free games left" the first time it is seen, without becoming chrome that dominates the screen — the treatment is resolved in the Claude Design project rather than invented in code
- [x] The meter is not called `pip` or `dots` in code: `pip` is already the playing-card pip colour and `dots` is already the Entrant badge palette
- [x] `CONTEXT.md` gains a **Free Match** entry, defined against **Started**, with an _Avoid_ line against "trial" and "credit"
- [x] Snapshot: Home with zero, one, two and three free games consumed, in both themes
