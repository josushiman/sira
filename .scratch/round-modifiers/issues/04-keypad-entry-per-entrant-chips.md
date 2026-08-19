# 04 — Keypad Round entry: per-Entrant Çifte and Okey attı chips

**What to build:** The keypad entry screen (Gonga 101/151, Okey 101) gains two chips that act on the **active row**, matching the convention `Won the round · 0` already establishes.

**Blocked by:** 03 — Okey atmak across all three Engines

**Status:** ready-for-agent

The chip row today is `[ Won the round · 0 ] [ Never laid down · 101 ] [ Çifte — double all ×2 ]`. The Çifte chip stops being Round-wide and becomes per-Entrant; a new joker-finish chip joins it.

- [ ] `Çifte` toggles the **active** Entrant's caller status, and lights when the active row is a caller
- [ ] Tapping `Çifte` again on the same row un-marks that caller
- [ ] The Çifte chip is shown only where the Variant supports it — Gonga still never sees it
- [ ] `Okey attı` / `Jokeri attı` marks the active Entrant as the Okey atan **and** sets their entered value to 0
- [ ] The marker is exclusive: applying it to another row moves it rather than adding a second
- [ ] Tapping it on the current atan clears the marker
- [ ] The joker-finish chip is shown for **every** Variant, including Gonga
- [ ] The label is chosen from the Match's Game: "Okey attı" in Okey, "Jokeri attı" in Gonga
- [ ] Each row's meta line extends from `now 34   ×2 → 68` to express ×4, and marks which rows are callers or the atan
- [ ] Modifier state is per-Round — none of it carries into the next Round's entry
- [ ] `RoundEntryState` grows the selection state and preview arithmetic; **what it hands to `onSave` stays raw** for every combination of modifiers
- [ ] `RoundEntryStateTests` cover: exclusivity of the atan, clearing on re-tap, the implied 0, per-Entrant Çifte toggling, ×2 and ×4 previews, and raw output
- [ ] `RoundEntryViewSnapshotTests` gain cases in both themes, including a Gonga Round showing `Jokeri attı` with no Çifte chip, and a row previewing ×4
- [ ] Existing snapshots re-recorded where the chip row's layout shifts

**Rejected alternative:** a separate "who called Çifte?" picker section below the rows — more explicit, but it breaks the active-row convention, adds a second place to look, and pushes a four-player Okey 101 Round into scrolling.
