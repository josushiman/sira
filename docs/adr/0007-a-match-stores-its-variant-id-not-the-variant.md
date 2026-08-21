# A Match stores its Variant's id, not the Variant

Once Matches are stored, a Match has to record which Variant it is played under. We decided it stores the Variant's **id**, plus the Round count chosen at Setup where the Variant has one, with `Match.variant` becoming a computed property that resolves the id against the Variant constants shipped in the binary.

## Considered Options

Encoding the whole Variant alongside the Match was rejected because a rule correction would then never reach data already on devices: each of this project's recent rule fixes would have split the history in two, with older Matches scoring by rules that exist nowhere in the code and no way for a player to tell which half they were looking at.

Loading a Match whose id cannot be resolved in a degraded, read-only form was also rejected — it invents an "unsupported Match" concept in the domain for a case that should not occur.

## Consequences

A Variant id becomes a persistence contract:

- **Ids are frozen once shipped.** Renaming one would orphan every Match that names it. The constraint is documented at the declaration and asserted per-Variant in `VariantTests`, so a future tidy-up fails the suite rather than silently orphaning data.
- **`okey-standard` was renamed to `okey-21` before any data existed**, resolving the long-standing mismatch between that id and its label at the last moment the rename was free rather than a migration.
- **A Match naming an unresolvable id is skipped, never deleted.** Its data is left untouched on disk, so a downgrade or a bad write stays recoverable when the app is updated again.

Entrants remain owned by their Match and are not shared across Matches: two Matches with a player called Alice hold two separate Entrants, exactly as today. Cross-Match player identity is a product decision about who "the same Alice" is and is out of scope here, but this is the cheap direction — the reverse would mean splitting one identity retroactively and guessing which Matches belong to whom. Should it be added later, it stays cheap provided the link runs from Entrant to a shared identity, is optional, nullifies rather than cascades on delete, is never inferred automatically from names (two players called Alice may be two different people, and a silent merge has no undo), and never assumes one person per Entrant — Okey 21's Entrants are teams of two.
