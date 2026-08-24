# 03 — Gonga becomes one Variant with a chosen limit

**What to build:** A Gonga table that plays to 201 can say so. Gonga 101 and Gonga 151 stop being two Variants — they differ by a single integer and are identical in Win Condition, Entrant mode, eight-player maximum, absence of Çifte and keypad entry. They become one Gonga whose limit is chosen at Setup: chips `101 · 151 · Custom`, 101 preselected, custom range 11–999.

Because Gonga now has a single Variant, tapping Gonga on Home goes straight to Setup. A Picker offering one card is a tap that asks a question with one answer.

Play to 201 and an Entrant goes Out on passing 201 and not before; Room left counts against 201; Closest to out means what it says; the Rejoin offer works exactly as it does at 101. Home reads `8 players · to 201`.

The ids `gonga-101` and `gonga-151` are deleted outright and replaced by `gonga-standard`, labelled "Gonga". No legacy resolution and no migration — see the gate below. `gonga-standard` names the slot rather than the number, so a genuinely different Gonga ruleset can be added later without the id lying.

**Blocked by:** 02.

> **Gate before starting:** this deletes two Variant ids. That is safe only if no Match anywhere names one. The evidence is no release tags, `SiraSchemaV1` still at 1.0.0 with an empty `SiraMigrationPlan`, and ADR 0007 recording the previous id rename as happening "before any data existed". **Confirm with the user that nothing is stored on any device before deleting the ids.** If data does exist, both old ids must stay resolvable — mapping onto Gonga with their old limits supplied as the Match's stored number — and a schema v2 with a migration stage is required. The failure mode is quiet: an unresolvable Match is skipped rather than reported, so the player sees a game silently missing from Home with no explanation.

**Status:** done

- [x] One Gonga Variant, id `gonga-standard`, labelled "Gonga"; `gonga-101` and `gonga-151` no longer exist
- [x] Setup offers `101 · 151 · Custom` with 101 preselected, and a limit of 11–999 starts a Match
- [x] Out of range disables Start with a visible reason and leaves the entered value untouched
- [x] Tapping Gonga on Home lands on Setup, not the Variant Picker
- [x] Gonga still seats up to 8 players
- [x] An Entrant goes Out on passing the chosen limit and not before; Rejoin is offered and works identically at any limit
- [x] Room left and Closest to out count against the chosen limit
- [x] Setup's rule blurb reads back the chosen limit — "Go over 201 and you're Out"
- [x] Home's card and Play's header show `to 201` in the metadata line
- [x] `SurvivalEngineTests` covers going Out at a custom limit and the Rejoin target computed from it; `PlayStatsTests` covers Room left and Closest to out against it
- [x] `VariantTests` asserts the Gonga id explicitly, as ADR 0007 requires
- [x] Affected snapshot suites re-recorded per ADR 0004, in this ticket
