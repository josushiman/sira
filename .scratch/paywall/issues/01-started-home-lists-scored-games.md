# 01 — Started: Home lists games that have been scored

**What to build:** A Match that has never been scored stops being history. Home lists only Matches with at least one Round on them, so a Match set up and abandoned never appears there and does not have to be tidied away by hand. This lands first because it is worth having on its own — a mis-tap at Setup currently leaves an empty Match on Home forever — and because it is what lets the paywall be enforced in one place instead of two.

**Blocked by:** None — can start immediately

**Status:** done

- [x] A Match becomes Started the first time a Round is scored on it, carried by a flag on the Match rather than inferred from its Round count
- [x] Started is permanent: undoing the only Round leaves the Match Started, and scoring another Round does not Start it a second time
- [x] Home's card list shows Started Matches only, in the Active, All and Archived filters alike
- [x] The route into Play still resolves a Match that Home does not list, so Setup hands Play an un-Started Match exactly as it does today — Home already resolves the route from the unfiltered query rather than from the card list, and that separation is the reason this works
- [x] Backing out of Play before scoring the first Round leaves nothing on Home
- [x] An un-Started Match left in the store — abandoned, or stranded by iOS reclaiming the app — is deleted at launch
- [x] A Started Match whose only Round has been undone stays on Home; this is the case that breaks if the filter tests the Round count instead of the flag
- [x] Archive, Restore and Delete keep their current meanings and are unaffected
- [x] `CONTEXT.md` gains a **Started** entry, defined against **Archived** (which hides a Started Match) and **Delete** (which removes one), with an _Avoid_ line against "created" and against "in progress"
- [x] Snapshot: Home with only an un-Started Match in the store reads as empty, in both themes
- [x] Prior art for the tests is `MatchFilterTests` for Home's list being a view rather than the whole store, and `NavigatorTests` for the route
