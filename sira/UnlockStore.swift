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
        var restore: () async throws -> Void
        /// What StoreKit currently says this device is entitled to. An empty
        /// answer is silence, not a refusal — see `apply(_:)`.
        var entitlements: () async -> [Entitlement]
        /// Transactions arriving from elsewhere: another device, a Family
        /// Sharing member, an approved Ask to Buy, or a revocation.
        var updates: () -> AsyncStream<Entitlement>
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
            apply([entitlement])
        }
    }

    /// Asks StoreKit what this device is entitled to, and applies the answer.
    func refreshEntitlements() async {
        apply(await operations.entitlements())
    }

    func purchase() async {
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
        do {
            try await operations.restore()
        } catch {
            status = .purchaseFailed(UnlockCopy.restoreFailed)
            return
        }
        await refreshEntitlements()
        status = isUnlocked ? .ready : .nothingToRestore
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
        restore: {},
        entitlements: { [] },
        updates: { AsyncStream { $0.finish() } }
    )
}
