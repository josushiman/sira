# 06 — Round-entry reskin: Okey-standard

**What to build:** A player adding a round to an Okey-standard Match gets the prototype's entry screen: a full-screen push showing the losing-team choice as two full-width team cards and Gösterge finds as per-team stepper rows — replacing the current `Form` with a segmented `Picker` and native `Stepper`s.

**Blocked by:** 01 — Design-system foundation + Home reskin.

**Status:** ready-for-agent

- [ ] `OkeyStandardRoundEntryView` is invoked via a full-screen push from Play's "Add Round" action instead of `.sheet`, with a Cancel/Save top bar matching the prototype.
- [ ] The losing-team choice renders as two full-width team cards, with a checkmark on the selected one, instead of a segmented `Picker`.
- [ ] Gösterge finds render as a per-team `–`/count/`+` stepper row instead of native `Stepper`s in a `Form` section.
- [ ] Çifte renders as the prototype's chip styling.
- [ ] Saving produces the same result as today: the selected team's −2 penalty, doubled by Çifte if on; Gösterge deductions (1 point off the other team per find) unaffected by Çifte — no change to `EliminationEngine` behavior.
- [ ] Snapshot tests exist for the Okey-standard entry screen in both Paper and Felt, covering: no team selected, a team selected with Gösterge finds > 0, and Çifte on.
