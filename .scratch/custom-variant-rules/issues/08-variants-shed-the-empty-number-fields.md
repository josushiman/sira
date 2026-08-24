# 08 — Variants shed the empty number fields

**What to build:** The cleanup ticket 06's review asked for and 06 deliberately did not take, raised here so it is decided rather than forgotten.

`Variant` still declares `limit`, `startingScore` and `roundCount`, as `let … = nil`. No Variant carries a value, nothing reads them, and the accessor resolves the number from the Match alone — but `variant.limit` still compiles and still answers `nil`. That is the exact shape the spec set out to remove: a number that can be read off a Variant, silently, by a caller who does not know better. Deleting the three properties turns that mistake from a `nil` at runtime into a compile error.

The counter-argument, which is why 06 left them: the spec says the fields "become `nil` on every Variant" rather than that they go, and `VariantTests.test_noVariantCarriesANumberToBePlayedAt` is written against them. That test documents the contract rather than defending it — it cannot fail while the declarations carry `= nil` — so deleting the properties means deleting the test with them, and the contract then rests on the type having no such field at all, which is stronger than any assertion could be.

**This needs a human decision before an agent starts**, because it edits a statement the spec makes: whether "a Variant carries no number" is best said by a `nil` value or by the absence of the field.

If it goes ahead: delete the three properties, delete `test_noVariantCarriesANumberToBePlayedAt`, and check nothing outside the domain reads them. Nothing a player can see changes and no snapshot should move.

**Blocked by:** 06.

**Status:** ready-for-human

- [ ] Decided: fields deleted, or kept with the reasoning recorded at the declaration
- [ ] If deleted: `Variant` declares no `limit`, `startingScore` or `roundCount`, and no caller reads one
- [ ] If deleted: `VariantTests` no longer asserts a contract the type now enforces
- [ ] Full suite green, with no snapshot re-recorded
