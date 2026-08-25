import XCTest
@testable import sira

final class PlayStatsTests: XCTestCase {
    func test_survivalInProgress_showsLeaderAndClosestToOut() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 20, b.id: 60])]
        )

        let stats = PlayStats(variant: .gongaStandard, match: match, engine: SurvivalEngine())

        XCTAssertEqual(stats.leadLabel, "Leader")
        XCTAssertEqual(stats.leadValue, "Alice · 20")
        XCTAssertEqual(stats.secondaryLabel, "Closest to out")
        XCTAssertEqual(stats.secondaryValue, "Bob · 41 left")
    }

    /// Cem is Out at 160 under the shipped 151 and comfortably in at 201, so
    /// this fails against a Match scored by the Variant's constant rather than
    /// by its own limit — Closest to out would skip him as already Out.
    func test_survivalClosestToOut_countsAgainstTheLimitThisMatchChose() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cem")
        let match = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 201,
            mode: .players,
            entrants: [a, b, c],
            rounds: [Round(deltas: [a.id: 20, b.id: 90, c.id: 160])]
        )

        let stats = PlayStats(variant: .gongaStandard, match: match, engine: SurvivalEngine())

        XCTAssertEqual(stats.secondaryLabel, "Closest to out")
        XCTAssertEqual(stats.secondaryValue, "Cem · 41 left")
    }

    func test_survivalClosestToOut_ignoresEntrantsAlreadyOut() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cem")
        let match = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 151,
            mode: .players,
            entrants: [a, b, c],
            rounds: [Round(deltas: [a.id: 20, b.id: 90, c.id: 160])]
        )

        let stats = PlayStats(variant: .gongaStandard, match: match, engine: SurvivalEngine())

        XCTAssertEqual(stats.secondaryLabel, "Closest to out")
        XCTAssertEqual(stats.secondaryValue, "Bob · 61 left")
    }

    /// A joining or rejoining Entrant enters on the highest total still in, so
    /// two Entrants level at the top is the ordinary case rather than a
    /// curiosity. Naming one of them would state something untrue.
    func test_survivalClosestToOut_namesBothEntrantsTiedOnTheHighestTotal() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cem")
        let match = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [a, b, c],
            rounds: [Round(deltas: [a.id: 20, b.id: 60, c.id: 60])]
        )

        let stats = PlayStats(variant: .gongaStandard, match: match, engine: SurvivalEngine())

        XCTAssertEqual(stats.secondaryLabel, "Closest to out")
        XCTAssertEqual(stats.secondaryValue, "Bob & Cem · 41 left")
    }

    func test_survivalClosestToOut_namesEveryEntrantWhenThreeAreTied() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cem")
        let d = Entrant(name: "Dila")
        let match = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [a, b, c, d],
            rounds: [Round(deltas: [a.id: 20, b.id: 60, c.id: 60, d.id: 60])]
        )

        let stats = PlayStats(variant: .gongaStandard, match: match, engine: SurvivalEngine())

        XCTAssertEqual(stats.secondaryValue, "Bob, Cem & Dila · 41 left")
    }

    /// An Out Entrant has no Room left to run out of, so the total the tie is
    /// measured at is the highest among those still in — not the higher one an
    /// Out Entrant is sitting on. Dila holds the top total and is excluded, so
    /// the tie reported is Bob and Cem's, at their number rather than hers.
    func test_survivalClosestToOut_measuresTheTieAgainstEntrantsStillIn() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cem")
        let d = Entrant(name: "Dila")
        let match = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [a, b, c, d],
            rounds: [Round(deltas: [a.id: 20, b.id: 60, c.id: 60, d.id: 110])]
        )

        let stats = PlayStats(variant: .gongaStandard, match: match, engine: SurvivalEngine())

        XCTAssertEqual(stats.secondaryValue, "Bob & Cem · 41 left")
    }

    /// Room left is measured against the Match's limit, so a Match played
    /// without one has no tie to report rather than a tie at zero.
    func test_survivalClosestToOut_withNoLimitReportsNothing() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = Match(
            game: .gonga,
            variantId: Variant.gongaStandard.id,
            limit: nil,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 60, b.id: 60])]
        )

        let stats = PlayStats(variant: .gongaStandard, match: match, engine: SurvivalEngine())

        XCTAssertEqual(stats.secondaryLabel, "Closest to out")
        XCTAssertEqual(stats.secondaryValue, "—")
    }

    /// Room left is the survivor's distance from the limit the table agreed
    /// on, not from the one the Variant ships with.
    func test_survivalRoomLeft_countsAgainstTheLimitThisMatchChose() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 201,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 20, b.id: 210])]
        )

        let stats = PlayStats(variant: .gongaStandard, match: match, engine: SurvivalEngine())

        XCTAssertEqual(stats.leadLabel, "Result")
        XCTAssertEqual(stats.secondaryLabel, "Room left")
        XCTAssertEqual(stats.secondaryValue, "181")
    }

    func test_survivalOver_showsResultAndTheSurvivorsRoomLeft() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 20, b.id: 110])]
        )

        let stats = PlayStats(variant: .gongaStandard, match: match, engine: SurvivalEngine())

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
            number: 8,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 10, b.id: 5]), Round(deltas: [a.id: 10, b.id: 5])]
        )

        let stats = PlayStats(variant: .okey101, match: match, engine: FixedRoundsEngine())

        XCTAssertEqual(stats.secondaryLabel, "Rounds left")
        XCTAssertEqual(stats.secondaryValue, "6")
    }

    /// Rounds left counts against the number this table chose, not the number
    /// the Variant ships with — a five-Round Match is three Rounds from the end
    /// after two, and would read as six if the Variant's 8 still stood.
    func test_fixedRounds_countsRoundsLeftAgainstTheChosenNumber() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = Match(
            game: .okey,
            variant: .okey101,
            number: 5,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 10, b.id: 5]), Round(deltas: [a.id: 10, b.id: 5])]
        )

        let stats = PlayStats(variant: .okey101, match: match, engine: FixedRoundsEngine())

        XCTAssertEqual(stats.secondaryLabel, "Rounds left")
        XCTAssertEqual(stats.secondaryValue, "3")
    }

    func test_elimination_showsGapBetweenBestAndWorst() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = Match(
            game: .okey,
            variant: .okeyStandard,
            number: 21,
            mode: .teams,
            entrants: [a, b],
            rounds: [Round(losingEntrantID: b.id)]
        )

        let stats = PlayStats(variant: .okeyStandard, match: match, engine: EliminationEngine())

        XCTAssertEqual(stats.secondaryLabel, "Gap")
        XCTAssertEqual(stats.secondaryValue, "2")
    }

    /// The Gap is the distance between the two teams, not the distance either
    /// has left to fall — so the score they started from does not enter into
    /// it. One Round of −2 leaves a gap of 2 from 21 and from 31 alike.
    func test_elimination_gapIsUnaffectedByTheStartingScore() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = Match(
            game: .okey,
            variant: .okeyStandard,
            number: 31,
            mode: .teams,
            entrants: [a, b],
            rounds: [Round(losingEntrantID: b.id)]
        )

        let stats = PlayStats(variant: .okeyStandard, match: match, engine: EliminationEngine())

        XCTAssertEqual(stats.leadValue, "Team A · 31")
        XCTAssertEqual(stats.secondaryLabel, "Gap")
        XCTAssertEqual(stats.secondaryValue, "2")
    }
}
