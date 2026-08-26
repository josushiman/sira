# StoreKit 2 directly, with no purchase SDK

Sıra sells one thing: the **Unlock**, a non-consumable that removes the three **Free Match** limit. The usual advice for shipping a purchase is to reach for RevenueCat, Adapty or Superwall, and we decided against all of them. The app talks to StoreKit 2 directly, verifies on the device, and keeps no server of any kind.

- **One product, one framework.** `UnlockStore.Operations.storeKit` is the whole integration: `Product.products(for:)` for the price, `product.purchase()` for the sale, `Transaction.currentEntitlements` for what this device holds, `Transaction.updates` for what arrives from elsewhere, and `AppStore.sync()` behind the sheet's Restore. It is one file, and it is the only file in the app that imports StoreKit.
- **Verification is Apple's signature, checked on the device.** StoreKit 2's `VerificationResult` is the whole of it. There is no receipt endpoint, nothing to deploy and nothing to keep running.
- **The price is StoreKit's `displayPrice`, always.** No number appears in the app's code or copy — `UnlockCopyTests` asserts it — so the price is correct in every storefront and a tier change in App Store Connect is not a release.

## Considered Options

**A purchase SDK** — RevenueCat and its equivalents — was rejected on what it is for. Those SDKs exist to solve subscriptions, renewals, trials, cross-platform entitlements, and an entitlement server you would otherwise have to run. Sıra has one non-consumable, no renewals, no other platform, no accounts and no server. There is no problem left for the SDK to solve.

What it would cost is specific and large for this app. Sıra is wholly offline: every Match is on the player's device and nothing about the app needs a network. Adding a purchase SDK adds a network dependency, a vendor, a third-party account holding data about the app's users, and a launch path that reaches somebody else's servers. That is a property worth more than the convenience of an SDK we would use one call from.

**A server of our own to verify receipts** was rejected for the same reason plus the $99-a-year framing: this paywall exists to cover an Apple Developer Program membership, and paying for hosting to protect a £2.99 purchase inverts the arithmetic it was built for.

**StoreKit 1** was not considered seriously. StoreKit 2's verification and its `async` surface are the reason a purchase can be done in one small file, and the deployment target is far above where it becomes available.

## Consequences

**The app stays wholly offline.** This is the property the decision was made for. A launch with no network reaches nothing — the entitlement comes from the local cache (`UnlockCache`) and the fail-open rule in [`0011`](0011-the-unlock-fails-open.md) — so a table in a basement or on a plane is scored exactly as one on wifi.

**StoreKit is not exercisable in tests, so it is injected.** `UnlockStore` takes an `Operations` struct of closures, the same technique `MatchStore` already uses for `saveContext`. Every rule the purchase has is driven through fakes in `UnlockStoreTests`; what is left untested is Apple's own payment sheet, which is checked by hand against Xcode's `.storekit` configuration and a sandbox tester before release.

**Nothing measures the paywall.** No SDK means no analytics, no conversion funnel, no experiments. That is out of scope by the spec rather than a loss here, and a decision to measure would be a decision to add a vendor.

**One product id ties the app to App Store Connect**: `com.10bitlabs.sira.unlock`, non-consumable, Family Sharing enabled. A second product would be a second decision — there is nothing in this design that generalises to a catalogue, and nothing here should be read as preparing for one.
