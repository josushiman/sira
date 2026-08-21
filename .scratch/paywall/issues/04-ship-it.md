# 04 — Ship it

**What to build:** The parts of the paywall that live outside the codebase. The product has to exist in App Store Connect before anything in ticket 03 can be bought for real, the listing has to disclose the free-game limit before anyone downloads it, and two behaviours can only be trusted after being seen on a real device.

Marked for a human rather than an agent: none of this can be done from a terminal.

**Blocked by:** 03

**Status:** ready-for-human

**App Store Connect**

- [ ] A non-consumable in-app purchase exists, with Family Sharing enabled
- [ ] The price is the £2.99 UK tier, with the base storefront chosen so other territories convert sensibly — Turkey is deliberately not priced here, as it launches later behind localisation
- [ ] Small Business Program enrolment is confirmed, so the commission is 15% rather than 30%
- [ ] The product identifier matches the one the app asks for, and the app returns a real localised price for it

**Listing**

- [ ] The description states that the first three games are free and that unlimited games are a one-off purchase, so that "free" is not a surprise on the App Store page
- [ ] The description claims nothing the purchase does not unlock — every Variant and team play are available in the free three
- [ ] Screenshots show the app, not the paywall

**Verifying the purchase for real**

- [ ] A sandbox Apple ID completes a purchase and the app unlocks
- [ ] Restore recovers the purchase on a second device signed into the same Apple ID
- [ ] A second Apple ID in the same Family Sharing group is unlocked without buying anything

**The two device checks the spec flags**

- [ ] A purchase started from the sheet presented over Home survives the payment sheet's presentation — presentation timing has already bitten this project once, when a sheet raised from a context menu needed a real device to trust
- [ ] A Family Sharing purchase arriving through the updates stream lifts the limit while Home is on screen
