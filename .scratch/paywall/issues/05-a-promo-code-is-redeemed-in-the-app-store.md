# 05 — A promo code is redeemed in the App Store

**What to build:** A player holding a promo code for the Unlock can redeem it without leaving the offer. A quiet link at the foot of the sheet hands them to the App Store's own redemption sheet; the code is typed there, and Sıra unlocks when Apple delivers the transaction.

**Blocked by:** 03

**Status:** done

**The constraint this ticket is written around**

The Unlock is a non-consumable, so a "promo code" here is an App Store Connect promo code and nothing else. Two consequences, both load-bearing:

- **The app never sees a code.** No field, no validation, no list of codes of its own. Unlocking paid functionality on a string the app checked itself is a purchase made outside In-App Purchase — guideline 3.1.1 — and it would also mean the entitlement had a second, unverifiable source. The tap opens Apple's sheet and Apple owns the keyboard.
- **`SKPaymentQueue`, not StoreKit 2.** `AppStore.presentOfferCodeRedeemSheet(in:)` and the `.offerCodeRedemption` modifier redeem *subscription* offer codes; there is no StoreKit 2 equivalent for a non-consumable's promo codes. `SKPaymentQueue.default().presentCodeRedemptionSheet()` is the only in-app route, and it lives alongside the StoreKit 2 the rest of the file is written in.

**The seam**

- [x] `UnlockStore.Operations` gains `presentCodeRedemption`, injected like every other StoreKit call, so the tap is driven by a fake and nothing in the test suite can reach the App Store
- [x] `StoreKitUnlock` wires it to `SKPaymentQueue.default().presentCodeRedemptionSheet()`, and says in the code why it is StoreKit 1 in a StoreKit 2 file
- [x] `Operations.silent` presents nothing, so previews and view tests keep buying and redeeming nothing

**The wait that isn't**

- [x] `UnlockStore.redeemCode()` is **not** `async` and does **not** set `.inFlight`. Presenting the sheet hands back nothing — no result, no completion, not even a dismissal — so a status set on the way in would have nothing to clear it, and a player who changed their mind would come back to a sheet disabled for good
- [x] A redeemed code arrives as a transaction on the existing updates stream and unlocks through `observeUpdates`, exactly as a purchase made on another device does. No new unlock path, and the fail-open rule (`docs/adr/0011`) is untouched
- [x] The wall lifts and the sheet comes down on `isUnlocked` flipping, which HomeView already watches

**The sheet**

- [x] A tertiary underlined link below the `Not now` / `Restore purchase` row, not a fourth `SheetButton` — a code is something a player either has in hand or has never heard of, and for everyone in the second group a full-width control is a fourth thing to read before deciding
- [x] The whole line is the hit target, not the words alone
- [x] The wording is a question addressed to the player who already has one, and never says "enter" or "redeem" a code here, because nothing is entered here

**Proving it**

- [x] The tap hands over to the App Store exactly once, through a fake
- [x] It leaves `status == .ready` and the sheet usable — the regression a dismissal with no callback would otherwise cause
- [x] A transaction arriving on the updates stream afterwards unlocks
- [x] The new line is covered by `UnlockCopyTests` — it names no price, like every other line
- [x] Contrast: the link is caption-sized and held to the AA *body* threshold in both themes, and the benefit cards are measured against their own composited fill rather than the sheet behind them
- [x] All twelve sheet snapshots re-recorded in both themes
- [ ] Demoable end to end: promo codes need a live, approved app and cannot be exercised against `Sira.storekit` or the simulator — Xcode's StoreKit testing has no redemption sheet. Verifying an actual code belongs with the release checks on ticket 04

**Note:** the last box cannot be ticked before the app is approved. App Store Connect issues promo codes per in-app-purchase product, 100 per app per version, expiring 28 days after issue — worth confirming against App Store Connect at release rather than trusting this line.
