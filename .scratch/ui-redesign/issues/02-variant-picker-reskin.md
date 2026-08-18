# 02 — Variant picker reskin

**What to build:** A player who tapped a Game card on Home sees that Game's Variants rendered as the prototype's cards, rather than a plain list.

**Blocked by:** 01 — Design-system foundation + Home reskin.

**Status:** ready-for-agent

- [ ] Each Variant (e.g. Gonga 101/151, Okey standard, Okey 101) renders as the prototype's card: label, tag, and rule text, using the shared card-row component and typography/color tokens from ticket 01.
- [ ] Navigation into `VariantPickerView` (from Home's Game cards) and out of it (into `SetupView`) is unchanged — native `NavigationStack`/back-swipe.
- [ ] Snapshot tests exist for the Variant picker in both Paper and Felt, for a Game with two Variants (Gonga) and a Game with a teams-only Variant (Okey).
