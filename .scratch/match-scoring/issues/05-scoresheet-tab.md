# 05 — Scoresheet tab

**What to build:** A second tab on the Play screen showing the full Round-by-Round history: one column per Entrant, one row per Round, and a totals row — alongside the existing Standings tab.

**Blocked by:** 04 — Çifte in Gonga

**Status:** ready-for-agent

- [ ] Play screen has Standings/Scoresheet tabs, matching the existing tab-switch pattern
- [ ] Scoresheet renders one row per saved Round with each Entrant's delta for that Round
- [ ] Scoresheet shows a totals row matching the Standings tab's current totals
- [ ] Built generically against `Standings`/`Round` data — no Survival-specific logic — so it requires no changes when later Engines (tickets 07, 08) are added
- [ ] Undoing a Round removes its row and updates the totals row immediately
