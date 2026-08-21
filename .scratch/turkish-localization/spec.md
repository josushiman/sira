Status: ready-for-agent

# Turkish localization

## Problem Statement

Sıra is an app about Turkish games, made for people who play them — Gonga and Okey, scored at a table where the conversation is in Turkish. Its glossary already keeps Gösterge and Çifte untranslated on purpose, and the app is named with a Turkish word. But every word of chrome the app puts on screen is English: "Your games", "Room left", "Never laid down", "14th March 2026 · 9pm". A Turkish speaker playing Okey with their family gets an app that names their game correctly and then talks to them in a language the table isn't using.

There is no localization infrastructure of any kind — no String Catalog, no `.lproj`, `developmentRegion = en`, and every user-facing string is a bare Swift literal. Some of those literals sit in the Domain layer, where language does not belong.

Separately, and independent of translation, parts of the app are **already incorrect for Turkish, and some are already incorrect in English**:

- Two `uppercased()` call sites (the display-type uppercase style, and the Entrant dot-badge initial) are locale-insensitive. In Turkish, `i` uppercases to `İ`, not `I`. Every uppercase-styled label in a Turkish build would render wrong, and an Entrant named "İlker" gets the wrong badge letter.
- The Home card title is a hand-assembled English date. It hard-codes an English ordinal ("14th"), hard-codes day-month-year order via string interpolation, and hard-codes a 12-hour clock with literal `"am"`/`"pm"`. Turkish uses a 24-hour clock and no ordinal marker in dates.
- That same date code renders "9pm" to a British user whose phone is set to a 24-hour clock — overriding a system preference the user explicitly set. This is a bug that exists today, in English.
- The app has no `CFBundleDisplayName`, so the home screen shows the target name: lowercase, dotless `sira`.
- Snapshot date fixtures pin no timezone, so Home snapshots already depend on the CI machine's zone. Adding a second locale makes this bite.

## Solution

Adopt a single native String Catalog (`Localizable.xcstrings`) with English as the source language and Turkish as a translation, following the system locale only — no in-app language picker, now or later.

Before the catalog is introduced, do two pieces of structural work that are much cheaper now than after ~150 strings are keyed. First, push display strings out of the Domain layer: `PlayStats`, `MatchSummary`, `MatchFilter` and `Variant` stop producing English and start producing semantic values that the view layer renders. Second, extract the Home card's date formatting out of the view into a testable value type, and fix its locale correctness while it moves.

The Turkish glossary is treated as a **domain-modeling decision, not a translation task** — canonical Turkish terms for Match, Round, Out and the rest are recorded in `CONTEXT.md` alongside their English counterparts, so future work speaks one vocabulary in two languages. Turkish copy for the app's six "voice" strings (the Home hero headline and subtitle, and the four Variant rule paragraphs) is treated as copywriting requiring a native rewrite, not as translation requiring approval.

## User Stories

1. As a Turkish-speaking player whose phone is set to Turkish, I want the entire app in Turkish, so that the app speaks the same language as the table I'm playing at.
2. As a Turkish-speaking player, I want the app to follow my phone's language automatically, so that I never have to find a setting to make it work.
3. As a player, I want no in-app language picker, so that the app stays as small and uncluttered as it is today.
4. As a Turkish-speaking player, I want Gösterge and Çifte to appear exactly as they do now, so that terms that were already Turkish aren't "translated" into something nobody says.
5. As a Turkish-speaking player, I want Gonga, Okey and the Variant numbers (101, 151) unchanged, so that the games are named the way they're named at a table.
6. As a Turkish-speaking player, I want "Okey (standard)" rendered as "Okey (standart)", so that the one English word inside an otherwise Turkish label is translated.
7. As a Turkish-speaking player, I want an uppercase-styled label containing an `i` to render with a dotted `İ`, so that the app doesn't display visibly misspelled Turkish.
8. As a player named "İlker", I want my dot badge to show `İ`, so that my initial is my actual initial.
9. As a Turkish-speaking player, I want the Home card date shown as "14 Mart 2026", so that it reads as a Turkish date rather than an English one with Turkish month names.
10. As a Turkish-speaking player, I want the Home card time shown on a 24-hour clock as "21:00", so that it reads as a time rather than as "9pm" translated.
11. As an English-speaking player, I want to keep the "14th March 2026 · 9pm" styling I have today, so that adding a second language doesn't cost the app its voice.
12. As a British player whose phone is set to a 24-hour clock, I want the Home card to show "21:00" rather than "9pm", so that the app respects a system preference I set deliberately.
13. As a Turkish-speaking player, I want "2 el kaldı" rather than "2 eller kaldı", so that the app doesn't apply English plural rules to a language that doesn't take them after a numeral.
14. As an English-speaking player, I want "1 round left" and "2 rounds left" both correct, so that the English build keeps proper plural agreement.
15. As a Turkish-speaking player, I want sentences about a named Entrant to read naturally without a grammatical suffix glued to my name, so that the app never produces something like "Ali'nin" assembled by a format string that can't know my name's final vowel.
16. As a player, I want the app's icon on my home screen labelled "Sıra" in both languages, so that the app is named properly rather than showing a lowercase, dotless `sira`.
17. As a Turkish-speaking player, I want the Home hero headline and subtitle to read as copy a Turkish speaker would write, so that the app doesn't feel like a translated app.
18. As a Turkish-speaking player, I want each Variant's rule text to read as an explanation of the game as it's actually played, so that the rules are clear rather than literally rendered from English.
19. As a Turkish-speaking player, I want the Home hero headline to break across lines sensibly at Turkish word lengths, so that a line break tuned to English doesn't leave the headline ragged.
20. As a Turkish-speaking player, I want the subtitle's spelled-out numerals to be Turkish words, so that "Two games, four variants" doesn't leave English words in a Turkish sentence.
21. As a Turkish-speaking player, I want the Active / All / Archived filter, the Standings/Scoresheet toggle, and the status pills all in Turkish, so that no control is left in English.
22. As a Turkish-speaking player, I want the Play screen's stat tiles ("Leader", "Room left", "Rounds left", "Gap") in Turkish, so that the at-a-glance summary is glanceable to me.
23. As a Turkish-speaking player, I want the round-entry quick shortcuts ("Won the round", "Never laid down") in Turkish, so that the fastest path through scoring is the one I can read.
24. As a Turkish-speaking player, I want the Rejoin offer and its "They're out" decline in Turkish, so that a decision that permanently affects the Match is one I fully understand.
25. As a Turkish-speaking player, I want the empty states in Turkish, so that the first thing I see in a fresh install isn't English.
26. As a player using a longer Turkish string on a small device, I want the layout to hold rather than clip or truncate, so that translation doesn't cost me information.
27. As a developer, I want display strings to live in the view layer rather than the Domain layer, so that Domain types describe the game rather than describing an English UI.
28. As a developer, I want `PlayStats` to say *which* statistic is interesting rather than what to call it in English, so that one type stops carrying two responsibilities.
29. As a developer, I want `MatchSummary`'s leader sentence to be a format string with named arguments rather than a string concatenation, so that a language with different word order can reorder it.
30. As a developer, I want the Home card's date formatting extracted from the view into a value type taking an explicit `Locale` and `TimeZone`, so that I can assert the exact rendered title in a fast test instead of inferring it from a snapshot image.
31. As a developer, I want date and time rules covered by unit tests across `en_GB`, `en_US` and `tr_TR`, so that the ordinal and clock-convention decisions are pinned by assertions rather than by reference images.
32. As a developer, I want every existing snapshot pinned to an explicit locale and timezone, so that the suite stops depending on whatever the CI machine happens to be set to.
33. As a developer, I want Turkish snapshots for the four densest screens rather than for every screen, so that I get real overflow coverage without doubling my review burden on every future UI change.
34. As a developer, I want the Turkish domain vocabulary recorded in `CONTEXT.md` next to the English terms, so that future work — mine or an agent's — speaks one vocabulary in two languages.
35. As a developer, I want the source-language and Domain-seam decisions recorded in an ADR, so that a future reader who finds a Turkish-domain app with an English source language understands why.
36. As a developer, I want the six "voice" strings explicitly flagged as needing a native rewrite rather than an approval, so that the review pass puts effort where translation genuinely can't reach.
37. As a developer, I want the work split so that no single pull request both restructures code and introduces a language, so that a regression is attributable.
38. As a developer, I want the Domain-seam refactor to leave English output byte-identical, so that its pull request is reviewable as a pure refactor.
39. As a developer reviewing Turkish copy, I want to review it as a diff in a pull request rather than in an editor that leaves no artifact, so that the review lives with the code.
40. As a developer, I want a missing Turkish string to fail a test rather than silently ship in English, so that the draft-then-review workflow is safe.

## Implementation Decisions

- **Mechanism**: A single `Localizable.xcstrings` String Catalog. No third-party pipeline (SwiftGen, Lokalise, Phrase) — the app is roughly 150 strings with one translator, and the catalog gives automatic extraction, plural variants, and per-string translation state with zero dependencies. The iOS 26.5 deployment target means there is no back-compatibility cost.
- **Language selection**: System locale only, permanently. No in-app picker and no indirection built in anticipation of one — `Locale.current` is read directly. iOS's own per-app language setting remains the only override, which is the deliberate and accepted trade-off.
- **Source language**: English remains the development language; `developmentRegion` stays `en`. Keys are the English source text, not abstract identifiers. This buys automatic extraction, readable call sites, and a readable fallback, at the accepted cost of calque risk in the Turkish column — which is managed by treating Turkish as copywriting rather than as translation, not by adding a key indirection layer.
- **Domain seam**: Display strings move out of the Domain layer into semantic values, and this lands *before* the catalog exists so that keys are never migrated twice.
  - `PlayStats` stops exposing `leadLabel` / `secondaryLabel` / `secondaryValue` as pre-rendered English and instead exposes a semantic case carrying its own number — room-left, rounds-left, or gap — plus a semantic lead state distinguishing an in-progress leader from a final result. The view layer maps these to text.
  - `MatchSummary` stops concatenating its leader sentence and instead exposes the leader and total as separate values, rendered through a localized format string with positional arguments so that Turkish word order can differ. Its no-Entrants case becomes a semantic state rather than the literal string "No Entrants".
  - `MatchFilter` stops using English display text as its `String` raw value. Its raw value becomes a stable, non-display identifier and the view layer supplies the label.
  - `Variant` drops `label` and `ruleText`. The view layer derives both from the Variant's identity. This keeps `Variant` a description of a ruleset rather than a description of a screen.
- **Locale-aware casing**: Both `uppercased()` call sites — the display-type uppercase style and the Entrant dot-badge initial — become locale-aware. This is in scope as a correctness fix, not as polish; without it a Turkish build ships visibly misspelled text on every uppercase-styled label.
- **Date and time**: The Home card's date/time formatting is extracted from the view into a value type that takes a `Date`, a `Locale` and a `TimeZone` and returns the rendered title.
  - Date *components* (month name, day, year) come from the system per-locale. The *assembly template* lives in the String Catalog as a localized format string with positional arguments, so the English entry can consume an ordinal day and the Turkish entry a plain cardinal one. No locale conditional appears in code.
  - The clock follows the locale and the user's 12/24-hour system setting. Where the locale is genuinely 12-hour, the existing compact lowercase style with minute elision ("9pm", "9:15pm") is preserved as part of the app's voice. Where it is 24-hour — always, for Turkish — the standard "21:00" form is used and minute elision does not apply, because a bare hour does not read as a time in Turkish. This corrects the existing English-side bug where "9pm" was shown regardless of the user's 24-hour setting.
- **Untranslated set**: Sıra, Gonga, Okey, Gösterge, Çifte, and the bare Variant numbers are identical in both catalogs. The only Variant label that changes is the parenthetical in "Okey (standard)" → "Okey (standart)".
- **App display name**: `CFBundleDisplayName` is added as "Sıra", unlocalized — one name in both languages. Folded into this work because it is the same category of defect as the casing bug.
- **Plurals and grammatical agreement**: English uses catalog plural variants. Turkish uses a single form, since Turkish takes no plural suffix after a numeral. A standing constraint applies to all Turkish copy: **never attach a grammatical suffix to an interpolated value**. Copy is phrased around the problem instead. This is why `MatchSummary` becomes a format string rather than remaining a concatenation.
- **Turkish domain vocabulary**: Recorded inline in `CONTEXT.md`, one Turkish line per existing term — vocabulary belongs in the glossary, and a separate file would drift. The adopted terms:

  | English | Turkish |
  |---|---|
  | Game | Oyun |
  | Match | Parti |
  | Round | El |
  | Out | Yandı |
  | Rejoin | Yeniden gir |
  | Archived | Arşiv |
  | Leader | Önde |
  | Gap | Fark |
  | Room left | Kalan |
  | Rounds left | Kalan el |

  **Entrant deliberately has no Turkish UI term.** English needs "Entrant" because it is an umbrella over player-and-team, but a Match is never mixed — `entrantMode` is fixed by the Variant — so the concrete kind is always known at render time. The Turkish catalog uses *Oyuncu* or *Takım* per Variant; "Entrant" survives as an English-only code and domain word. *Katılımcı* is rejected as stiff and unspoken at a table.
- **Copy authorship**: All Turkish strings are drafted by the implementing agent and reviewed by the maintainer as an `.xcstrings` diff in a pull request. Six strings — the Home hero headline, the Home subtitle, and the four Variant rule paragraphs — are explicitly marked as **needing a native rewrite, not an approval**; these are copywriting, and a faithful rendering will read as a translated app. The Home headline's hard-coded line break, tuned to English word lengths, is revisited as part of that rewrite, as are the subtitle's spelled-out English numerals.
- **ADR**: One ADR records the source-language decision and the Domain-seam decision together — they are one decision with two halves, both hard to reverse, both surprising without context. No ADR is written for the catalog choice itself; it is the obvious default at this deployment target.
- **Delivery**: One `.scratch/turkish-localization/` feature, delivered as five sequential tickets, each its own short-lived branch and squash-merged pull request per `docs/agents/gitflow.md`. No pull request both restructures code and introduces a language.
  1. Docs only — the ADR and the bilingual `CONTEXT.md`. Lands first because the Turkish glossary is the least-verified part of the design and is free to change before any string is keyed against it.
  2. Domain seam — the `PlayStats` / `MatchSummary` / `MatchFilter` / `Variant` split. Pure refactor; English output byte-identical.
  3. Date and time — the value-type extraction, the 24-hour correction, and timezone pinning in fixtures. English behaviour changes here, correctly and deliberately.
  4. Catalog infrastructure — `Localizable.xcstrings`, string extraction, locale-aware casing, `CFBundleDisplayName`, and locale/timezone pinning across the snapshot suite. Output remains English-only.
  5. Turkish — translations, Turkish snapshots, and the maintainer's rewrite pass on the six voice strings.

## Testing Decisions

- A good test here asserts observable behaviour, consistent with the existing `siraTests` style, where `SurvivalEngineTests` and `MatchStoreTests` assert on `Match` and `Standings` output rather than on SwiftUI internals. Localization tests must not assert that a particular key exists or that a particular formatter was called; they assert what a user would see.
- **Three seams, only one of them new.**
- **Seam A — the existing Domain unit tests (`PlayStatsTests`, `MatchSummaryTests`, `MatchFilterTests`, `VariantTests`, `MatchTests`).** These are reshaped, not relocated. After the Domain seam lands they assert semantic values rather than English strings — a room-left case carrying its number, rather than the label "Room left" beside the value "59". The assertions get stronger, and no localization test is needed at this seam at all, because after the split there is no language left in the Domain to test. `Entrant`'s dot-badge initial is reached through this seam, which is where the locale-aware casing fix is asserted, including the Turkish dotted-`İ` case.
- **Seam B — `MatchDateStyle` (new; the only new seam).** A pure function of `Date`, `Locale` and `TimeZone`. This is the highest available point for the date work: one surface covers the ordinal rule, day/month/year assembly, the 12-versus-24-hour decision, and minute elision, with no view involved. Tested directly across `en_GB`, `en_US` and `tr_TR`, asserting exact rendered titles — including "14 Mart 2026 · 21:00", "14th March 2026 · 9pm", the minutes-present case, and the 24-hour-preference case that is currently a bug in English. Prior art for this shape of test is `ScoresheetTests` and `MatchSummaryTests`, which assert derived presentation-adjacent values on plain types.
- **Seam C — the existing snapshot suite.** Every existing snapshot is pinned to an explicit locale *and* an explicit timezone; `Date.fixture` gains an explicit timezone, closing a pre-existing CI-machine dependency that localization would otherwise appear to have caused. Turkish snapshots are added for the four densest screens only — Home, Play, keypad round entry, and Okey-standard round entry — which is where Turkish string length can realistically overflow a layout. Full duplication across all ten suites is rejected: it doubles review burden on every future UI change to cover screens where nothing can overflow. Prior art is the existing per-appearance (Paper/Felt) snapshot pattern established by `docs/adr/0004-snapshot-testing-for-ui-redesign.md`; locale becomes a second axis alongside appearance, applied selectively rather than exhaustively.
- **Deliberately not a seam: locale-aware casing does not get its own test surface.** The Entrant initial is already reachable through Seam A, and the display-type uppercase path lives inside a view body where a snapshot is the honest test. A third seam to unit-test a two-line casing helper would cost more than it buys.
- **Optional fourth seam — catalog completeness.** A test that parses `Localizable.xcstrings` and fails if any key lacks a Turkish value in a translated state. This is the guard that makes the draft-then-review workflow safe: without it, a string added in a later feature silently ships in English to Turkish users. It is a genuinely new seam and is marked optional for the maintainer to accept or cut. If accepted, it belongs with ticket 4 so that ticket 5 lands against an already-armed check.

## Out of Scope

- **Any third language.** The catalog makes adding one straightforward, but no accommodation is designed for it; in particular the untranslated-term set and the Entrant-has-no-umbrella-term decision are reasoned specifically about Turkish.
- **An in-app language picker**, now or later. This was considered and explicitly and permanently rejected.
- **Turkish collation.** The Turkish alphabet orders `ç ğ ı ö ş ü` distinctly, but no name-ordered list exists in the app today — the engines sort Entrants by score. Deferred until a name-sorted surface exists.
- **Date and number formatting beyond the Home card title.** No other date is displayed anywhere in the app. The U+2212 minus in Okey-standard rule text stays as-is; it is a typographic choice, not a locale-dependent one.
- **Right-to-left layout.** Neither language needs it.
- **Localized App Store metadata, screenshots, or listing copy.** In-app strings only.
- **Localized accessibility labels beyond what falls out of the catalog.** Where a label is already a localized string it follows automatically; no separate accessibility audit is undertaken here.
- **Changing scoring, round, rejoin, or archive behaviour.** No engine logic is touched. `SurvivalEngine`, `EliminationEngine` and `FixedRoundsEngine` and their tests are unaffected.
- **Re-recording snapshots for visual reasons.** English snapshots are re-recorded only where the locale/timezone pin or the date-format change alters the rendering.

## Further Notes

- **This feature fixes three defects that exist today in the English build**, all uncovered while designing for Turkish: the missing `CFBundleDisplayName` showing a lowercase, dotless `sira` on the home screen; the Home card showing "9pm" to users whose system is set to a 24-hour clock; and snapshot date fixtures with no pinned timezone. Each is folded in rather than split out, because each sits in exactly the code this work already has open, and two of the three are only *observable* once a second locale exists.
- **The Turkish glossary is the least-verified part of this spec.** It was proposed from game convention rather than derived from the codebase, and accepted without correction. It is free to change before ticket 1 lands and expensive to change after ~150 strings are keyed against it. `Parti`, `Yandı` and `Yeniden gir` in particular deserve a native ear before ticket 1 is merged.
- **The calque risk accepted in the source-language decision is real and is not fully mitigated by process.** English-as-source means every future string is authored in English first, and Turkish will always be downstream. The six flagged voice strings are the known concentration of that risk, but ordinary labels can drift too. If the Turkish build ever starts reading as translated rather than written, revisiting the source-language decision is the lever — and the ADR exists so that a future reader knows it was a choice.
- The design for this feature was settled in a grilling session covering fifteen decisions across three rounds; this spec is that session's output and no implementation work has begun.
