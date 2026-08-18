# 01 — Design-system foundation + Home reskin

**What to build:** Introduce the shared design-system layer the whole reskin depends on, and prove it end-to-end by reskinning the Home screen with it — including folding game-picking into Home. A player opening the app sees Home rendered in the prototype's visual language (fonts, colors, cards, pills) in both light and dark mode, and can go straight from a Game card to the Variant picker without an intermediate screen.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Bricolage Grotesque (400/500/600/800) and IBM Plex Mono (400/500/600) are bundled as app font assets and usable from SwiftUI (`docs/adr/0001-bundle-brand-fonts.md`).
- [ ] Two color-token sets exist, matching the prototype's `THEMES.pad` ("Paper") and `THEMES.felt` ("Felt") values (background, surface, ink, line, track, accent, accent2, onAccent, tile, tileInk, cardFace, cardBack, pip, rotating dot-badge palette), resolved from the system color scheme with no persisted preference or picker UI (`docs/adr/0002-two-system-driven-themes.md`).
- [ ] Theme-token resolution (color scheme → Paper/Felt token set) has a unit test asserting the mapping, independent of any view.
- [ ] A typography scale maps the prototype's display/label/mono text roles onto scalable SwiftUI text styles that respect Dynamic Type, preserving the prototype's relative hierarchy rather than its literal point sizes (`docs/adr/0003-native-navigation-and-type-scaling-over-literal-port.md`).
- [ ] Shared, reusable components exist and are visible via SwiftUI Previews in both Paper and Felt: pill-track tabs, chip selectors, dot badges (colored by index from the theme's rotating palette), card rows, a bottom-sheet container, and custom keypad tiles.
- [ ] swift-snapshot-testing is added as a test-target dependency and wired up (`docs/adr/0004-snapshot-testing-for-ui-redesign.md`).
- [ ] `GamePickerView` is deleted. Home renders the two Game cards (Gonga, Okey) inline, styled per the prototype; tapping one navigates directly to `VariantPickerView`.
- [ ] Home's Match list renders as the prototype's cards (badge, title, status pill, leader/result line, dashed divider) instead of a plain `List` row.
- [ ] Home's Active/All/Archived filter renders as the prototype's pill row instead of a segmented `Picker`.
- [ ] Home's empty state (no Matches for the current filter) renders as the prototype's centered dim text instead of `ContentUnavailableView`.
- [ ] Swipe-to-archive/restore continues to work exactly as today — no inline Archive/Restore button is added.
- [ ] Snapshot tests exist for Home in both Paper and Felt appearances, covering: populated Match list, empty state, and the inline Game cards.
