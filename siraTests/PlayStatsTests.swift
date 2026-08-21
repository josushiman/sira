import XCTest
@testable import sira

final class PlayStatsTests: XCTestCase {
    func test_survivalInProgress_showsLeaderAndClosestToOut() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 20, b.id: 60])]
        )

        let stats = PlayStats(variant: .gonga101, match: match, engine: SurvivalEngine())

        XCTAssertEqual(stats.leadLabel, "Leader")
        XCTAssertEqual(stats.leadValue, "Alice · 20")
        XCTAssertEqual(stats.secondaryLabel, "Closest to out")
        XCTAssertEqual(stats.secondaryValue, "Bob · 41 left")
    }

    func test_survivalClosestToOut_ignoresEntrantsAlreadyOut() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cem")
        let match = Match(
            game: .gonga,
            variant: .gonga151,
            mode: .players,
            entrants: [a, b, c],
            rounds: [Round(deltas: [a.id: 20, b.id: 90, c.id: 160])]
        )

        let stats = PlayStats(variant: .gonga151, match: match, engine: SurvivalEngine())

        XCTAssertEqual(stats.secondaryLabel, "Closest to out")
        XCTAssertEqual(stats.secondaryValue, "Bob · 61 left")
    }

    func test_survivalOver_showsResultAndTheSurvivorsRoomLeft() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 20, b.id: 110])]
        )

        let stats = PlayStats(variant: .gonga101, match: match, engine: SurvivalEngine())

        XCTAssertEqual(stats.leadLabel, "Result")
        XCTAssertEqual(stats.leadValue, "Alice · 20")
        XCTAssertEqual(stats.secondaryLabel, "Room left")
        XCTAssertEqual(stats.secondaryValue, "81")
    }

    func test_fixedRounds_showsRoundsLeft() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = Match(
            game: .okey,
            variant: .okey101,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 10, b.id: 5]), Round(deltas: [a.id: 10, b.id: 5])]
        )

        let stats = PlayStats(variant: .okey101, match: match, engine: FixedRoundsEngine())

        XCTAssertEqual(stats.secondaryLabel, "Rounds left")
        XCTAssertEqual(stats.secondaryValue, "6")
    }

    func test_elimination_showsGapBetweenBestAndWorst() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = Match(
            game: .okey,
            variant: .okey21,
            mode: .teams,
            entrants: [a, b],
            rounds: [Round(losingEntrantID: b.id)]
        )

        let stats = PlayStats(variant: .okey21, match: match, engine: EliminationEngine())

        XCTAssertEqual(stats.secondaryLabel, "Gap")
        XCTAssertEqual(stats.secondaryValue, "2")
    }
}
