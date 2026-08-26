import XCTest
@testable import sira

/// The purchase, end to end, through injected fakes — none of it can touch the
/// App Store.
///
/// What each test asserts is what a player would notice: whether they are
/// unlocked, and what the sheet says to them. Nothing here inspects StoreKit or
/// counts calls into it.
@MainActor
final class UnlockStoreTests: XCTestCase {
    /// A StoreKit that answers however the test needs it to. Everything
    /// defaults to the quietest possible answer — no price, no entitlements,
    /// nothing arriving — so each test names only the thing it is about.
    private func operations(
        displayPrice: String? = nil,
        purchase: UnlockStore.PurchaseOutcome = .cancelled,
        restore: @escaping () async throws -> Void = {},
        entitlements: [UnlockStore.Entitlement] = [],
        updates: AsyncStream<UnlockStore.Entitlement> = AsyncStream { $0.finish() }
    ) -> UnlockStore.Operations {
        UnlockStore.Operations(
            displayPrice: { displayPrice },
            purchase: { purchase },
            restore: restore,
            entitlements: { entitlements },
            updates: { updates }
        )
    }

    private func store(
        _ operations: UnlockStore.Operations,
        cache: UnlockStore.Cache = .inMemory()
    ) -> UnlockStore {
        UnlockStore(operations: operations, cache: cache)
    }

    private let held = UnlockStore.Entitlement(isRevoked: false)
    private let revoked = UnlockStore.Entitlement(isRevoked: true)

    // MARK: - Buying

    func test_aSuccessfulPurchaseUnlocks() async {
        let unlock = store(operations(purchase: .unlocked))

        await unlock.purchase()

        XCTAssertTrue(unlock.isUnlocked)
        XCTAssertEqual(unlock.status, .ready)
    }

    /// The purchase is remembered on the device, so the next launch does not
    /// have to ask Apple anything to know the answer.
    func test_aSuccessfulPurchaseIsRememberedForTheNextLaunch() async {
        let cache = UnlockStore.Cache.inMemory()

        await store(operations(purchase: .unlocked), cache: cache).purchase()

        XCTAssertTrue(store(operations(), cache: cache).isUnlocked)
    }

    /// Backing out of Apple's payment sheet is not an event. No message, no
    /// change: exactly as they were.
    func test_cancellingLeavesThePlayerExactlyAsTheyWere() async {
        let unlock = store(operations(purchase: .cancelled))

        await unlock.purchase()

        XCTAssertFalse(unlock.isUnlocked)
        XCTAssertEqual(unlock.status, .ready)
    }

    func test_aFailedPurchaseSurfacesAMessageAndLeavesThemLocked() async {
        let unlock = store(operations(purchase: .failed(UnlockCopy.purchaseFailed)))

        await unlock.purchase()

        XCTAssertFalse(unlock.isUnlocked)
        XCTAssertEqual(unlock.status, .purchaseFailed(UnlockCopy.purchaseFailed))
    }

    /// And says so — the thing a player is actually worried about is whether
    /// they have been charged.
    func test_aFailedPurchaseSaysNoMoneyMoved() async {
        let unlock = store(operations(purchase: .failed(UnlockCopy.purchaseFailed)))

        await unlock.purchase()

        guard case let .purchaseFailed(message) = unlock.status else {
            return XCTFail("Expected a message, got \(unlock.status)")
        }
        XCTAssertTrue(message.contains("haven't been charged"), message)
    }

    /// Ask to Buy: neither bought nor failed. It arrives later through the
    /// updates stream, which is what the message says.
    func test_aPurchaseNeedingApprovalIsWaitingRatherThanFailed() async {
        let unlock = store(operations(purchase: .awaitingApproval))

        await unlock.purchase()

        XCTAssertFalse(unlock.isUnlocked)
        XCTAssertEqual(unlock.status, .awaitingApproval)
    }

    /// Raising the offer again after a failure is a fresh offer, not the last
    /// failure still on screen.
    func test_dismissingTheOfferClearsTheLastMessage() async {
        let unlock = store(operations(purchase: .failed(UnlockCopy.purchaseFailed)))
        await unlock.purchase()

        unlock.clearStatus()

        XCTAssertEqual(unlock.status, .ready)
    }

    // MARK: - The price

    func test_thePriceShownIsTheOneStoreKitSupplied() async {
        let unlock = store(operations(displayPrice: "1.234,56 TL"))

        await unlock.prepare()

        XCTAssertEqual(unlock.displayPrice, "1.234,56 TL")
        XCTAssertEqual(UnlockCopy.buy(price: unlock.displayPrice), "Unlock Sıra for 1.234,56 TL")
    }

    /// Offline at launch, most likely. The button keeps its own word and stays
    /// live: the purchase asks for the product again and has something to say
    /// if it still cannot reach it.
    func test_noPriceYetLeavesTheButtonWithSomethingToSay() async {
        let unlock = store(operations(displayPrice: nil))

        await unlock.prepare()

        XCTAssertNil(unlock.displayPrice)
        XCTAssertEqual(UnlockCopy.buy(price: unlock.displayPrice), "Unlock Sıra")
    }

    // MARK: - The entitlement

    /// **The single most important test in this ticket.**
    ///
    /// StoreKit returning nothing — offline, a cache that has never synced on
    /// this device, or the known family-sharing regressions — is not a refusal.
    /// A device that has ever seen a verified purchase stays unlocked, because
    /// wrongly locking hits a paying player mid-evening and wrongly staying
    /// unlocked costs at most one purchase somebody already made.
    func test_storeKitReturningNothingLeavesAPreviouslyUnlockedPlayerUnlocked() async {
        let unlock = store(
            operations(entitlements: []),
            cache: .inMemory(hasSeenUnlock: true)
        )

        await unlock.prepare()

        XCTAssertTrue(unlock.isUnlocked)
    }

    /// The other half of it: silence does not hand the app to somebody who
    /// never bought it either. It changes nothing at all.
    func test_storeKitReturningNothingLeavesAPlayerWhoNeverPaidLocked() async {
        let unlock = store(operations(entitlements: []))

        await unlock.prepare()

        XCTAssertFalse(unlock.isUnlocked)
    }

    func test_averifiedEntitlementUnlocksADeviceThatHasNotSeenOneBefore() async {
        let unlock = store(operations(entitlements: [held]))

        await unlock.prepare()

        XCTAssertTrue(unlock.isUnlocked)
    }

    /// A refund, or a Family Sharing group the player has left. This is the one
    /// answer that re-locks — an explicit revocation, never an absence.
    func test_anExplicitlyRevokedTransactionRelocks() async {
        let cache = UnlockStore.Cache.inMemory(hasSeenUnlock: true)
        let unlock = store(operations(entitlements: [revoked]), cache: cache)

        await unlock.prepare()

        XCTAssertFalse(unlock.isUnlocked)
        // And the device stops claiming it, so the next launch agrees.
        XCTAssertFalse(cache.read())
    }

    /// Two Apple Accounts on one device, one of them refunded: the purchase
    /// that still stands is what counts.
    func test_oneRevokedTransactionAlongsideOneHeldLeavesThePlayerUnlocked() async {
        let unlock = store(operations(entitlements: [revoked, held]))

        await unlock.prepare()

        XCTAssertTrue(unlock.isUnlocked)
    }

    // MARK: - Arriving from elsewhere

    /// Another device, or a Family Sharing member. The player buys nothing in
    /// this session and the app unlocks.
    func test_aPurchaseArrivingThroughTheUpdatesStreamUnlocks() async {
        let unlock = store(operations(updates: stream(of: [held])))

        await unlock.observeUpdates()

        XCTAssertTrue(unlock.isUnlocked)
    }

    func test_aRevocationArrivingThroughTheUpdatesStreamRelocks() async {
        let unlock = store(
            operations(updates: stream(of: [revoked])),
            cache: .inMemory(hasSeenUnlock: true)
        )

        await unlock.observeUpdates()

        XCTAssertFalse(unlock.isUnlocked)
    }

    // MARK: - Restore

    func test_restoreThatFindsAPurchaseUnlocks() async {
        let unlock = store(operations(entitlements: [held]))

        await unlock.restore()

        XCTAssertTrue(unlock.isUnlocked)
        XCTAssertEqual(unlock.status, .ready)
    }

    /// Said plainly, rather than left as a screen that did nothing.
    func test_restoreThatFindsNothingSaysSo() async {
        let unlock = store(operations(entitlements: []))

        await unlock.restore()

        XCTAssertFalse(unlock.isUnlocked)
        XCTAssertEqual(unlock.status, .nothingToRestore)
    }

    /// A Restore that finds nothing is an answer about *this* Apple Account,
    /// and it does not take the app away from a device that already had it.
    func test_restoreThatFindsNothingDoesNotRelockAnUnlockedDevice() async {
        let unlock = store(operations(entitlements: []), cache: .inMemory(hasSeenUnlock: true))

        await unlock.restore()

        XCTAssertTrue(unlock.isUnlocked)
        XCTAssertEqual(unlock.status, .ready)
    }

    func test_restoreThatCannotReachTheAppStoreSaysSo() async {
        let unlock = store(operations(restore: { throw StubError() }))

        await unlock.restore()

        XCTAssertFalse(unlock.isUnlocked)
        XCTAssertEqual(unlock.status, .purchaseFailed(UnlockCopy.restoreFailed))
    }

    // MARK: - The local cache

    /// The flag is written where the meter lives, and read back the way
    /// `MatchStorePersistenceTests` proves everything else: a second store over
    /// the same file.
    func test_theUnlockSurvivesARelaunch() throws {
        let directory = URL.temporaryDirectory.appending(path: "UnlockStoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "Sira.store")

        try MatchStore(storedAt: url).recordUnlock(seen: true)

        XCTAssertTrue(try MatchStore(storedAt: url).hasSeenUnlock)
    }

    /// Re-locking changes what the player can start and nothing else. Their
    /// history is where they left it, complete and readable.
    func test_reLockingTouchesNoMatchRoundOrEntrant() {
        let matchStore = MatchStore()
        let alice = Entrant(name: "Alice")
        let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [alice])
        matchStore.add(match)
        matchStore.addRound(Round(deltas: [alice.id: 20]), to: match)
        matchStore.recordUnlock(seen: true)

        matchStore.recordUnlock(seen: false)

        XCTAssertFalse(matchStore.hasSeenUnlock)
        XCTAssertEqual(match.rounds.count, 1)
        XCTAssertEqual(match.entrants.count, 1)
        XCTAssertEqual(match.rounds.first?.deltas[alice.id], 20)
        // And the meter is exactly where it was: a revocation returns the
        // player to it rather than resetting it.
        XCTAssertEqual(matchStore.freeMatches.remaining, 2)
    }

    // MARK: -

    private func stream(of entitlements: [UnlockStore.Entitlement]) -> AsyncStream<UnlockStore.Entitlement> {
        AsyncStream { continuation in
            for entitlement in entitlements { continuation.yield(entitlement) }
            continuation.finish()
        }
    }

    private struct StubError: Error {}
}
