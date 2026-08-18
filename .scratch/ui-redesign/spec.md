Status: ready-for-agent

# Reskin the app to match the Claude Design prototype

## Problem Statement

The app's screens (Home, game/variant pickers, Setup, Play, round entry, Scoresheet) are built from stock SwiftUI controls — `List`, segmented `Picker`, `Form`, `ContentUnavailableView` — with no distinct visual identity. A full design has already been prototyped in Claude Design (`Card Scores.dc.html`, referenced from `[[design-prototype]]` memory) covering every one of these screens with custom typography, color themes, and components, but none of it has been carried over into the native app. The user wants the shipped app to look and feel like that prototype, not like a generic SwiftUI form.

## Solution

Introduce a shared design-system layer (color tokens, typography scale, and reusable components — pill tabs, chip selectors, dot badges, card rows, custom keypad, bottom sheet) modeled directly on the prototype's own component vocabulary, then reskin each screen onto it in the prototype's own flow order. Two structural flow changes are folded in at the same time because the prototype specifies them directly: game-picking moves inline onto Home (removing a screen), and round-score entry becomes an all-entrants-visible view with a tap-to-focus active row (replacing the current one-entrant-at-a-time flow). Native iOS conventions (`NavigationStack`, back-swipe, Dynamic Type, system light/dark) are kept underneath the prototype's visual skin rather than porting its hand-rolled state machine and fixed-pixel sizing literally — see `docs/adr/0003-native-navigation-and-type-scaling-over-literal-port.md`.

## User Stories

1. As a player opening the app, I want the Home screen to show the two Games (Gonga, Okey) as inline cards styled like the prototype, so that I can start a new Match without navigating through an extra "pick a game" screen.
2. As a player, I want tapping a Game card to take me directly to that Game's Variant picker, so that starting a Match takes one fewer tap than today.
3. As a player, I want my list of Matches on Home styled as the prototype's cards (badge, title, pill status, leader line, dashed divider) instead of a plain `List` row, so that the Home screen matches the design.
4. As a player, I want the Active/All/Archived filter shown as the prototype's pill row instead of a segmented `Picker`, so that filtering matches the design.
5. As a player, I want the empty state (no Matches for the current filter) styled like the prototype's centered dim text instead of `ContentUnavailableView`, so that the empty state matches the design.
6. As a player, I want swipe-to-archive/restore kept exactly as it works today (no visible inline Archive/Restore button, per explicit decision), so that existing muscle memory for archiving isn't disrupted.
7. As a player picking a Variant, I want each Variant shown as the prototype's card (label, tag, rule text) instead of a plain `List` row, so that the Variant picker matches the design.
8. As a player setting up a Match, I want the Players/Teams mode toggle shown as the prototype's pill track instead of nothing/implicit, when the Variant allows choosing mode.
9. As a player setting up a Match, I want the entrant-count and round-count choices (2/3/4 entrants; 8/12 rounds for Okey 101) shown as the prototype's chip row instead of `Add Entrant`/`Remove Entrant` buttons and a segmented `Picker`.
10. As a player setting up a Match, I want each entrant's name field styled as the prototype's row (dot-badge initial, inline text field, placeholder hint) instead of a plain `TextField` in a `Form` section.
11. As a player, I want "Start Match" styled as the prototype's full-width dark button instead of a default `Form` button row.
12. As a player in an active Match, I want the Standings/Scoresheet toggle shown as the prototype's pill track instead of a segmented `Picker`.
13. As a player viewing Standings, I want each Entrant's row styled as the prototype's row (rank, dot badge, name, LEADS/OUT tag, progress bar, score, delta) instead of a plain `List` row with strikethrough.
14. As a player viewing Standings, I want the two stat tiles (Leader/Result and Room-left/Rounds-left/Gap) shown as the prototype specifies, giving me an at-a-glance summary beyond just the ranked list.
15. As a player, I want the "Match over" state styled as the prototype's accent-colored banner instead of a plain green-tinted `Text`.
16. As a player viewing the Scoresheet, I want the round-by-round table styled as the prototype's table (Rd/Tot columns, right-aligned mono deltas) instead of a generic scrollable `Grid`.
17. As a player starting a new round, I want a full-screen "Add round" entry view (matching the prototype's Cancel/Save top bar) instead of a `.sheet`.
18. As a player entering a Survival or Fixed Rounds round, I want to see every still-in Entrant listed at once with their current total, tap any row to make it "active," and type into a shared keypad that fills whichever row is active — instead of being forced through them one at a time via Next/Save Round.
19. As a player entering a Survival or Fixed Rounds round, I want the same quick-entry shortcuts as the prototype ("Won the round · 0", and "Never laid down · 101" where the Variant offers it) available per active row.
20. As a player entering a Survival or Fixed Rounds round, I want the custom on-screen keypad (digits, `⌫`, quick shortcuts) restyled to match the prototype's tile look, keeping the existing custom-keypad approach rather than switching to the system number pad.
21. As a player entering an Okey-standard round, I want the losing-team picker shown as the prototype's two full-width team cards (with a checkmark on the selected one) instead of a segmented `Picker`.
22. As a player entering an Okey-standard round, I want Gösterge finds shown as the prototype's per-team stepper row (`–`/count/`+`) instead of a `Stepper` list.
23. As a player toggling Çifte during round entry, I want it shown as the prototype's chip/toggle styling, and its doubling effect (previewed live, e.g. "×2 → 24") reflected in the entry UI exactly as the prototype shows it — with the Elimination (Okey standard) exception preserved, where Çifte doubles only the losing team's −2 penalty and never affects Gösterge deductions.
24. As a player who has just gone Out, I want the Rejoin offer shown as a bottom sheet with the prototype's copy and button styling (its own slide-up feel, via a native sheet) instead of the current plain `.sheet` with `.medium` detent.
25. As a player, I want the app's color palette to follow my iOS Appearance setting automatically — light mode uses the prototype's "Paper" palette, dark mode uses its "Felt" palette — with no in-app theme picker or override, and no Night/Clay palettes.
26. As a player, I want all of the prototype's display text (headlines, labels) rendered in Bricolage Grotesque and all numeric/mono text (scores, labels, tags) rendered in IBM Plex Mono, bundled into the app.
27. As a player using a larger iOS text-size (accessibility) setting, I want the redesigned screens to scale their text via Dynamic Type rather than clipping or staying visually fixed at the prototype's literal pixel sizes.
28. As a developer maintaining this app, I want a single shared design-system layer (color tokens per appearance, a typography scale, and the reusable prototype components) so that no screen re-implements the same pill/chip/card styling independently.
29. As a developer maintaining this app, I want each screen's reskin to land as its own short-lived branch/PR (per `docs/agents/gitflow.md`), tracked as its own ticket under `.scratch/ui-redesign/issues/`, so review stays incremental rather than one large PR.
30. As a developer maintaining this app, I want the reskin's newly introduced interactive state (e.g. round-entry's active-row selection, theme→token resolution) modeled as plain, testable types rather than embedded directly in view bodies, consistent with how `Match`/engines are tested today.

## Implementation Decisions

- **Fonts**: Bundle Bricolage Grotesque (weights 400/500/600/800) and IBM Plex Mono (400/500/600) as app font assets (both OFL-licensed); register via Info.plist. See `docs/adr/0001-bundle-brand-fonts.md`.
- **Theming**: Exactly two color-token sets, resolved from the prototype's `THEMES.pad` ("Paper") and `THEMES.felt` ("Felt") objects — background, surface, ink, line, track, accent, accent2, onAccent, tile, tileInk, cardFace, cardBack, pip, and a rotating dot-badge palette. Paper is used when the system is in light mode, Felt when in dark mode; resolution happens via the environment's color scheme, with no persisted preference and no picker UI. Night and Clay token sets from the prototype are not implemented. See `docs/adr/0002-two-system-driven-themes.md`.
- **Design-system layer**: Built once, shared by all screens, before any screen is reskinned. Covers: color tokens (per above), a typography scale mapping the prototype's display/label/mono text roles onto scalable SwiftUI text styles (Dynamic Type-friendly, preserving the prototype's relative hierarchy rather than its literal point sizes), and reusable components mirroring the prototype's own vocabulary: pill-track tabs (used for Players/Teams and Standings/Scoresheet), chip selectors (used for entrant/round counts and quick-entry shortcuts), dot badges (entrant initials, colored by index from the theme's rotating palette), card rows (Home match list, Variant picker, name-entry rows, standings rows), a bottom-sheet container (Rejoin), and the custom numeric keypad.
- **Navigation**: Native `NavigationStack` and `NavigationLink` throughout — no port of the prototype's own `screen` state machine. Screen chrome (custom back-chevron button, colors, fonts) is restyled to match the prototype visually. See `docs/adr/0003-native-navigation-and-type-scaling-over-literal-port.md`.
- **Screen flow change — Home absorbs game picking**: `GamePickerView` is deleted. The two Game cards (Gonga, Okey) render inline on `HomeView`, above the Match list, exactly where the prototype places them; tapping one navigates directly to `VariantPickerView`.
- **Screen flow change — round entry is a full-screen push**: `RoundEntryView` and `OkeyStandardRoundEntryView` are presented via `NavigationLink`/push instead of `.sheet`, with a Cancel/Save top bar matching the prototype's entry screen chrome.
- **Round-entry rework (Survival/Fixed Rounds)**: Replace the current one-entrant-at-a-time state machine (`index`, single `digits` buffer, Next/Save Round) with a state shape that holds a value per still-in Entrant plus one "active" Entrant ID; tapping any entrant row sets it active; the shared keypad and quick-entry shortcuts always write into the currently active Entrant's value; Save is enabled once at least one value has been entered (matching the prototype's "ready" check). Preserve existing save semantics: entered values become that round's per-Entrant deltas, doubled if Çifte is on, unchanged from current `SurvivalEngine`/`FixedRoundsEngine` behavior.
- **Round-entry (Okey standard)**: Restyle only — the underlying `losingEntrantID` + per-Entrant Gösterge-find counts + Çifte model is unchanged; only the picker (segmented → two full-width cards with a checkmark) and stepper (native `Stepper` list → prototype's `–`/count/`+` row) become custom components.
- **Rejoin**: Keep the existing `.sheet(item:)` presentation mechanism, but style it as a bottom half-sheet (rounded top corners, drag handle, slide-up transition) matching the prototype's sheet look, rather than the current `.medium` detent plain sheet.
- **Archive control**: No change to interaction — `.swipeActions` stays as the only archive/restore mechanism; the prototype's always-visible inline Archive/Restore button is deliberately not built.
- **Keypad**: Keep the existing custom `LazyVGrid`-based keypad approach (already the current architecture); restyle button appearance (rounded tiles, mono digits, `C`/`⌫` treated as text-weight buttons per the prototype) rather than switching to a native `.keyboardType(.numberPad)` field.
- **Snapshot testing**: Add swift-snapshot-testing as a test-target dependency; record reference snapshots per screen and per appearance (Paper/Felt) as each screen's design-system-based reskin lands. See `docs/adr/0004-snapshot-testing-for-ui-redesign.md`.
- **Delivery**: One `.scratch/ui-redesign/` feature. Tickets, one per unit of work: design-system/tokens first, then one ticket per screen in the prototype's flow order (Home, Variant, Setup, Play, Entry [keypad + Okey-standard], Scoresheet). Each ticket ships as its own short-lived `feature/`-prefixed branch and PR into `main`, squash-merged, per `docs/agents/gitflow.md`.

## Testing Decisions

- Good tests here assert observable behavior/state, not view-body implementation details — consistent with the existing `siraTests` style (e.g. `SurvivalEngineTests`, `MatchStoreTests` assert on `Match`/`Standings` outputs, not on SwiftUI internals).
- Any new interactive state introduced by the reskin must be extracted into a plain, testable type before it's tested:
  - The reworked round-entry state (per-Entrant values + active-Entrant selection + derived "ready to save" and "doubled preview" values) gets its own unit tests, analogous to existing `MatchTests`/`ScoresheetTests` coverage of derived state.
  - Theme-token resolution (system color scheme → Paper/Felt token set) gets a unit test asserting the mapping, independent of any view.
- Snapshot tests (new — see Implementation Decisions) cover each reskinned screen's rendered appearance in both Paper and Felt, recorded as each screen's ticket lands. These are the primary regression net for the parts of this feature (colors, fonts, layout) that plain unit tests can't meaningfully assert.
- No changes are needed to existing engine tests (`SurvivalEngineTests`, `EliminationEngineTests`, `FixedRoundsEngineTests`, `MatchTests`, `MatchStoreTests`, `MatchFilterTests`, `MatchSummaryTests`, `ScoresheetTests`) — the reskin does not change scoring/round/rejoin/archive logic, only presentation and the round-entry input mechanism's shape.

## Out of Scope

- Night and Clay theme palettes, and any in-app theme picker or manual light/dark override (see `docs/adr/0002-two-system-driven-themes.md`).
- An inline Archive/Restore button on Home rows (swipe-to-archive is kept as-is).
- Switching the round-entry keypad to the native system number pad.
- Any change to domain/scoring logic (`Match`, `Round`, `MatchEngine` and its `SurvivalEngine`/`EliminationEngine`/`FixedRoundsEngine` implementations, `Scoresheet`, `Standings`) — this is a presentation-layer and input-mechanism reskin only.
- iPad-specific or landscape-specific layout — the prototype itself is a single fixed-width iPhone mockup; no multi-size layout adaptation is specified here beyond what Dynamic Type scaling already requires.
- App icon / launch screen changes.

## Further Notes

- Source of truth for the visual design: the Claude Design project "Card Scores" (`Card Scores.dc.html`), projectId `ea5a7a7f-3fd6-4aed-8c0f-44f7a5469a58`, readable via the `DesignSync` tool. Cross-reference it directly when implementing each screen/component rather than relying solely on this spec's prose.
- Domain vocabulary throughout (Game, Match, Variant, Entrant, Round, Out, Rejoin, Archived, Gösterge, Win Condition, Çifte) is defined in `CONTEXT.md` and is unchanged by this feature.
- Relevant ADRs: `docs/adr/0001-bundle-brand-fonts.md`, `docs/adr/0002-two-system-driven-themes.md`, `docs/adr/0003-native-navigation-and-type-scaling-over-literal-port.md`, `docs/adr/0004-snapshot-testing-for-ui-redesign.md`.
- Per-screen implementation tickets (one per unit of work, per the Delivery decision above) should be filed under `.scratch/ui-redesign/issues/`, numbered from `01`, starting with the design-system/tokens ticket.
