import Foundation

/// Everything about the Unlock: the product, buying it, restoring it, the
/// entitlement behind it, and the rule that decides what silence from Apple
/// means.
///
/// The one place in the app that knows a purchase exists. StoreKit itself is
/// injected rather than called from here — the same technique `MatchStore`
/// already uses for `saveContext`, and for the same stated reason: none of it
/// can be exercised in a test. Production wires `Operations.storeKit`; tests
/// hand over fakes and drive every path this type has.
///
/// What it does *not* own is the local flag. That is durable state, so it is
/// written where every other durable thing is written (`MatchStore`), through
/// the `Cache` seam below — which keeps this type free of SwiftData and keeps
/// the Unlock and the meter durable in one place.
@MainActor
@Observable
final class UnlockStore {
    /// Whether this device holds the Unlock, as far as anything can tell right
    /// now. Read through `GameAccess` rather than directly by any view.
    ///
    /// Starts from the cache, which is what makes a launch with no network the
    /// same launch as any other for a player who has paid.
    private(set) var isUnlocked: Bool

    /// StoreKit's price for this player's storefront, or `nil` until it has
    /// answered. The only price the app ever shows: there is no literal
    /// anywhere in the code or the copy, so the number is right in every
    /// currency without anyone keeping a table of them.
    private(set) var displayPrice: String?

    /// What the sheet is doing, and the only thing that changes what it draws.
    private(set) var status: Status = .ready

    private let operations: Operations
    private let cache: Cache

    init(operations: Operations, cache: Cache) {
        self.operations = operations
        self.cache = cache
        self.isUnlocked = cache.read()
    }

    /// What the sheet is in the middle of.
    ///
    /// The failure states are messages shown *on* the sheet rather than dialogs
    /// over it, so that trying again is the tap the player already has their
    /// thumb over. Nothing here is an error to be reported and cleared
    /// somewhere else; it is the state of one sheet.
    enum Status: Equatable {
        /// Nothing in flight. What the sheet opens in, and what it returns to.
        case ready
        /// A purchase or a Restore is with Apple. The app's own controls are
        /// disabled while it is — Apple draws the payment sheet itself, and two
        /// sets of live buttons over each other is how a second purchase gets
        /// attempted.
        case inFlight
        /// It did not go through, and no money moved. The wording is the
        /// player's, not StoreKit's.
        case purchaseFailed(String)
        /// Restore reached Apple and there was nothing to find. Not a failure —
        /// an answer — and said plainly rather than left as a screen that did
        /// nothing.
        case nothingToRestore
        /// The purchase needs someone else's approval (Ask to Buy). It has not
        /// finished and it has not failed: it arrives later through the updates
        /// stream, which unlocks the app without the player doing anything.
        case awaitingApproval
    }

    /// A verified transaction for the Unlock, reduced to the one thing the rule
    /// turns on. Everything else StoreKit knows about it is StoreKit's.
    struct Entitlement: Equatable {
        /// Whether Apple has explicitly taken it back — a refund, or a Family
        /// Sharing group the player has left.
        let isRevoked: Bool
    }

    /// What a tap on Restore came back as.
    enum RestoreOutcome: Equatable {
        /// Apple re-delivered whatever this Apple Account holds. Whether that
        /// was anything is the entitlements' answer, not this one.
        case finished
        /// The player dismissed Apple's password prompt. Not an error, and
        /// nothing to say about it — the same non-event that backing out of
        /// the payment sheet is.
        case cancelled
        /// It could not be done. Offline, most likely.
        case failed
    }

    /// What a tap on Buy came back as.
    enum PurchaseOutcome: Equatable {
        case unlocked
        /// The player backed out of Apple's payment sheet. Not an error, and
        /// nothing to say about it: they land exactly where they were.
        case cancelled
        case awaitingApproval
        case failed(String)
    }

    /// The StoreKit operations, injected. A struct of closures rather than a
    /// protocol: there is exactly one production conformance and one fake per
    /// test, and a fake is then three lines rather than a type.
    struct Operations {
        /// The localised price, or `nil` if the product could not be reached.
        var displayPrice: () async -> String?
        /// Buys it, through Apple's own payment sheet.
        var purchase: () async -> PurchaseOutcome
        /// Asks Apple to re-deliver this Apple Account's purchases. Prompts for
        /// a password, which is why nothing calls it at launch.
        ///
        /// Hands back an outcome rather than throwing, so that telling a
        /// cancellation apart from a failure stays in the one file that
        /// imports StoreKit. `UnlockStore` would otherwise have to read
        /// StoreKit's own error taxonomy to know which of the two it had.
        var restore: () async -> RestoreOutcome
        /// What StoreKit currently says this device is entitled to. An empty
        /// answer is silence, not a refusal — see `apply(_:)`.
        var entitlements: () async -> [Entitlement]
        /// Transactions arriving from elsewhere: another device, a Family
        /// Sharing member, an approved Ask to Buy, or a revocation.
        var updates: () -> AsyncStream<Entitlement>
        /// Hands the screen to the App Store so the player can type a promo
        /// code. Returns nothing, and cannot: see `redeemCode()`.
        var presentCodeRedemption: () -> Void
    }

    /// Where the local unlocked flag is kept between launches — read at init,
    /// written whenever StoreKit says something definite.
    ///
    /// A seam rather than a direct call into `MatchStore` so that this type
    /// stays free of the database, and so that a test can drive the entitlement
    /// rules without one.
    struct Cache {
        var read: () -> Bool
        var write: (Bool) -> Void

        /// The app's own: beside the meter, in the database (`UnlockCache`).
        static func stored(in store: MatchStore) -> Cache {
            Cache(read: { store.hasSeenUnlock }, write: { store.recordUnlock(seen: $0) })
        }

        /// A cache that lives as long as the value it hands back — previews,
        /// and tests that want a relaunch without a file.
        static func inMemory(hasSeenUnlock: Bool = false) -> Cache {
            let box = Box(value: hasSeenUnlock)
            return Cache(read: { box.value }, write: { box.value = $0 })
        }

        private final class Box: @unchecked Sendable {
            var value: Bool
            init(value: Bool) { self.value = value }
        }
    }

    /// The app's first word to StoreKit, at launch: the price, and what this
    /// device is entitled to.
    ///
    /// Deliberately not a Restore. Restoring prompts for an Apple Account
    /// password, and an app that asks for one before the player has done
    /// anything is an app that gets deleted — so Restore is a control on the
    /// sheet, and nothing else ever calls it.
    func prepare() async {
        displayPrice = await operations.displayPrice()
        await refreshEntitlements()
    }

    /// Watches for transactions arriving from anywhere but this session — a
    /// second device, a Family Sharing member, an approved Ask to Buy, a
    /// revocation — and applies each as it comes.
    ///
    /// Runs for as long as the app does, which is why it is a `for await` the
    /// caller holds rather than something started and forgotten in here.
    func observeUpdates() async {
        for await entitlement in operations.updates() {
            // A revocation is the one kind of update that cannot be read on
            // its own. It says one transaction has been taken back; it does
            // not say the player has nothing left. A player who bought the
            // Unlock and is also in a family group that holds one has two, and
            // a refund of theirs would otherwise lock an app they are still
            // entitled to — mid-evening, at a table, which `apply(_:)` spells
            // out as the expensive direction to be wrong in.
            //
            // So a revocation is applied against the whole picture rather than
            // alone. The arriving transaction goes in with it, which is what
            // keeps a genuine last-one-revoked re-locking: StoreKit answering
            // nothing would otherwise be silence, and silence leaves the
            // device as it was.
            if entitlement.isRevoked {
                apply(await operations.entitlements() + [entitlement])
            } else {
                apply([entitlement])
            }
        }
    }

    /// Asks StoreKit what this device is entitled to, and applies the answer.
    func refreshEntitlements() async {
        apply(await operations.entitlements())
    }

    func purchase() async {
        // Two taps landing before Apple's sheet is up are two purchases
        // started. The sheet disables itself while a purchase is in flight,
        // but only once this method has run far enough to say so — and a
        // second tap in the hop before that has already been dispatched. The
        // guard belongs here, where the state actually changes, rather than in
        // the view that reads it.
        guard status != .inFlight else { return }
        status = .inFlight
        switch await operations.purchase() {
        case .unlocked:
            setUnlocked(true)
            status = .ready
        case .cancelled:
            // Exactly as they were. A player who backed out of Apple's sheet
            // has not been told anything and does not need to be told anything.
            status = .ready
        case .awaitingApproval:
            status = .awaitingApproval
        case let .failed(message):
            status = .purchaseFailed(message)
        }
    }

    /// The sheet's Restore: reaches Apple, re-reads the entitlements, and says
    /// plainly when there was nothing to find.
    func restore() async {
        status = .inFlight
        switch await operations.restore() {
        case .finished:
            break
        case .cancelled:
            // Dismissing Apple's password prompt is not a failed Restore, and
            // saying "Sıra couldn't reach the App Store" to a player who
            // simply changed their mind is a lie about their network. The same
            // non-event a cancelled purchase is, treated the same way.
            status = .ready
            return
        case .failed:
            status = .purchaseFailed(UnlockCopy.restoreFailed)
            return
        }
        await refreshEntitlements()
        status = isUnlocked ? .ready : .nothingToRestore
    }

    /// The sheet's promo code: hands the player to the App Store to type one.
    ///
    /// The code itself is Apple's — issued in App Store Connect against the
    /// Unlock, typed into Apple's own redemption sheet, and redeemed as a
    /// purchase of the product at no charge. The app never sees it, never
    /// validates one, and has no code of its own: unlocking paid functionality
    /// on a string the app checked itself is a purchase made outside In-App
    /// Purchase, which is not something Sıra is allowed to do.
    ///
    /// **Not `async`, and deliberately not `.inFlight`.** Presenting that sheet
    /// hands back nothing at all — no result, no completion, no notice that it
    /// was dismissed. A status set here would be a status with nothing to clear
    /// it, and a player who opened the sheet and changed their mind would come
    /// back to this one disabled for good.
    ///
    /// So nothing here waits for an answer, because the answer does not come
    /// back this way. A redeemed code reaches the app as a transaction on
    /// `updates` — the same path a purchase made on another device takes — and
    /// `observeUpdates` unlocks on it. A code the player never typed arrives as
    /// nothing, which is exactly right.
    func redeemCode() {
        operations.presentCodeRedemption()
    }

    /// Puts the sheet back to its default — what dismissing it does, so that
    /// raising it again is a fresh offer rather than the last failure still on
    /// screen.
    func clearStatus() {
        status = .ready
    }

    /// The rule the whole entitlement design turns on: **silence is not a
    /// refusal** (`docs/adr/0011`).
    ///
    /// Nothing at all from StoreKit — offline, a cache that has never synced on
    /// this device, or the known family-sharing regressions — leaves the device
    /// exactly as it was, which for a player who has ever seen a verified
    /// purchase means unlocked. Only an answer that arrives and is explicitly
    /// revoked re-locks.
    ///
    /// The asymmetry is deliberate, because the costs are not symmetrical.
    /// Wrongly staying unlocked costs at most one purchase somebody has already
    /// made on another device. Wrongly locking hits a paying player mid-evening,
    /// at a table, with the tally half-written.
    private func apply(_ entitlements: [Entitlement]) {
        guard !entitlements.isEmpty else { return }
        setUnlocked(entitlements.contains { !$0.isRevoked })
    }

    private func setUnlocked(_ unlocked: Bool) {
        isUnlocked = unlocked
        cache.write(unlocked)
    }
}

extension UnlockStore {
    /// A store over a StoreKit that says nothing at all, unlocked or not as the
    /// caller needs — previews and view tests, which draw Home and the sheet
    /// but buy nothing.
    ///
    /// The counterpart to `MatchStore.seeded()`: the fake every view needs,
    /// built in one place rather than assembled at each call site.
    static func silent(unlocked: Bool = false) -> UnlockStore {
        UnlockStore(operations: .silent, cache: .inMemory(hasSeenUnlock: unlocked))
    }
}

extension UnlockStore.Operations {
    /// A StoreKit that says nothing at all: no price, no entitlements, no
    /// updates, and a purchase that cannot be made.
    ///
    /// What previews and view tests run against — nothing in either is buying
    /// anything, and neither should be able to. By the fail-open rule it leaves
    /// the device exactly as its cache found it, which is also what makes it
    /// the honest stand-in for a device with no network.
    static let silent = UnlockStore.Operations(
        displayPrice: { nil },
        purchase: { .failed(UnlockCopy.purchaseFailed) },
        restore: { .finished },
        entitlements: { [] },
        updates: { AsyncStream { $0.finish() } },
        presentCodeRedemption: {}
    )
}
