# 08 — Investigate intermittent unresponsive taps on primary buttons

**What to build:** Not a fix yet — this needs on-device reproduction before a fix can be scoped. The user reports that on a real device, tapping name-entry fields (Setup's team/player name rows), Start Match, and Add round N scores sometimes does nothing, "as if the whole button is not selectable," and that buttons generally look like they could be bigger.

**Blocked by:** None, but needs a device to reproduce — this can't be confirmed from source alone.

**Status:** needs-info

- [ ] Reproduce on a physical device (not just Simulator) and note: does it happen right after the keyboard dismisses/appears, right after a `safeAreaInset` layout change, or with no clear trigger?
- [ ] Check whether missed taps correlate with `ScrollView` scroll-gesture recognition stealing quick/light taps near the Start Match / Add round buttons, which sit in `.safeAreaInset(edge: .bottom)` in `SetupView.swift` and `PlayView.swift`
- [ ] Once reproduced, confirm whether `.contentShape(Rectangle())` (already added defensively to both buttons in this pass) resolves it, or whether the cause is elsewhere (gesture conflict, keyboard-avoidance timing, etc.)

## Comments

Reported by the user while triaging a batch of UI bugs (2026-08-19): "The buttons look like they need to maybe be bigger. Sometimes clicking on them doesn't have any action. That's mainly on adding team names or people, as well as the Start Match button and Add Round Scores button."

In this pass: added `.contentShape(Rectangle())` to the Start Match button (`SetupView.swift`) and the Add round N scores button (`PlayView.swift`) to close one plausible hit-testing gap (SwiftUI's default tap region can undershoot a shape-only `.background()` at rounded corners), and bumped `PillTrack`'s tab height (Players/Teams, Standings/Scoresheet) from ~39pt to ~44pt to meet Apple's minimum tap target. Neither change is confirmed to be the actual cause — this ticket exists to track a real repro.
