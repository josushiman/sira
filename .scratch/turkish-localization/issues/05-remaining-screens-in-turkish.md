# 05 — Every remaining screen in Turkish

**What to build:** A player with a Turkish phone can go from picking a Variant, through Setup, into a Match, add Rounds on either entry screen, read the Scoresheet, and take or decline a Rejoin offer — all in Turkish. After this ticket the app has no English left in it for a Turkish user.

The catalog, the casing fix and the snapshot locale axis all already exist from ticket 04, so this ticket adds entries and translations rather than infrastructure.

**Blocked by:** 04.

**Status:** ready-for-agent

- [ ] The Variant picker is localized: each Variant's label and rule text. "Okey (standard)" becomes "Okey (standart)" — the parenthetical is the only part that translates. "Gonga 101", "Gonga 151" and "Okey 101" are unchanged.
- [ ] Setup is localized: the entrant-count and round-count chips, the name-entry rows and their placeholder hints, and the Start Match button.
- [ ] Play is localized: the Standings/Scoresheet toggle, standings rows and their LEADS/OUT tags, both stat tiles (leader-or-result, and room-left / rounds-left / gap), and the Match-over banner.
- [ ] The Scoresheet is localized: its column headings and any round labelling.
- [ ] Keypad Round entry is localized: the Cancel/Save top bar, the quick-entry shortcuts ("Won the round", "Never laid down"), and the Çifte toggle with its doubling preview.
- [ ] Okey-standard Round entry is localized: the losing-team cards, the Gösterge stepper rows, and the Çifte toggle.
- [ ] The Rejoin bottom sheet is localized, including the "They're out" decline — a decision that permanently affects the Match, so its Turkish must be unambiguous.
- [ ] Gösterge and Çifte appear exactly as they do today in both languages. They are already Turkish and are not "translated" into something nobody says at a table.
- [ ] The four Variant rule paragraphs are flagged in the pull request as **needing the maintainer's native rewrite, not their approval**. These are the remaining four of the six voice strings, they are the longest prose in the app, and a faithful rendering of them will read as a translated app.
- [ ] Turkish copy never attaches a grammatical suffix to an interpolated value. Where a sentence would require one — anything of the shape "Ali'nin" — the copy is phrased around it, because no format string can know a name's final vowel.
- [ ] Where a string combines a count with a noun, Turkish uses a single form, since Turkish takes no plural suffix after a numeral. English uses catalog plural variants where genuine plural agreement exists. Note: the app may currently contain no true plural cases at all — stat tiles keep label and value separate, and Home's only count phrase is "Round N" — so this criterion may be satisfied vacuously. Confirm rather than assume.
- [ ] Turkish snapshots are added for the three remaining dense screens — Play, keypad Round entry, and Okey-standard Round entry — where Turkish string length can realistically overflow a layout. Snapshots are deliberately **not** added for every screen; full duplication doubles review burden on every future UI change to cover screens where nothing can overflow.
- [ ] Every existing English snapshot still passes.
- [ ] Turkish copy is reviewed by the maintainer as an `.xcstrings` diff in the pull request.
- [ ] No scoring, Round, Rejoin or archive behaviour changes. The engines and their tests are untouched.
- [ ] If this ticket runs long, the natural split is the two Round entry screens into their own ticket, leaving Variant picker / Setup / Play / Scoresheet / Rejoin here. Both halves are blocked only by 04 and can then run in parallel.
