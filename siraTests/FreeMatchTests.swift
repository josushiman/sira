import XCTest
import SwiftData
@testable import sira

/// How many free games a player has left, and what does and does not spend
/// one.
///
/// Asserted through the store rather than against `StartedMatchTally`
/// directly: what a player notices is the number on Home going down when they
/// start a game and staying put when they undo, delete or archive one, and
/// that is what these drive.
final class FreeMatchTests: XCTestCase {
    private func gongaMatch(_ entrants: [Entrant]) -> Match {
        Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: entrants)
    }

    /// Sets up a Match in `store` and scores `rounds` Rounds on it, one at a
    /// time — the way the app does, and the only way a Match Starts through
    /// play.
    @discardableResult
    private func play(_ rounds: Int, in store: MatchStore) -> Match {
        let alice = Entrant(name: "Alice")
        let match = gongaMatch([alice])
        store.add(match)
        for _ in 0..<rounds {
            store.addRound(Round(deltas: [alice.id: 20]), to: match)
        }
        return match
    }

    func test_aFreshStoreHasThreeFreeGames() {
        let store = MatchStore()

        XCTAssertEqual(store.freeMatches.remaining, 3)
        XCTAssertEqual(store.freeMatches.used, 0)
        XCTAssertFalse(store.freeMatches.isExhausted)
    }

    func test_settingUpAMatchWithoutScoringItCostsNothing() {
        let store = MatchStore()

        store.add(gongaMatch([Entrant(name: "Alice")]))

        XCTAssertEqual(store.freeMatches.remaining, 3)
    }

    func test_theFirstRoundScoredSpendsOneFreeGame() {
        let store = MatchStore()

        play(1, in: store)

        XCTAssertEqual(store.freeMatches.remaining, 2)
    }

    func test_furtherRoundsOnTheSameMatchSpendNothing() {
        let store = MatchStore()

        play(4, in: store)

        XCTAssertEqual(store.freeMatches.remaining, 2)
    }

    func test_eachMatchPlayedSpendsItsOwnFreeGame() {
        let store = MatchStore()

        play(1, in: store)
        play(1, in: store)

        XCTAssertEqual(store.freeMatches.remaining, 1)
    }

    func test_threeMatchesPlayedUseThemUp() {
        let store = MatchStore()

        for _ in 0..<3 { play(1, in: store) }

        XCTAssertEqual(store.freeMatches.remaining, 0)
        XCTAssertEqual(store.freeMatches.used, 3)
        XCTAssertTrue(store.freeMatches.isExhausted)
    }

    /// Nothing here blocks a fourth Match yet — that is ticket 03 — so playing
    /// one is possible, and the meter has to survive being asked about a
    /// player who is past the allowance rather than report fewer than none
    /// left.
    func test_playingPastTheAllowanceLeavesNoneLeftRatherThanFewerThanNone() {
        let store = MatchStore()

        for _ in 0..<5 { play(1, in: store) }

        XCTAssertEqual(store.freeMatches.remaining, 0)
        XCTAssertEqual(store.freeMatches.used, 3)
        XCTAssertEqual(store.freeMatches.startedMatches, 5)
    }

    func test_undoingTheOnlyRoundDoesNotGiveTheFreeGameBack() {
        let store = MatchStore()

        let match = play(1, in: store)
        store.undoLastRound(in: match)

        XCTAssertEqual(store.freeMatches.remaining, 2)
    }

    /// The case the tally exists for. Undo leaves the Match Started, so the
    /// next Round is not a Start — and a count that re-read the Round number
    /// instead of the flag would charge for the same game twice.
    func test_scoringAgainAfterAnUndoDoesNotSpendASecondFreeGame() {
        let store = MatchStore()

        let alice = Entrant(name: "Alice")
        let match = gongaMatch([alice])
        store.add(match)
        store.addRound(Round(deltas: [alice.id: 20]), to: match)
        store.undoLastRound(in: match)
        store.addRound(Round(deltas: [alice.id: 30]), to: match)

        XCTAssertEqual(store.freeMatches.remaining, 2)
    }

    func test_deletingAPlayedMatchDoesNotGiveTheFreeGameBack() {
        let store = MatchStore()

        let match = play(1, in: store)
        store.delete(match)

        XCTAssertEqual(store.freeMatches.remaining, 2)
    }

    func test_archivingAPlayedMatchChangesNothing() {
        let store = MatchStore()

        let match = play(1, in: store)
        store.archive(match)

        XCTAssertEqual(store.freeMatches.remaining, 2)
    }

    /// A Match handed over with its Rounds already on it has been played, and
    /// `Match.init` Starts it for exactly that reason. It costs a free game
    /// too, so that the tally counts Started Matches however they arrived
    /// rather than only those scored a Round at a time.
    func test_aMatchAddedWithRoundsAlreadyOnItSpendsAFreeGame() {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")

        store.add(Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [alice],
            rounds: [Round(deltas: [alice.id: 20])]
        ))

        XCTAssertEqual(store.freeMatches.remaining, 2)
    }

    /// A Match carrying Rounds but no Start is data written before the flag
    /// existed. The launch sweep believes the Rounds and Starts it — and the
    /// game it records was played, so it is counted rather than given away.
    func test_aMatchStartedByTheLaunchSweepSpendsItsFreeGame() throws {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")
        let match = gongaMatch([alice])
        store.context.insert(match)
        match.addRound(Round(deltas: [alice.id: 20]))
        // What the store held before this release: Rounds on the Match, and no
        // flag to have written. Set directly, as
        // `MatchStorePersistenceTests` does, because nothing in the app can
        // un-Start a Match.
        match.started = false

        store.discardUnstartedMatches()

        XCTAssertEqual(store.freeMatches.remaining, 2)
    }

    /// And only once, however many launches happen: the sweep runs at every
    /// one, and a Match it has already Started is not Started again.
    func test_aLaunchThatSweepsNothingSpendsNothing() {
        let store = MatchStore()

        play(1, in: store)
        store.discardUnstartedMatches()
        store.discardUnstartedMatches()

        XCTAssertEqual(store.freeMatches.remaining, 2)
    }
}
