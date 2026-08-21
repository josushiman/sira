# 03 — The wall and the Unlock

**What to build:** The whole purchase, end to end. With three games used and no Unlock held, tapping Gonga or Okey raises the offer instead of opening the Variant picker; the player reads the price in their own currency, buys, and every trace of the paywall disappears. Once a device has seen a verified purchase it stays unlocked forever, offline included.

This is one ticket rather than several because splitting it produces either a dead end — a wall with no way past — or a horizontal slice: a sheet with no purchase behind it, or a purchase with nothing to reach it through. The fail-open rule is an acceptance criterion here rather than a follow-up, because shipping the naive entitlement check first and hardening it afterwards is precisely the outcome the spec was written to avoid.

**Blocked by:** 02

**Status:** ready-for-agent

**The seam**

- [ ] `UnlockStore` owns the product, the purchase, the restore and the entitlement, with StoreKit's operations injected the way `MatchStore` already injects `saveContext`, and for the same stated reason
- [ ] One StoreKit 2 non-consumable, verified on the device against Apple's signature — no receipt endpoint, no server, and no third-party purchase SDK, so the app stays wholly offline
- [ ] A single derived value — unlocked, free with a remainder, or locked — is the only thing the views read; neither Home nor the sheet touches StoreKit or counts Matches

**The wall**

- [ ] With no free games left and no Unlock, tapping Gonga or Okey raises the offer instead of opening the Variant picker
- [ ] Scoring a Round is never refused, by anything, in any state
- [ ] The check happens at Home only — not at Setup, and not at Start; letting a player choose a Variant and name four Entrants before refusing them is the version of this that reads as bait

**The sheet**

- [ ] Composes the existing `DecisionSheet` and `SheetButton`, presented over a dimmed Home that stays visible behind it, as the Rejoin offer and the delete confirmation already do
- [ ] Dismissing costs one tap and never leaves Home; the offer can be raised again afterwards
- [ ] The price shown is always StoreKit's `displayPrice` for the player's storefront — `£2.99` appears nowhere in the app's code or copy — and the layout holds for a longer localised price string
- [ ] No benefit line claims to unlock a Variant, team play, or any other feature; only the game count is gated, and claiming otherwise is inaccurate App Store metadata as well as untrue
- [ ] Four states, the last two inline on the sheet rather than as dialogs so the player can simply try again: default, purchase in flight with the app's own controls disabled, purchase failed, and Restore found nothing
- [ ] Restore is a control with legible contrast and a full-size hit target — it is the app's only Restore affordance — and is never called at launch, because it prompts for an Apple ID password
- [ ] Buying unlocks immediately, and every trace of the paywall disappears: the meter, the wall, the offer

**The entitlement**

- [ ] StoreKit returning nothing — offline, a cache that has never synced on this device, or the known family-sharing regressions — is not a refusal, and leaves a device that has ever seen a verified purchase unlocked
- [ ] An explicitly revoked or refunded transaction re-locks, returning the player to the meter
- [ ] Re-locking changes what the player can start and touches no Match, Round or Entrant; their history stays complete and readable
- [ ] The updates listener unlocks the app when a purchase arrives from elsewhere — another device, or a Family Sharing member — without the player buying anything in this session
- [ ] The local unlocked flag is written where the meter lives, and the code declaring it says plainly that it is a cache of a truth Apple owns rather than a source of truth

**Recording it**

- [ ] `CONTEXT.md` gains **Unlock** and **Locked**, the latter with an _Avoid_ line against using "locked" for an Archived Match or an Entrant who is Out
- [ ] An ADR records StoreKit 2 with no purchase SDK, with the offline-only property as the stated consequence
- [ ] An ADR records the fail-open rule — silence is not a refusal, explicit revocation is — with the asymmetry of costs as its reasoning

**Proving it**

- [ ] Driven through injected fakes: a successful purchase unlocks; a cancellation leaves the player as they were; a failure surfaces a message and leaves them locked; a revoked transaction re-locks; a restore that finds nothing says so; a purchase arriving through the updates stream unlocks
- [ ] **StoreKit returning nothing leaves a previously-unlocked player unlocked** — the single most important test in this ticket
- [ ] The derived value is asserted directly: unlocked regardless of the meter, free with the right remainder at zero, one and two consumed, locked at three
- [ ] Snapshot: all four sheet states in both themes, with every text-on-background pair clearing WCAG AA — `accent` is gold in Felt and dark green in Paper, so Paper is designed rather than recoloured. Prior art is `RejoinSheetSnapshotTests`
- [ ] The sheet's wording is asserted, as `DeleteMatchSheet.explanation(for:)` already is
- [ ] Demoable against Xcode's `.storekit` configuration: hit the wall, buy, unlock; kill the network and relaunch, still unlocked; revoke, and the meter returns with every game intact
