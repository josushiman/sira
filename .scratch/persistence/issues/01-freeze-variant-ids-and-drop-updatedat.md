# 01 — Freeze the Variant ids, drop the dead field

**What to build:** Two cleanups that are free today and become migrations tomorrow. Okey 21's Variant id stops disagreeing with its label, and the Match field that has never been read is removed. Nothing a player can see changes; this exists so the schema, when it arrives, is written over a domain that is already correct.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [x] Okey 21's Variant id is renamed from `okey-standard` to `okey-21`, matching the Variant's label
- [x] The declaration documents that Variant ids become a persistence contract once the app ships: a Match will store this string and resolve its rules from it, so renaming one orphans every Match that names it
- [x] Every Variant's id is asserted explicitly in the Variant tests — `gonga-101`, `gonga-151`, `okey-21`, `okey-101` — so a future rename fails the suite instead of silently orphaning data
- [x] `Match.updatedAt` and its initialiser parameter are gone; it is set at creation and never read or written anywhere in the app or the tests
- [x] Home is demonstrably unaffected: Matches still sort newest-first and each card is still titled by its creation datetime, both of which read `createdAt`
- [x] Full suite green, with no snapshot re-recording
