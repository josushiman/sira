import XCTest
import SwiftData
@testable import sira

/// What the wall does, and — more importantly — what it does not.
///
/// Driven through a real `MatchStore`, so the numbers the wall reads are the
/// ones playing games actually produces rather than a `FreeMatches` written by
/// hand. `GameAccessTests` asserts the rule; this asserts that a player who
/// sits down and plays arrives at it, and that the one thing the spec promises
/// unconditionally survives it.
@MainActor
final class TheWallTests: XCTestCase {
    private func access(_ store: MatchStore, unlocked: Bool = false) -> GameAccess {
        .resolved(freeMatches: store.freeMatches, isUnlocked: unlocked)
    }

    @discardableResult
    private func play(_ rounds: Int, in store: MatchStore) -> (Match, Entrant) {
        let alice = Entrant(name: "Alice")
        let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [alice])
        store.add(match)
        for _ in 0..<rounds {
            store.addRound(Round(deltas: [alice.id: 20]), to: match)
        }
        return (match, alice)
    }

    /// Three games played, nothing bought: the next tap on Gonga or Okey is the
    /// offer rather than the Variant picker.
    func test_afterThreeGamesPlayedTheNextTapIsTheOffer() {
        let store = MatchStore()

        for _ in 0..<3 { play(1, in: store) }

        XCTAssertTrue(access(store).isLocked)
    }

    /// And not a game earlier. Two played leaves one free, and the picker opens
    /// as it always has.
    func test_withAFreeGameLeftTheTapStillOpensTheVariantPicker() {
        let store = MatchStore()

        for _ in 0..<2 { play(1, in: store) }

        XCTAssertFalse(access(store).isLocked)
    }

    /// A player who has bought the Unlock never meets the wall, however many
    /// games they have played.
    func test_anUnlockedPlayerNeverMeetsTheWall() {
        let store = MatchStore()

        for _ in 0..<5 { play(1, in: store) }

        XCTAssertFalse(access(store, unlocked: true).isLocked)
        XCTAssertNil(access(store, unlocked: true).meter)
    }

    /// **Scoring a Round is never refused, by anything, in any state.**
    ///
    /// The promise the whole spec is built around: four people at a table, the
    /// tally half-written, and the app does not stop. The Match here was
    /// Started before the limit was reached and goes on being scored well past
    /// it.
    func test_aMatchInProgressKeepsScoringAfterTheLimitIsReached() {
        let store = MatchStore()
        let (match, alice) = play(1, in: store)
        for _ in 0..<2 { play(1, in: store) }
        XCTAssertTrue(access(store).isLocked)

        for _ in 0..<4 {
            store.addRound(Round(deltas: [alice.id: 15]), to: match)
        }

        XCTAssertEqual(match.rounds.count, 5)
        XCTAssertNil(store.saveFailure)
    }

    /// And Undo goes on working on it, so a mistake is still correctable at the
    /// wall.
    func test_undoStillWorksAfterTheLimitIsReached() {
        let store = MatchStore()
        let (match, alice) = play(1, in: store)
        for _ in 0..<2 { play(1, in: store) }
        store.addRound(Round(deltas: [alice.id: 15]), to: match)

        store.undoLastRound(in: match)

        XCTAssertEqual(match.rounds.count, 1)
        XCTAssertTrue(access(store).isLocked)
    }

    /// Reaching the limit hides nothing and unmakes nothing: every game played
    /// is still there to be read.
    func test_reachingTheLimitLeavesEveryGamePlayedIntact() {
        let store = MatchStore()
        for _ in 0..<3 { play(2, in: store) }

        XCTAssertTrue(access(store).isLocked)
        let matches = (try? store.context.fetch(FetchDescriptor<Match>())) ?? []
        XCTAssertEqual(matches.count, 3)
        XCTAssertTrue(matches.allSatisfy { $0.started && $0.rounds.count == 2 })
    }

    /// Buying lifts the wall at once — and the meter goes with it, which is the
    /// rest of the paywall disappearing.
    func test_buyingLiftsTheWallAndTakesTheMeterWithIt() async {
        let store = MatchStore()
        for _ in 0..<3 { play(1, in: store) }
        let unlock = UnlockStore(
            operations: UnlockStore.Operations(
                displayPrice: { nil },
                purchase: { .unlocked },
                restore: {},
                entitlements: { [] },
                updates: { AsyncStream { $0.finish() } },
                presentCodeRedemption: {}
            ),
            cache: .stored(in: store)
        )

        await unlock.purchase()

        let after = GameAccess.resolved(freeMatches: store.freeMatches, isUnlocked: unlock.isUnlocked)
        XCTAssertEqual(after, .unlocked)
        XCTAssertNil(after.meter)
        // And the device remembers it, so the next launch opens unlocked.
        XCTAssertTrue(store.hasSeenUnlock)
    }
}
