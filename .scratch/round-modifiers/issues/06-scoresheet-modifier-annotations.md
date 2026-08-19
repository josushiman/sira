# 06 — Scoresheet annotations for doubled Rounds

**What to build:** A Round that was doubled says so in the history, naming the Entrant responsible.

**Blocked by:** 04 — Keypad Round entry, 05 — Okey 21 Round entry

**Status:** ready-for-agent

The app exists to settle arguments about totals. "Why is Ada's Round 120?" should be answerable from the scoresheet rather than from someone's memory of the Round.

- [ ] `ScoresheetRow` carries its Round's modifiers alongside the deltas it already holds
- [ ] The scoresheet annotates a doubled Round with what happened and who did it — e.g. the Okey atan's name, and which Entrants called Çifte
- [ ] The annotation uses the vocabulary from `CONTEXT.md`, with per-Game wording ("Okey attı" / "Jokeri attı")
- [ ] The existing row-delta derivation — Standings diffs, no Engine-specific logic — is untouched; this is purely additive
- [ ] Rejoins continue to render correctly in rows that also carry modifiers
- [ ] `ScoresheetTests` cover that a row carries its Round's modifiers and that delta derivation is unchanged by their presence
- [ ] `ScoresheetView` snapshots gain a doubled Round in both themes
