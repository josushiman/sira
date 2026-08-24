Status: ready-for-agent

# Customisable Variants — one number, chosen at Setup

## Problem Statement

Sıra ships four Variants and every number in them is welded shut. Gonga is played to 101 or to 151 and nothing else; Okey 21 counts down from 21 and nothing else; Okey 101 runs 8 Rounds or 12 and nothing else.

Real tables do not play that way. A group that plays Gonga to 201 because the evening is long, or to 51 because it is short, has no way to say so. They either pick the nearest shipped Variant and keep the real limit in their heads — which is exactly the arguing the app exists to end — or they do not use the app.

The shape of the app makes the gap look bigger than it is. Gonga 101 and Gonga 151 are two whole Variants that differ by a single integer: same Win Condition, same Entrant mode, same eight-player maximum, same absence of Çifte, same keypad entry. The Variant Picker presents them as a choice of rules when it is a choice of number. Meanwhile Okey 101 already proves the number can be a Setup choice rather than a rule — its 8-or-12 Round count is picked at Setup and stored on the Match — but that route exists for exactly one Variant and offers exactly two values.

So the codebase currently says two contradictory things. `CONTEXT.md` says a Game is "a fixed, small set (extending it means adding code, not data)" and that Variants number four, while `Match.roundCount` already lets one Variant's defining number come from data.

## Solution

A Variant stops carrying values and carries only shape. Every Variant takes exactly one number, chosen at Setup, and the Match records it.

Three Variants replace the four:

- **Gonga** (`gonga-standard`) — Survival. Choose the limit: 101, 151, or Custom.
- **Okey** (`okey-standard`) — Elimination. Choose the starting score: 21 or Custom.
- **Okey 101** (`okey-101`) — Fixed Rounds. Choose the Round count: 8, 12, or Custom.

Gonga 101 and Gonga 151 collapse into one Gonga whose limit is a Setup choice. Okey 21 is renamed to Okey — id, label, types and glossary together — because the number in its name is no longer fixed and a name that quotes a value it no longer guarantees is worse than no name.

Setup gains one control, the same in all three: a row of chips ending in **Custom**, which reveals a numeric field. The stock value is preselected, so the common path is unchanged — open Setup, type names, Start. A rule blurb under the control restates the rules using the number currently selected, so choosing 201 immediately reads back "Go over 201 and you're Out."

Because Gonga now has a single Variant, tapping Gonga on Home goes straight to Setup. A picker offering one card is a tap that asks a question with one answer.

The chosen number is shown wherever a Match is named, as a phrase alongside the label rather than fused into it: `8 players · to 201` on the Home card, the same phrase under Play's header. A Gonga Match to 101 and a Gonga Match to 201 are never mistaken for each other.

## User Stories

1. As a Gonga player whose table plays to 201, I want to enter 201 at Setup, so that the app tracks the game we actually play instead of the nearest one it ships.
2. As a Gonga player, I want 101 already selected when Setup opens, so that the most common game costs me no extra taps.
3. As a Gonga player, I want 151 available as a chip, so that the second-most-common game is one tap and not a typing exercise.
4. As a Gonga player, I want a Custom option beside the presets, so that an unusual limit is possible without making the usual ones slower.
5. As a Gonga player who picks Custom, I want a number field to appear, so that I can type the limit my table agreed on.
6. As a Gonga player, I want the app to refuse an impossible limit rather than accept it, so that I find out at Setup and not three Rounds in.
7. As a Gonga player, I want to see "Go over 201 and you're Out" after choosing 201, so that I can confirm the app understood me before the first Round.
8. As a Gonga player, I want tapping Gonga on Home to take me straight to Setup, so that I am not asked to choose between a list of one.
9. As a Gonga player, I want up to 8 players as before, so that squashing two Variants into one has not quietly shrunk my table.
10. As a Gonga player, I want the Rejoin offer to work exactly as before at any limit, so that a custom limit does not change what happens when someone goes Out.
11. As a Gonga player, I want Room left to count against my chosen limit, so that Closest to out means something at 201 as much as at 101.
12. As an Okey player, I want to choose the score we count down from, so that a shorter or longer countdown is possible.
13. As an Okey player, I want 21 preselected, so that the standard game is still the default and not something I have to opt back into.
14. As an Okey player, I want the losing team to still take −2 per Round whatever the starting score, so that changing the length has not changed the game.
15. As an Okey player, I want each Gösterge find to still deduct 1, so that the find is worth the same at any starting score.
16. As an Okey player, I want 0 to remain the finish line, so that "first team to reach 0 loses" still describes what happens.
17. As an Okey player, I want the Variant called Okey rather than Okey 21, so that its name does not quote a number I have just changed.
18. As an Okey 101 player, I want to enter a Round count other than 8 or 12, so that a five-Round session is trackable.
19. As an Okey 101 player, I want 12 preselected, so that the longer game — the one my table plays — is the default.
20. As an Okey 101 player, I want 8 still available as a chip, so that the shorter game stays a single tap.
21. As an Okey 101 player, I want Rounds left on the Play screen to count against my chosen Round count, so that the tile tells me the truth.
22. As an Okey 101 player, I want the Match to end when my chosen Rounds run out, so that a custom count is a real rule and not a label.
23. As an Okey 101 player, I want the "never laid down" shortcut to stay 101, so that changing the Round count has not changed the scoring.
24. As a player of any Variant, I want the number fixed once the Match starts, so that a mid-Match change cannot retroactively un-Out someone who already declined to Rejoin.
25. As a player, I want the Start button disabled while my number is out of range, so that I cannot start a Match that cannot be played.
26. As a player, I want to be told why Start is disabled, so that I can fix the number instead of guessing.
27. As a player, I want an out-of-range number left alone rather than silently corrected, so that the app never starts a Match at a number I did not choose.
28. As a player, I want the number I chose shown on the Home card, so that two Matches of the same Variant at different numbers are told apart at a glance.
29. As a player, I want the number phrased as "to 201", "from 21" or "12 rounds", so that I can tell a limit from a starting score from a Round count without being told which Variant I am looking at.
30. As a player, I want the number shown beside the Variant's name rather than built into it, so that the Variant is always called the same thing.
31. As a player, I want the number visible on the Play screen too, so that I do not have to leave the Match to remember what we are playing to.
32. As a player, I want a Match's number to survive the app closing, so that a custom game is not silently rescored against a stock value on relaunch.
33. As a player, I want every Match to record the number it was played at, even a stock one, so that the history is unambiguous about what was agreed.
34. As a player, I want Çifte, Okey atmak and Gösterge to behave exactly as they do today, so that the only thing this change alters is how long the Match runs.
35. As a player, I want the Scoresheet and Undo to work identically at a custom number, so that the number is the only thing that varies.
36. As a player of Okey, I want the picker to still offer Okey and Okey 101 as separate cards, so that the two genuinely different Okey games stay distinguishable.
37. As a first-time player, I want the Variant Picker card to describe the rules without quoting a number I have not chosen yet, so that the card does not promise a value Setup is about to ask me for.

## Implementation Decisions

### Variants describe shape, never values

`Variant` keeps `id`, `game`, `label`, `winCondition`, `entrantMode`, `maxEntrants`, `supportsCifte`, `entryStyle` and `neverLaidDownValue`. Its `limit`, `startingScore` and `roundCount` become `nil` on every Variant — they are no longer rules the binary owns.

This narrows rather than contradicts ADR 0007. The Variant id remains the frozen persistence contract and still resolves everything about how a Match is *scored*; what it no longer resolves is *how far* the Match runs, which was never a rule the app could correct on the player's behalf. A limit is a table decision, not a bug that a later release might fix.

The three shipped Variants become `gonga-standard`, `okey-standard` and `okey-101`. `gonga-101`, `gonga-151` and `okey-21` cease to exist, with no legacy resolution: nothing is stored on any device (no release tags, `SiraSchemaV1` still at 1.0.0, an empty `SiraMigrationPlan`, and ADR 0007 records the last id rename as happening "before any data existed"), so there is nothing to migrate. `gonga-standard` is named for the slot rather than the number so a genuinely different Gonga ruleset can be added later without the id lying.

### The Match owns the number

`Match` gains three named optionals mirroring the Variant fields they supply — a limit, a starting score and a Round count — joining the `roundCount` that already exists for this purpose. Exactly one is non-`nil` for any given Match, determined by its Variant's Win Condition. Three named fields rather than one generic number, because a generic field would be meaningless-but-present on the two Variants it does not describe, and `Match.variant` already resolves a Setup choice this way.

The number is **always** stored, including when it is the preselected value. A Match is then self-describing: nothing has to reason about whether a stored value means "the player chose this" or "nothing was chosen." It also means the number can never be retroactively changed by a release, which is the intended behaviour — a Match played to 101 stays a Match played to 101 even if the preselected default later moves.

### One resolved accessor, no scattered fallbacks

Every read of the number goes through a single accessor on `Match` that resolves the Variant and its number together. Today four places each invent their own fallback and each would silently produce a nonsense Match rather than fail:

- `SurvivalEngine` resolves the limit as `?? .max` — an Entrant can never go Out.
- `PlayView` resolves the limit as `?? 0` for its bars and its Room left rows.
- `PlayStats` resolves the limit as `?? 0` for Closest to out and the Round count as `?? 0` for Rounds left.

The accessor returns `nil` when the Variant or its number cannot be resolved, and an unresolvable Match is skipped exactly as a Match with an unknown Variant id is today — the `scorable` / `scorableMatch` gate already established by ADR 0007. Skipped, never scored against a substitute, and never deleted.

### `VariantParameter` — the new seam

One view-independent value type in the domain layer holds everything about the number a Variant takes: which kind it is (limit, starting score, Round count), the preset chip values, which is preselected, the legal range, whether a given value is startable, the reason it is not, and the display phrase. Modelled directly on `RoundEntryState` — a struct that owns interactive state and its rules with no SwiftUI involved, tested by driving it directly.

It serves three surfaces from one definition, which is why it is worth introducing rather than leaving the logic in `SetupView`'s `@State`:

| Variant | Kind | Chips | Preselected | Range | Phrase |
|---|---|---|---|---|---|
| Gonga | limit | 101, 151, Custom | 101 | 11–999 | `to 201` |
| Okey | starting score | 21, Custom | 21 | 2–99 | `from 21` |
| Okey 101 | Round count | 8, 12, Custom | 12 | 1–50 | `12 rounds` |

Out-of-range values are never clamped. The value is left as typed, Start is disabled, and the reason is shown inline.

### Setup

One control pattern for all three Variants: a `ChipSelector` whose final chip is Custom, revealing a numeric field when selected. Choosing a preset chip after typing a custom value returns to the preset.

A rule blurb sits under the control and is derived from the current selection, restating the Variant's rules with the number substituted in. This replaces `Variant.ruleText` as a stored string — the text is now a function of the chosen number, because a static sentence quoting 101 is wrong the moment 201 is picked. All three Variants show it at Setup; the two Okey Variants keep their Picker card text as well, phrased without quoting a number the player has not yet chosen.

Entrant counts are untouched: Gonga up to 8 players, Okey exactly 2 teams, Okey 101 up to 4 players, each still fixed by the Variant's `entrantMode` rather than offered as a choice.

### Navigation

Home routes Gonga directly to Setup, bypassing `VariantPickerView`. Okey still routes to the Picker, which shows two cards. `VariantCard`'s muted numeric tag is removed entirely: the Picker runs before Setup, so no number has been chosen and the tag could only ever show decoration — and after this change it would show a value the player is about to be asked for.

### Display

The Variant's label and the chosen number never fuse. The label is "Gonga", "Okey" or "Okey 101" in every context. The number rides alongside as a phrase in the metadata line — `HomeCard`'s entrants line becomes `8 players · to 201`, and Play's header carries the same phrase under the label. The phrase form is what distinguishes a limit from a starting score from a Round count, so no separate unit label is needed.

### Renames

`okey-21` becomes `okey-standard` throughout, id included, superseding ADR 0007's original `okey-standard` → `okey-21` rename. That rename existed to fix an id that did not match its label; with the label no longer a number, the reasoning inverts.

Swift identifiers follow: `Variant.okeyStandard`, `RoundEntryStyle.okeyStandard`, `OkeyStandardRoundEntryView` and its snapshot suite. Deliberately not `Variant.okey` or `RoundEntryStyle.okey` — `Game.okey` already exists, and two `okey` members one type apart is a collision that reads fine on the day it is written and gets misresolved later. The user-facing label is "Okey"; the identifier stays qualified.

### Documentation

`CONTEXT.md` needs its **Game**, **Variant** and **Gösterge** entries rewritten. Two statements become false — "A fixed, small set (extending it means adding code, not data)" and "Four exist: Gonga 101, Gonga 151, Okey 21, Okey 101" — and **Gösterge** is described as "an Okey-21-only find." **Win Condition** and **Room left** both name Variants by their old labels and need the same pass. `VariantParameter` earns a new entry.

One new ADR: Variants carry shape and Matches carry values; ids are slots rather than descriptions; and the `okey-21` rename is reverted. It supersedes ADR 0007 in part — 0007's central decision, that a Match stores an id rather than a copy of its rules, survives intact.

No schema v2 and no migration stage, on the recorded assumption that nothing is stored on any device.

## Testing Decisions

A good test here asserts **observable behaviour** — a total, a Standing, whether Start is offered, what a card reads — not the shape of the code producing it. It does not assert that a particular field is `nil`, except where that nullity is itself the contract (`VariantTests` on the Variant constants), and it does not reach past the accessor to check how a number was resolved.

**Five existing seams, one new one.** No seam is added for Setup's view, for navigation, or for the rule blurb's text assembly.

### `Variant.all(for:)` and the constants → `VariantTests`

Prior art: this suite already asserts each id explicitly, which ADR 0007 requires so that a future tidy-up fails the suite rather than orphaning data. Coverage: the three ids are exactly `gonga-standard`, `okey-standard`, `okey-101`; Gonga resolves one Variant and Okey two, in Picker order; `limit`, `startingScore` and `roundCount` are `nil` on all three; entrant modes, maxima, Çifte support and entry styles are unchanged from what the four Variants declared.

### Number resolution → `MatchTests`

Prior art, and the closest: `MatchTests` already asserts that `variantId: "gonga-101"` resolves a limit of 101 and that a Setup `roundCount` of 12 overrides the constant. Those tests become the tests for the new accessor with inverted expectations. Coverage: a Match resolves the number it stores, for each of the three kinds; a Match storing no number resolves `nil` rather than a substitute; a Match naming an unknown Variant id still resolves `nil`; `scorable` and `scorableMatch` skip a Match whose number is unresolvable exactly as they skip an unknown id, and leave it stored.

### Scoring → `SurvivalEngineTests`, `EliminationEngineTests`, `FixedRoundsEngineTests`

Prior art: all three already build a Match from `Round` fixtures and assert per-Entrant totals. Coverage: an Entrant goes Out by passing a custom Gonga limit and not before; the Rejoin target is computed correctly at a custom limit; a custom Okey starting score counts down to 0 with the losing team still taking −2 and Gösterge still deducting 1; a custom Okey 101 Round count ends the Match on the right Round; Çifte, Okey atmak and their stacking are unchanged at custom numbers. Critically, the `?? .max` regression: a Match with no resolvable limit must not reach an Engine at all, which is asserted at the `scorable` gate rather than by giving the Engine a substitute.

### Play's tiles → `PlayStatsTests`

Coverage: Room left and Closest to out compute against a custom Gonga limit; Rounds left computes against a custom Okey 101 Round count; the Elimination Gap tile is unaffected by the starting score.

### Home's card → `HomeCardTests`

Coverage: the metadata line reads `8 players · to 201` for Gonga, `from 21` for Okey and `12 rounds` for Okey 101; the label field is the bare Variant label in every case, never fused with the number.

### `VariantParameter` → new `VariantParameterTests`

The one new seam. Prior art: `RoundEntryStateTests`, which drives its struct directly with no view. Coverage: each Variant offers the right chips with the right one preselected; selecting a preset yields that value; selecting Custom and entering a value yields that value; returning to a preset after a custom entry discards the custom value; boundary values at each end of each range are startable and the values just outside are not; an out-of-range value is preserved rather than clamped; a non-startable state supplies a reason; the display phrase is correct for each kind.

### Snapshots

`SetupViewSnapshotTests`, `VariantPickerViewSnapshotTests`, `HomeViewSnapshotTests` and `PlayViewSnapshotTests` all need re-recording per ADR 0004, in the same change rather than after it. `Okey21RoundEntryViewSnapshotTests` is renamed with its subject. New cases: Setup with a preset selected and with Custom revealed, in both themes; Setup in a non-startable state; a Home list containing two Matches of the same Variant at different numbers. These assert appearance only — no rule is verified by a snapshot.

## Out of Scope

- **Changing a Match's number after it has started.** The number is fixed at Setup. Editing it mid-Match can retroactively un-Out an Entrant who already declined to Rejoin, and the Rejoin offer that was declined does not come back — Standings recompute from the Rounds, so the Out simply vanishes. That needs its own history semantics and is a separate feature.
- **A second customisable value per Variant.** Exactly one number each. Opening a second knob turns this from "same game, different length" into a rules editor.
- **Making Çifte, Gösterge, Okey atmak or Rejoin configurable.** Every rule other than the number is inherited from the Variant unchanged, including the −2 per losing Round and the −1 per Gösterge find, which do not scale with a custom starting score.
- **Configurable entrant counts.** Gonga stays at 8 players, Okey at exactly 2 teams, Okey 101 at 4 players, each fixed by the Variant.
- **A configurable Elimination finish line.** 0 stays the floor; only the starting score moves.
- **A configurable "never laid down" value.** Okey 101's shortcut stays 101 regardless of Round count.
- **Adding new Variants.** Three, replacing four. `gonga-standard` is named to leave room for a future second Gonga ruleset, but adding one is not part of this.
- **Migration or legacy id resolution.** Conditional on nothing being stored on any device — see Further Notes.
- **Paywalling custom values.** Decided free, and decided now rather than shipped free and clawed back.

## Further Notes

**The one standing assumption.** This spec deletes three Variant ids outright. That is safe only if no Match anywhere names one. The evidence is that no release tags exist, `SiraSchemaV1` is still at version 1.0.0 with an empty `SiraMigrationPlan`, and ADR 0007 records the previous id rename as having happened "before any data existed." If a device somewhere holds real Matches, this changes materially: `gonga-101`, `gonga-151` and `okey-21` must all stay resolvable, mapping onto the new Variants with their old numbers supplied as the Match's stored value, and a schema v2 with a migration stage is required. **Confirm before deleting the ids.** The failure mode is quiet — an unresolvable Match is skipped, not reported, so the player sees a game silently missing from Home with no explanation.

**Why the label was not allowed to absorb the number.** An earlier reading derived the display name from the chosen number: "Gonga 201", "Okey 31". Applied to the stock case it renders "Okey 21" — resurrecting the exact name being retired, on the most common Match in the app. Showing the base label for default values and a derived name otherwise is worse still: the same Match type renders under two naming schemes depending on a value, which makes 21 secretly special again immediately after the work to make it ordinary. Label and number stay separate everywhere.

**Why `VariantParameter` and not `Target` or `Distance`.** *Target* is wrong for Okey, where 21 is the origin and 0 is the target. *Distance* fits all three honestly and reads better against the existing glossary, but **Room left** is already a per-Entrant distance measured against exactly this number, and two "distances" one hop apart in the same glossary is how vocabulary rots.

**Gonga's asymmetry is deliberate.** Okey keeps its Picker and Gonga does not. This looks inconsistent and is honest: Okey has two Variants with genuinely different Win Conditions, and Gonga has one with a dial.

**"Okey" beside "Okey 101" is accepted as-is.** The Okey Picker reads Okey / Okey 101, directly under an "Okey" heading. It is what players call the games, and inventing a disambiguator would re-introduce the naming problem this change removes.
