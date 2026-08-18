import XCTest
@testable import sira

final class EliminationEngineTests: XCTestCase {
    private let variant = Variant.okeyStandard

    private func makeMatch(entrants: [Entrant], rounds: [Round]) -> Match {
        Match(game: .okey, variant: variant, mode: .teams, entrants: entrants, rounds: rounds)
    }

    func test_startsAtTheVariantsStartingScore() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(entrants: [a, b], rounds: [])

        let standings = EliminationEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 20)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 20)
    }

    func test_losingTeamTakesTwoPointPenalty() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(losingEntrantID: a.id)]
        )

        let standings = EliminationEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 18)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 20)
    }

    // MARK: - Gösterge

    func test_gostergeFindDeductsOneFromTheOtherTeam() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(gostergeFinds: [a.id: 1])]
        )

        let standings = EliminationEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 20)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 19)
    }

    func test_gostergeFindsAreCappedAtOnePerEntrantEvenIfMoreAreSent() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(gostergeFinds: [a.id: 3])]
        )

        let standings = EliminationEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 19)
    }

    func test_bothTeamsCanFindGostergeInTheSameRound() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(gostergeFinds: [a.id: 1, b.id: 1])]
        )

        let standings = EliminationEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 19)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 19)
    }

    func test_penaltyAndGostergeCombineInTheSameRound() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(losingEntrantID: a.id, gostergeFinds: [b.id: 1])]
        )

        let standings = EliminationEngine().standings(for: match)

        // Team A: -2 penalty, -1 from Team B's find = 17.
        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 17)
        // Team B: unaffected by its own find.
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 20)
    }

    // MARK: - Çifte

    func test_cifteDoublesOnlyTheLossPenalty() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(cifte: true, losingEntrantID: a.id, gostergeFinds: [b.id: 1])]
        )

        let standings = EliminationEngine().standings(for: match)

        // Team A: -4 (doubled penalty) - 1 (Gösterge, never doubled) = 15.
        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 15)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 20)
    }

    // MARK: - Match ending

    func test_matchEndsWhenAnEntrantReachesZero() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        var rounds = (0..<9).map { _ in Round(losingEntrantID: a.id) }
        rounds.append(Round(losingEntrantID: a.id))
        let match = makeMatch(entrants: [a, b], rounds: rounds)

        let standings = EliminationEngine().standings(for: match)

        let teamA = standings.ranked.first { $0.entrantID == a.id }!
        XCTAssertEqual(teamA.total, 0)
        XCTAssertTrue(teamA.isOut)
        XCTAssertTrue(standings.isOver)
        XCTAssertEqual(standings.result, "Team B wins!")
    }

    func test_matchDoesNotEndWhileBothTeamsAboveZero() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(losingEntrantID: a.id)]
        )

        let standings = EliminationEngine().standings(for: match)

        XCTAssertFalse(standings.isOver)
        XCTAssertNil(standings.result)
    }

    func test_penaltyCanTakeATeamBelowZero() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        var rounds = (0..<9).map { _ in Round(losingEntrantID: a.id) }
        rounds.append(Round(cifte: true, losingEntrantID: a.id))
        let match = makeMatch(entrants: [a, b], rounds: rounds)

        let standings = EliminationEngine().standings(for: match)

        let teamA = standings.ranked.first { $0.entrantID == a.id }!
        XCTAssertEqual(teamA.total, -2)
        XCTAssertTrue(teamA.isOut)
        XCTAssertTrue(standings.isOver)
        XCTAssertEqual(standings.result, "Team B wins!")
    }

    // MARK: - Undo

    func test_standingsAfterAppendingThenUndoingARoundMatchStandingsBeforeAppending() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        var match = makeMatch(
            entrants: [a, b],
            rounds: [Round(losingEntrantID: a.id)]
        )

        let before = EliminationEngine().standings(for: match)

        match.rounds.append(Round(losingEntrantID: b.id, gostergeFinds: [a.id: 1]))
        match.undoLastRound()

        let after = EliminationEngine().standings(for: match)

        XCTAssertEqual(before, after)
    }

    // MARK: - Ranking

    func test_rankingOrdersHigherTotalFirst() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(losingEntrantID: a.id)]
        )

        let standings = EliminationEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.map(\.name), ["Team B", "Team A"])
    }
}
