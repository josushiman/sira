import XCTest
@testable import sira

final class PlayStatsTests: XCTestCase {
    func test_survivalInProgress_showsLeaderAndRoomLeft() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 20, b.id: 60])]
        )

        let stats = PlayStats(match: match, engine: SurvivalEngine())

        XCTAssertEqual(stats.leadLabel, "Leader")
        XCTAssertEqual(stats.leadValue, "Alice · 20")
        XCTAssertEqual(stats.secondaryLabel, "Room left")
        XCTAssertEqual(stats.secondaryValue, "81")
    }

    func test_survivalOver_showsResultAndZeroRoomLeft() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 20, b.id: 110])]
        )

        let stats = PlayStats(match: match, engine: SurvivalEngine())

        XCTAssertEqual(stats.leadLabel, "Result")
        XCTAssertEqual(stats.leadValue, "Alice · 20")
    }

    func test_fixedRounds_showsRoundsLeft() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = Match(
            game: .okey,
            variant: .okey101.choosingRoundCount(8),
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 10, b.id: 5]), Round(deltas: [a.id: 10, b.id: 5])]
        )

        let stats = PlayStats(match: match, engine: FixedRoundsEngine())

        XCTAssertEqual(stats.secondaryLabel, "Rounds left")
        XCTAssertEqual(stats.secondaryValue, "6")
    }

    func test_elimination_showsGapBetweenBestAndWorst() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = Match(
            game: .okey,
            variant: .okeyStandard,
            mode: .teams,
            entrants: [a, b],
            rounds: [Round(cifte: false, losingEntrantID: b.id, gostergeFinds: [:])]
        )

        let stats = PlayStats(match: match, engine: EliminationEngine())

        XCTAssertEqual(stats.secondaryLabel, "Gap")
        XCTAssertEqual(stats.secondaryValue, "2")
    }
}
