The thing that's biting you

Your shared scheme has a local StoreKit config attached to the Run action:

sira.xcodeproj/xcshareddata/xcschemes/sira.xcscheme:63 → StoreKitConfigurationFileReference → Sira.storekit

So the build now on your phone is not talking to Apple at all. Purchases are served by that JSON file: fake money, instant success, no Apple Account involved, and the £2.99 on the sheet is the literal from the file, not App Store Connect. That's a great harness for the flow, and useless as a rehearsal for review. There are three tiers, and you want to walk all three.

---

Tier 1 — Local StoreKit config (works on your phone today)

Nothing to set up. Run to the device, start 3 matches, tap Gonga → the sheet appears.

Drive the edge cases from Xcode → Debug → StoreKit → Manage Transactions (device must be running from Xcode), and from the Sira.storekit editor's Editor menu:
- Ask to Buy — enable it in the config; you should land on .awaitingApproval ("we'll let you know"), then approving in Transaction Manager should unlock you with no further taps, via Transaction.updates.
- Refund a transaction in Transaction Manager → next launch should re-lock (that's Transaction.latest(for:) carrying revocationDate).
- Interrupted / failed purchases — toggles in the config editor's settings.

Gotcha specific to your design: deleting a transaction in Transaction Manager will not re-lock the app. UnlockStore.apply treats an empty entitlement list as silence, not refusal (ADR 0011), and the unlocked flag is cached in SwiftData (UnlockCache). To get back to a clean paywall state you must either refund the transaction, or delete the app from the phone — which is also what resets the 3-match tally (StartedMatchTally). Expect to be deleting the app a lot.

---

Tier 2 — Real sandbox on your phone (this is the one that de-risks submission)

In App Store Connect, first:
1. Agreements, Tax and Banking → Paid Applications agreement must be Active. If it isn't, Product.products(for:) returns empty, your sheet shows no price, and Buy fails with purchaseFailed. This is the single most common cause of "the paywall works locally but not on device".
2. App record exists for bundle ID com.10bitlabs.sira.
3. Create the IAP: Non-Consumable, Product ID exactly com.10bitlabs.sira.unlock, Family Sharing on (your config sets familyShareable: true), price point for 2.99, an en-US localization, review screenshot + notes. Get it to "Ready to Submit" — sandbox serves products in that state; it does not need to be approved first.
4. Users and Access → Sandbox → Test Accounts → +. Use an email address you control that has never been an Apple ID (you+sandbox1@… works).

On the phone:
5. Settings → Developer → Sandbox Apple Account → sign in as the tester. Do not sign out of your real Apple Account in the App Store app.

In Xcode:
6. Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration → None. Without this you're still in Tier 1. Note this scheme is shared and checked in, so the change shows in git status — either revert it before committing, or duplicate the scheme (e.g. sira-sandbox) and mark it unshared.
7. Build & run to the device.

You should now get Apple's real payment sheet with [Environment: Sandbox] on it, no charge. Verify: the price comes from App Store Connect (not 2.99 from the file), Buy unlocks, Restore purchase works after deleting and reinstalling the app, and "Have a promo code?" opens Apple's redemption sheet. To buy again, clear the tester's purchase history under its entry in App Store Connect → Sandbox → Test Accounts.

---

Tier 3 — TestFlight (final rehearsal)

Upload a build, add yourself as an internal tester. TestFlight runs against sandbox automatically using your real Apple Account — no sandbox tester, no scheme fiddling, no Xcode attached. This is the closest thing to what the reviewer sees, and worth one pass before you submit.

---

Two things for submission itself

- On a first release the IAP must be attached to the app version in App Store Connect (the version page's In-App Purchases section) or it won't be reviewed with the binary — a very common rejection/limbo.
- Reviewers test Restore purchase explicitly. Confirm Tier 2 step: delete app → reinstall → Restore → unlocked.

One thing I'd flag: your Sira.storekit has empty _developerTeamID and _applicationInternalID, so it's a standalone local file rather than one synced from App Store Connect. Once the product exists in ASC, "Sync with App Store Connect" in the config editor keeps the local prices honest — optional, but it stops Tier 1 drifting from reality.

I checked the scheme, the StoreKit config, StoreKitUnlock.swift, UnlockStore.swift, GameAccess/FreeMatches (allowance = 3), and the caching in UnlockCache/StartedMatchTally to confirm the reset behaviour above.

result: Paywall device-testing guide — the checked-in scheme's local StoreKit config is intercepting purchases; detach it, create the com.10bitlabs.sira.unlock non-consumable in App Store Connect with an active Paid Apps agreement, and sign in a sandbox tester under Settings → Developer for a real end-to-end test.