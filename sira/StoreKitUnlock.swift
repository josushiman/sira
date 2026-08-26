import Foundation
import StoreKit

/// The app's one conversation with the App Store: a single non-consumable,
/// bought and verified on the device (`docs/adr/0010`).
///
/// The only file that imports StoreKit, which is the point of the seam it fills
/// in. Everything above it — the entitlement rule, the sheet, the wall — is
/// driven by values, so all of it is exercised in tests and none of it can be.
///
/// There is no receipt endpoint, no server and no third-party purchase SDK.
/// Verification is StoreKit 2's own check of Apple's signature against the
/// device, which is why an app with no network of its own can sell something.
extension UnlockStore.Operations {
    /// What ties this to App Store Connect. One product, matching the bundle
    /// identifier, non-consumable, Family Sharing enabled.
    ///
    /// `nonisolated` for the same reason `transactionUpdates()` below is: this
    /// type inherits `UnlockStore`'s main actor, and a string constant that
    /// cannot be read from off it is a constant that cannot be read from the
    /// stream this file opens.
    nonisolated static let productID = "com.10bitlabs.sira.unlock"

    static let storeKit = UnlockStore.Operations(
        displayPrice: { await unlockProduct()?.displayPrice },
        purchase: purchaseUnlock,
        restore: restore,
        entitlements: currentEntitlements,
        updates: transactionUpdates,
        presentCodeRedemption: presentCodeRedemption
    )

    /// Asks Apple to re-deliver this Apple Account's purchases.
    ///
    /// The cancellation is told apart from the failure here, in the one file
    /// that imports StoreKit, rather than by handing `UnlockStore` an error to
    /// interpret. `AppStore.sync()` prompts for an Apple Account password, and
    /// a player who dismisses that prompt has not failed to restore anything —
    /// they have changed their mind, which is the same non-event that backing
    /// out of the payment sheet is.
    private static func restore() async -> UnlockStore.RestoreOutcome {
        do {
            try await AppStore.sync()
            return .finished
        } catch StoreKitError.userCancelled {
            return .cancelled
        } catch {
            return .failed
        }
    }

    /// The App Store's own "Redeem Gift Card or Code" sheet.
    ///
    /// `SKPaymentQueue` rather than StoreKit 2, and not an oversight. StoreKit
    /// 2's `AppStore.presentOfferCodeRedeemSheet(in:)` redeems *subscription*
    /// offer codes and nothing else; the Unlock is a non-consumable, and the
    /// codes App Store Connect issues against it are promo codes, which this
    /// sheet is the only in-app way to redeem. The rest of this file stays
    /// StoreKit 2 — the two live alongside each other, and this is a
    /// presentation call rather than a second purchase path.
    ///
    /// Hands back nothing: no result, no completion, no notice of dismissal.
    /// What a redeemed code becomes is a transaction on `transactionUpdates`,
    /// arriving exactly as a purchase made on another device does — which is
    /// why nothing above this waits on it (`UnlockStore.redeemCode`).
    ///
    /// `nonisolated` for the reason `transactionUpdates()` is: a synchronous
    /// member of this main-actor-inheriting type, referenced as a function
    /// value from `storeKit` above, is a main-actor call from a nonisolated
    /// context. The queue is safe from anywhere, and the sheet it presents is
    /// UIKit's to raise.
    nonisolated private static func presentCodeRedemption() {
        SKPaymentQueue.default().presentCodeRedemptionSheet()
    }

    private static func unlockProduct() async -> Product? {
        try? await Product.products(for: [productID]).first
    }

    private static func purchaseUnlock() async -> UnlockStore.PurchaseOutcome {
        guard let product = await unlockProduct() else {
            return .failed(UnlockCopy.purchaseFailed)
        }
        do {
            switch try await product.purchase() {
            case let .success(verification):
                // An unverified transaction is one Apple's signature does not
                // vouch for, which is the one case that is not a purchase at
                // all — so it is reported as a failure rather than trusted.
                guard case let .verified(transaction) = verification else {
                    return .failed(UnlockCopy.purchaseFailed)
                }
                await transaction.finish()
                return .unlocked
            case .userCancelled:
                return .cancelled
            case .pending:
                return .awaitingApproval
            @unknown default:
                return .failed(UnlockCopy.purchaseFailed)
            }
        } catch {
            return .failed(UnlockCopy.purchaseFailed)
        }
    }

    /// What this device is entitled to, right now, as far as StoreKit's local
    /// cache knows.
    ///
    /// Empty is the answer offline, and on a device whose cache has never
    /// synced — which is exactly the silence `UnlockStore` refuses to read as a
    /// refusal (`docs/adr/0011`).
    ///
    /// Two sources, because neither alone answers both halves of the rule.
    /// `currentEntitlements` is what the player holds — a purchase of their
    /// own, or a Family Sharing member's — but it says nothing about a
    /// revocation: it simply stops listing a refunded purchase, which under the
    /// fail-open rule reads as silence and would leave the app unlocked for
    /// good. `Transaction.latest(for:)` still carries that transaction,
    /// `revocationDate` and all, so a refund taken while the app was closed
    /// re-locks at the next launch rather than waiting on an update that has
    /// already been delivered and finished once.
    ///
    /// Both go into one list, and `UnlockStore` applies its rule to the whole
    /// of it: any transaction still standing unlocks. A player whose own
    /// purchase was refunded but who is in a family group that still holds one
    /// is therefore unlocked, which is the truth about what they may play.
    private static func currentEntitlements() async -> [UnlockStore.Entitlement] {
        var found: [UnlockStore.Entitlement] = []
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result,
                  transaction.productID == productID else { continue }
            found.append(UnlockStore.Entitlement(isRevoked: transaction.revocationDate != nil))
        }
        if let latest = await Transaction.latest(for: productID),
           case let .verified(transaction) = latest {
            found.append(UnlockStore.Entitlement(isRevoked: transaction.revocationDate != nil))
        }
        return found
    }

    /// Transactions that arrive without the player buying anything in this
    /// session: a purchase made on their other device, a Family Sharing
    /// member's, an Ask to Buy that has been approved, or a revocation.
    ///
    /// Each is finished as it is taken, which is what stops StoreKit
    /// re-delivering it at every launch.
    ///
    /// `nonisolated` because it is handed over as a function value rather than
    /// called: `Operations` is nested in a main-actor type and inherits that
    /// isolation, so a *synchronous* member of it referenced from the
    /// `storeKit` initialiser below is a main-actor call from a nonisolated
    /// context — a warning today and an error under the Swift 6 language mode.
    /// The same trap `HomeView.filteredMatches` documents about
    /// `.map(HomeCard.init)`. Nothing in here touches main-actor state; it opens
    /// a stream and hands it back, and the values that come out of it are
    /// applied by `UnlockStore` on the main actor as before. The `async`
    /// members alongside it need no such annotation — an `await` gets to the
    /// actor on its own.
    nonisolated private static func transactionUpdates() -> AsyncStream<UnlockStore.Entitlement> {
        AsyncStream { continuation in
            let task = Task {
                for await result in Transaction.updates {
                    guard case let .verified(transaction) = result,
                          transaction.productID == productID else { continue }
                    await transaction.finish()
                    continuation.yield(
                        UnlockStore.Entitlement(isRevoked: transaction.revocationDate != nil)
                    )
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
