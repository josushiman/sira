# 04 — Play screen reskin

**What to build:** A player in an active Match sees the prototype's Play screen: a pill-track Standings/Scoresheet toggle, restyled Standings rows with stat tiles, a restyled Scoresheet table, and restyled Undo/Archive/match-over chrome — replacing the current segmented `Picker` and plain `List`/`Grid`.

**Blocked by:** 01 — Design-system foundation + Home reskin.

**Status:** ready-for-agent

- [ ] Standings/Scoresheet toggle renders as the shared pill-track component instead of a segmented `Picker`.
- [ ] Each Standings row renders per the prototype: rank, dot badge, name, LEADS/OUT tag, progress bar, score, and delta — instead of a plain `List` row with strikethrough.
- [ ] The two stat tiles (Leader/Result, and Room-left/Rounds-left/Gap depending on Win Condition) render above or alongside Standings, matching the prototype.
- [ ] The "Match over" state renders as the prototype's accent-colored banner instead of a plain green-tinted `Text`.
- [ ] The Scoresheet table (Rd/Tot columns, right-aligned mono deltas) is restyled to match the prototype instead of a generic scrollable `Grid`.
- [ ] Undo and Archive controls are restyled to match the prototype's chrome; their behavior (disabled Undo with no Rounds, disabled Add Round once the Match is over) is unchanged.
- [ ] Snapshot tests exist for Play in both Paper and Felt, covering: Standings tab (mid-Match and Match-over states), and Scoresheet tab.
