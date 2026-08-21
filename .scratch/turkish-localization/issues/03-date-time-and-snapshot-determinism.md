# 03 — Date and time correctness, and a deterministic snapshot suite

**What to build:** A player whose phone is set to a 24-hour clock sees "21:00" on a Home card instead of "9pm". The date formatting that produces that title moves out of the view into a value type that can be tested directly against any locale and timezone, instead of only being observable through a snapshot image.

This ticket changes English behaviour, deliberately. The Home card currently shows "9pm" to every user regardless of their 12/24-hour system setting — a preference they set on purpose. That is a bug today, in English, and it is fixed here. Expect existing Home snapshots to change.

**Blocked by:** None — can start immediately. This is a prefactor and involves no Turkish, so it does not wait on the glossary.

**Status:** ready-for-agent

- [ ] Home card date/time formatting is extracted out of the view into a value type taking a `Date`, a `Locale` and a `TimeZone` and returning the rendered title. This is the single new test seam in the whole feature.
- [ ] Date components — month name, day, year — come from the system per-locale rather than being assembled by string interpolation. The current hard-coded day-month-year order is removed; ordering follows the locale.
- [ ] The English ordinal day ("14th") is preserved for English, but is no longer produced for locales that do not use one. The assembly is structured so the ordinal can be supplied per-locale rather than by a conditional in code — in this ticket the template can live in the type; ticket 04 moves it into the String Catalog.
- [ ] The clock follows the locale *and* the user's 12/24-hour system setting. Where the locale is genuinely 12-hour, the existing compact lowercase style with minute elision is preserved — "9pm", "9:15pm" — because it is part of the app's voice. Where it is 24-hour, the standard "21:00" form is used and minute elision does not apply.
- [ ] Unit tests assert exact rendered titles across `en_GB`, `en_US` and `tr_TR`, covering: the on-the-hour case, the minutes-present case, the 24-hour-preference case that is currently wrong in English, and the Turkish case rendering as "14 Mart 2026 · 21:00" with no ordinal marker.
- [ ] `Date.fixture` gains an explicit timezone. This closes a pre-existing dependency on the CI machine's zone that localization would otherwise appear to have caused.
- [ ] Every existing snapshot test is pinned to an explicit locale *and* an explicit timezone, so the suite stops depending on whatever the host happens to be set to. Locale becomes a second axis alongside the existing Paper/Felt appearance axis established by `docs/adr/0004-snapshot-testing-for-ui-redesign.md`.
- [ ] Home snapshots are re-recorded where the date-format change alters the rendering, and only there. No snapshot is re-recorded for cosmetic reasons.
