# 03 — Setup screen reskin

**What to build:** A player setting up a new Match sees the prototype's Setup screen: a mode toggle (where the Variant allows choosing Players vs. Teams), chip-based entrant/round-count pickers, dot-badge name rows, and a full-width Start button — replacing the current `Form`-based screen.

**Blocked by:** 01 — Design-system foundation + Home reskin.

**Status:** ready-for-agent

- [ ] Players/Teams mode toggle renders as the shared pill-track component (from ticket 01), shown only when the Variant allows choosing mode (not shown for teams-only Variants like Okey standard).
- [ ] Entrant-count choice (2/3/4) and, for Okey 101, round-count choice (8/12) render as the shared chip-selector component instead of `Add Entrant`/`Remove Entrant` buttons and a segmented `Picker`.
- [ ] Each entrant/team name field renders as a row with a dot-badge initial, inline text field, and placeholder hint, using the shared card-row and dot-badge components.
- [ ] "Start Match" renders as a full-width dark button matching the prototype, instead of a default `Form` button row.
- [ ] Starting a Match with default (untouched) name fields still falls back to "Entrant N"/"Team N" naming, matching current behavior.
- [ ] Snapshot tests exist for Setup in both Paper and Felt, covering: a Players-mode Variant (Gonga), a Teams-only Variant (Okey standard), and an Okey 101 setup showing the round-count chips.
