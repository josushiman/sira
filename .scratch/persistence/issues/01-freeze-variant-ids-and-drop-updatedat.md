# 01 — Freeze the Variant ids, drop the dead field

**What to build:** Two cleanups that are free today and become migrations tomorrow. `Variant.okeyStandard`'s id is renamed to match its label, and `Match.updatedAt` is deleted. No persistence yet — this ticket exists so that the schema, when it arrives, is written over a domain that is already correct.

**Blocked by:** nothing

**Status:** ready-for-agent

- [ ] Rename `Variant.okeyStandard`'s id from `okey-standard` to `okey-21`, matching the Variant's label
- [ ] Document at the declaration that Variant ids are a persistence contract once the app ships: a Match will store this string and resolve rules from it, so renaming one orphans every Match that names it
- [ ] `VariantTests` asserts every Variant's id explicitly — `gonga-101`, `gonga-151`, `okey-21`, `okey-101` — so a future rename fails the suite instead of silently orphaning data
- [ ] Delete `Match.updatedAt` and its initialiser parameter; it is set at creation and never read or written anywhere in the app or the tests
- [ ] Confirm Home is unaffected: `MatchFilter` sorts by `createdAt` descending and `HomeView` titles each card from `createdAt`, neither of which touches the removed field
- [ ] Full suite green, no snapshot re-recording expected
