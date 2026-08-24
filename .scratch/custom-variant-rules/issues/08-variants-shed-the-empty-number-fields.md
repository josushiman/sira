# 08 — Variants shed the empty number fields

**What to build:** The cleanup ticket 06's review asked for and 06 deliberately did not take, raised here so it is decided rather than forgotten.

`Variant` still declares `limit`, `startingScore` and `roundCount`, as `let … = nil`. No Variant carries a value, nothing reads them, and the accessor resolves the number from the Match alone — but `variant.limit` still compiles and still answers `nil`. That is the exact shape the spec set out to remove: a number that can be read off a Variant, silently, by a caller who does not know better. Deleting the three properties turns that mistake from a `nil` at runtime into a compile error.

The counter-argument, which is why 06 left them: the spec says the fields "become `nil` on every Variant" rather than that they go, and `VariantTests.test_noVariantCarriesANumberToBePlayedAt` is written against them. That test documents the contract rather than defending it — it cannot fail while the declarations carry `= nil` — so deleting the properties means deleting the test with them, and the contract then rests on the type having no such field at all, which is stronger than any assertion could be.

## Decided (2026-08-24): the fields go

The human call this ticket was waiting on has been made — delete them. The reasoning, recorded here because it is the part worth keeping:

- **They are still callable and they answer plausibly.** The next caller reaching for a Variant's number writes `variant.limit ?? 101` or `if let n = variant.roundCount`, builds clean, and gets a fallback instead of `Match.variantNumber`. Deleting the properties makes that same code fail to compile, with the fix one symbol away. Nothing in `sira/` reads them today; the only three readers in the repo are the assertions in `VariantTests`.
- **The test defending them cannot fail.** `let limit: Int? = nil` is a compile-time constant, excluded from the memberwise init, so no Variant can be constructed carrying one. The assertion restates what the compiler already guarantees. Absence of the field makes the contract structural instead of asserted.
- **They are three-eighths of what a `Variant` looks like** — in the synthesized `Equatable`/`Hashable`, in autocomplete, and in the first screenful anyone reads to learn what a Variant is, carrying no content but "not this one".

The cost is real and is paid in the same change: the contract stops being stated in code and would otherwise live only in `CONTEXT.md` and ADR 0008. So the rationale moves up into `Variant`'s type doc — a Variant describes shape, and the number it is played at is on the Match, read through `Match.variantNumber` — which says more than three `nil`s did.

The spec's wording ("the fields become `nil` on every Variant") is superseded by this decision rather than contradicted by an agent: it described the safest first move, and the move after it is the one being taken here. ADR 0008 already records the decision this rests on — Variants carry shape, Matches carry values — and needs no amendment, but its first bullet names the three properties as carrying no value and should read as them being gone.

## Doing it

Delete the three properties, delete `test_noVariantCarriesANumberToBePlayedAt`, move the rationale from the declarations into `Variant`'s type doc, and correct ADR 0008's first bullet. Nothing a player can see changes and no snapshot should move — a re-recorded snapshot in this change means something rendered differently, which is a bug, not a re-record.

**Blocked by:** 06.

**Status:** done

- [x] Decided: fields deleted, or kept with the reasoning recorded at the declaration — **deleted**, reasoning above
- [x] `Variant` declares no `limit`, `startingScore` or `roundCount`, and no caller reads one
- [x] `Variant`'s type doc carries the contract the deleted declarations used to state
- [x] `VariantTests` no longer asserts a contract the type now enforces
- [x] ADR 0008's first bullet describes the properties as gone rather than as empty
- [x] Full suite green, with no snapshot re-recorded
