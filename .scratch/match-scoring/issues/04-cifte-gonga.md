# 04 — Çifte in Gonga

**What to build:** A per-Round Çifte toggle on the keypad entry screen that doubles every Entrant's delta for that Round before it's saved.

**Blocked by:** 03 — Undo

**Status:** ready-for-agent

- [ ] Keypad Round entry has a Çifte toggle
- [ ] When Çifte is on, every Entrant's entered value is doubled in the Round that gets saved (visible in the pre-save preview, per the existing UI pattern)
- [ ] Çifte state is per-Round — it does not persist as "on" into the next Round's entry
- [ ] Undo (ticket 03) correctly reverses a doubled Round
- [ ] `SurvivalEngineTests` cover a Round saved with Çifte on, confirming every Entrant's delta was doubled
