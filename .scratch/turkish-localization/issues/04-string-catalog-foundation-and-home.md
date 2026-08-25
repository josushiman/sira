# 04 — String Catalog foundation, and Home in Turkish

**What to build:** A player sets their phone to Turkish, opens the app, and Home reads Turkish — the hero, the filter pills, the match cards, the status pills, the empty states, the dates. The app's icon is labelled "Sıra" rather than a lowercase, dotless `sira`.

This is the tracer bullet. It cuts through every layer the app has — app configuration, Domain, design system, screen, and both test seams — and it retires the pipeline risk in one go: the catalog exists, extraction works, locale switching works, snapshots pin correctly, and ticket 02's semantic Domain values render in two languages.

**Blocked by:** 01 (the glossary must be settled before any Turkish string is written), 02 (Home renders `MatchSummary` and `MatchFilter`), 03 (Home renders the date title).

**Status:** ready-for-agent

- [ ] A single `Localizable.xcstrings` String Catalog exists, with English as the source language and Turkish as a translation. `developmentRegion` stays `en`; `tr` is added to the project's known regions. Keys are the English source text, not abstract identifiers. No third-party pipeline is introduced.
- [ ] Language follows the system locale only. No in-app picker is built, and no indirection is added in anticipation of one — `Locale.current` is read directly. This is a permanent decision, not a v1 simplification.
- [ ] Both locale-insensitive `uppercased()` call sites become locale-aware: the display-type uppercase style, and the Entrant dot-badge initial. An Entrant named "İlker" gets `İ`, and an uppercase-styled label containing an `i` renders with a dotted `İ` in Turkish.
- [ ] `CFBundleDisplayName` is added as "Sıra", unlocalized — one name in both languages.
- [ ] Every Home string is localized in English and Turkish: the hero headline, the subtitle, the "Your games" heading, the Active / All / Archived filter pills, the three empty states, the Finished / Archived / Round-N status pills, the swipe Archive and Restore actions, and the Game cards.
- [ ] The Home hero headline's hard-coded line break is revisited rather than copied — it was tuned to English word lengths. The subtitle's spelled-out English numerals ("Two games, four variants") become Turkish words in the Turkish column, not English words in a Turkish sentence.
- [ ] The hero headline and subtitle are flagged in the pull request as **needing the maintainer's native rewrite, not their approval** — these are copywriting, and a faithful rendering will read as a translated app. Two of the six voice strings are in this ticket; the other four are in ticket 05.
- [ ] The date assembly template moves into the catalog as a localized format string with positional arguments, so the English entry consumes an ordinal day and the Turkish entry a plain cardinal one, with no locale conditional in code.
- [ ] Sıra, Gonga, Okey and the bare Variant numbers render identically in both languages.
- [ ] A Turkish Home snapshot is added. Existing English Home snapshots still pass, and the layout holds under Turkish string lengths rather than clipping or truncating.
- [ ] Turkish copy is reviewed by the maintainer as an `.xcstrings` diff in the pull request.
- [ ] Screens other than Home are untouched and continue to render English. A Turkish phone shows a mixed app until ticket 05 lands; untranslated keys fall back readably to English, so nothing is broken in the interim.
