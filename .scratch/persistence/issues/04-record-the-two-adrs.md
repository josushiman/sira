# 04 — Record the two persistence ADRs

**What to build:** The two architectural decisions behind this spec, written before the code that implements them. Both meet the bar: hard to reverse once data exists on devices, surprising to a reader who wasn't in the conversation, and the result of a real trade-off with a rejected alternative.

They are separate ADRs because their reversal costs differ sharply — the storage mechanism is a rewrite to undo, the Variant encoding is a migration.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] ADR: **the domain types are the SwiftData models**. Decision: Match, Round and Entrant become model classes; there is no mapping layer. Rejected alternative: persistence records mapped to and from the existing value types, rejected because it maintains two descriptions of a domain that changed in three consecutive commits
- [ ] That ADR states the consequences plainly: these types stop being value types, the store's Match binding and its missing-id crash disappear, undoing a Round becomes a delete rather than dropping the last element, previews need a container, and the risk is bounded by Rounds being append-only with only the last one removable
- [ ] That ADR records why a Round's deltas, Çifte callers and Rejoins stay inline rather than becoming relationships — per ADR 0005 the Engines read a whole Round and derive from it — and that a UUID-keyed dictionary therefore gets no referential integrity, which is safe only while Entrants cannot be removed from a Match
- [ ] That ADR records local-only storage as a one-way door: adopting sync later would require unique constraints to be dropped and stored properties to become optional or defaulted
- [ ] ADR: **a Match stores its Variant's id, not the Variant**. Decision: store the id plus the Setup-chosen Round count and resolve the Variant from the shipped constants. Rejected alternative: encoding the whole Variant, rejected because each of this project's recent rule fixes would then have split the data into Matches scored by rules that exist nowhere in the code
- [ ] That ADR records the resulting frozen-id contract, the Okey 21 rename taken in ticket 01 as the last free moment to do it, and the decision to skip rather than delete a Match whose id cannot be resolved
- [ ] That ADR records what would keep cross-Match player identity cheap later: an optional link from Entrant to a shared identity, nullify rather than cascade, never inferred from names, and never assumed one-to-one — Okey 21's Entrants are teams of two
- [ ] Both follow the existing ADR format and numbering
