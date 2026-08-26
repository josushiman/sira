# 04 — Ship it

**What to build:** The parts of the paywall that live outside the codebase. The product has to exist in App Store Connect before anything in ticket 03 can be bought for real, the listing has to disclose the free-game limit before anyone downloads it, and a handful of behaviours can only be trusted after being seen on a real device.

Promo code redemption (ticket 05) lands here too, and lands here entirely: Xcode's StoreKit testing has no redemption sheet, the simulator cannot open one, and codes are not issued until the app is approved. Every assertion the suite can make about it has been made — that the tap hands over to the App Store, that it leaves the sheet usable, that a transaction arriving afterwards unlocks — and none of them prove a real code works.

Marked for a human rather than an agent: none of this can be done from a terminal.

**Blocked by:** 03, 05

**Status:** ready-for-human

**App Store Connect**

- [ ] A non-consumable in-app purchase exists, with Family Sharing enabled
- [ ] The price is the £2.99 UK tier, with the base storefront chosen so other territories convert sensibly — Turkey is deliberately not priced here, as it launches later behind localisation
- [ ] Small Business Program enrolment is confirmed, so the commission is 15% rather than 30%
- [ ] The product identifier matches the one the app asks for, and the app returns a real localised price for it
- [ ] Promo codes are generated against the Unlock product, and the limits are confirmed rather than taken from ticket 05's note — 100 per app per version, expiring 28 days after issue, and available only once the app is approved

**Listing**

- [ ] The description states that the first three games are free and that unlimited games are a one-off purchase, so that "free" is not a surprise on the App Store page
- [ ] The description claims nothing the purchase does not unlock — every Variant and team play are available in the free three
- [ ] Screenshots show the app, not the paywall

**Verifying the purchase for real**

- [ ] A sandbox Apple ID completes a purchase and the app unlocks
- [ ] Restore recovers the purchase on a second device signed into the same Apple ID
- [ ] A second Apple ID in the same Family Sharing group is unlocked without buying anything

**Verifying the promo code for real**

Not testable anywhere before this point: promo codes need an approved app, and the redemption sheet does not exist in the simulator or in Xcode's StoreKit testing. Everything below is a by-hand pass on a real device, against TestFlight or the released build.

- [ ] "Have a promo code?" on the offer sheet raises the App Store's own redemption sheet, over the offer, without dismissing it
- [ ] A valid code redeems and the app unlocks — the wall lifts, the meter goes, and the offer comes down without the player tapping anything else, because the transaction arrives on the updates stream rather than through the tap
- [ ] **Dismissing Apple's sheet without typing anything leaves the offer exactly usable** — Buy still buys, Restore still restores. This is the one the code is written around: presenting that sheet reports nothing back, not even a dismissal, so nothing in the app can un-disable a sheet it disabled on the way in
- [ ] An expired or already-redeemed code is refused by Apple, and refused *on Apple's sheet* — Sıra shows no error of its own, because it never learns that anything happened
- [ ] A code redeemed on one device unlocks the player's other devices, and their Family Sharing group, exactly as a paid purchase does
- [ ] A redemption arriving while Home is on screen lifts the limit there and then, without a relaunch

**The two device checks the spec flags**

- [ ] A purchase started from the sheet presented over Home survives the payment sheet's presentation — presentation timing has already bitten this project once, when a sheet raised from a context menu needed a real device to trust
- [ ] A Family Sharing purchase arriving through the updates stream lifts the limit while Home is on screen
