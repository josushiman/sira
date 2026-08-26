# The Unlock fails open: silence is not a refusal

Every entitlement check has to decide what to do when StoreKit says nothing. We decided that **nothing is not a refusal**: a device that has ever seen a verified purchase stays Unlocked when StoreKit returns an empty answer, and re-locks only when a transaction arrives that is explicitly revoked or refunded.

- **Silence changes nothing.** `UnlockStore.apply(_:)` returns early on an empty list. Offline, a StoreKit cache that has never synced on this device, and the known Family Sharing regressions all produce exactly that empty list, and all three leave the player where they were.
- **An explicit revocation re-locks.** A verified transaction carrying a `revocationDate` — a refund, or a Family Sharing group the player has left — sets the flag back to false and returns the player to the meter.
- **The local flag is a cache, not a source of truth.** `UnlockCache` is one row beside the meter, written only from what StoreKit said, and its own doc comment says as much. Nothing in the app is allowed to treat it as permission the app granted itself.

## Considered Options

**Locking whenever StoreKit does not confirm** is the naive check and the one this decision exists to rule out. It is a single expression, it looks correct, and it is wrong in the exact circumstance the app is used in: four people at a table, one phone, no signal.

**Refreshing the entitlement at launch with `AppStore.sync()`** was rejected because syncing prompts for an Apple Account password. An app that asks for one before the player has done anything is an app that gets deleted, so `sync()` is reached only from the sheet's Restore, where the player asked for it.

**Treating an unverified transaction as a purchase** was rejected in the other direction. Unverified means Apple's signature does not vouch for it, which is the one case that is not a purchase at all — it is reported as a failure rather than trusted.

## The asymmetry, which is the whole argument

The two ways of being wrong do not cost the same.

Wrongly staying unlocked costs, at most, one £2.99 that somebody has already paid on another device — and in the most common shape of the error, a family member's purchase resolving late. That is a rounding error against a paywall whose entire purpose is to clear a $99 annual membership.

Wrongly locking hits a paying customer mid-evening, at a table, with a tally half-written and a game in progress. The spec this feature comes from was written around one failure: *someone reaching for a pen and never opening the app again*. A false lock is precisely that failure, delivered to the person who has already paid.

Given the costs, the app errs in the direction that cannot produce that outcome. `test_storeKitReturningNothingLeavesAPreviouslyUnlockedPlayerUnlocked` is where the rule is pinned down, and it is the single most important test in the paywall.

## Consequences

**Re-locking changes what a player may start and nothing else.** Every Match, Round and Entrant stays exactly where it is, complete, readable and scorable. A refund costs the player the limit, never their history — `test_reLockingTouchesNoMatchRoundOrEntrant`.

**A revocation is noticed through `Transaction.updates`, not through a gap.** `Transaction.currentEntitlements` simply stops listing a revoked purchase, which under this rule reads as silence and changes nothing. The revoked transaction is delivered explicitly on the updates stream instead, which is what re-locks the app. A device that is offline when a refund is issued therefore stays unlocked until it next hears from Apple, and that is the intended behaviour rather than a gap in it.

**Deleting the app resets the meter but not the entitlement.** The cache goes with the app, and StoreKit restores a non-consumable for the same Apple Account, so a reinstalling player who paid is unlocked again without touching anything. A reinstalling player who did not gets three fresh Free Matches — a choice recorded in the spec, not an oversight: a trial counter hidden in the Keychain to survive deletion is the kind of thing players notice and resent.
