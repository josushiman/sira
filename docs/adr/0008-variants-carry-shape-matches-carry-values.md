# Variants carry shape, Matches carry values

Gonga 101 and Gonga 151 were one ruleset written twice: identical Win Condition, Entrant mode, table size, absence of Çifte and keypad entry, differing by a single integer. Okey 101's Round count was already a Setup choice while Okey 21's starting score was baked into its Variant, so the same kind of number was data in one Variant and code in another. We decided three linked things:

- **A Variant declares shape only; the number it is played at lives on the Match.** `Variant` declares no `limit`, `startingScore` or `roundCount` at all — there is no number to be read off a Variant — and Setup asks for the one number the Variant's Win Condition takes — a limit, a starting score or a Round count — which the Match stores and every screen reads back through `Match.variantNumber` and names with `Match.numberPhrase`.
- **Variant ids name slots, not numbers.** `gonga-standard` is labelled "Gonga" and `okey-standard` is labelled "Okey". An id or a label quoting a number the Variant no longer guarantees is worse than one quoting none, and a genuinely different Gonga or Okey ruleset can later take the id beside it without either having to lie.
- **ADR 0007's `okey-standard` → `okey-21` rename is reverted.** The rename existed to make the id agree with the label "Okey 21"; the label is gone, so the id goes back to naming its slot. Reverting is free on the same grounds 0007 renamed on — no shipped data names either id.

## Relationship to ADR 0007

This supersedes [0007](0007-a-match-stores-its-variant-id-not-the-variant.md) **in part only**. 0007's central decision stands and is not up for revisiting: a Match stores its Variant's **id** and resolves the rules from the constants in the binary, so a rule correction reaches Matches already on devices. So does its frozen-id contract, and the handling of an id that cannot be resolved — such a Match is skipped, never deleted.

What this ADR replaces is 0007's account of *what else* a Match stores alongside the id. 0007 said "plus the Round count chosen at Setup where the Variant has one", a per-Variant exception; a Match now always stores exactly one number, and no Variant has one. The frozen ids are now `gonga-standard`, `okey-standard` and `okey-101`; `gonga-101`, `gonga-151` and `okey-21` were retired before any data named them.

## Considered Options

**Deriving the display name from the number** — rendering a Match as "Okey 21" or "Gonga 151" from its stored value — was rejected. It resurrects exactly the names being retired: the stock Okey Match, the common case, would read "Okey 21" everywhere, and the Variant would once again be identified by a number that is now the table's choice.

**Showing a derived name only for non-default values** — plain "Okey" at 21, "Okey 19" otherwise — was rejected for the same reason and a worse one: one Match type would render under two naming schemes depending on a value, which makes 21 secretly special again after the whole point was that it isn't.

What we do instead is keep the label and the number separate and never fuse them. The label is "Gonga", "Okey" or "Okey 101" in every context; the number rides alongside as a phrase in the metadata line — `8 players · to 201` on the Home card, the same phrase under Play's header. The phrase form (`to 201`, `from 21`, `12 rounds`) is what distinguishes a limit from a starting score from a Round count, so nothing has to carry a separate label saying which is being shown.

## Consequences

Gonga has one Variant, so Home routes it straight to Setup rather than through a Picker offering a single card; Okey still routes to the Picker, which offers Okey and Okey 101. Home's copy and Play's header derive what they say from `Game.allCases` and `Variant.all(for:)` rather than quoting a catalogue that goes stale on the next change.

Two Matches of the same Variant at different numbers are told apart by their metadata line and nothing else, which is why the number is on the Home card at all.

`VariantParameter` owns the number as Setup asks for it — which kind it is, the presets offered, the legal range, and how it reads once chosen. Presets are stated there and nowhere else, there being no Variant constant left for them to agree or disagree with. Out of range is a refusal rather than a correction: a player who types 500 Rounds is told 500 will not do and is left holding 500, because clamping would start a Match at a length nobody chose and say nothing about having done so.
