import XCTest
@testable import sira

/// What a rename does to a Match already being played: everything that names
/// the Entrant says the new name, and nothing that scores them moves.
///
/// Asserted through the seams the screens read from — the Engine's Standings,
/// the Scoresheet's rows and `PlayStats`' tiles — rather than through the sheet
/// that starts it, so these stay true of any screen that names an Entrant.
final class EntrantRenameTests: XCTestCase {
    private let limit = 101

    private func makeMatch(entrants: [Entrant], rounds: [Round]) -> Match {
        Match(
            game: .gonga,
            variant: .gongaStandard,
            number: limit,
            mode: .players,
            entrants: entrants,
            rounds: rounds
        )
    }

    private func standing(_ entrant: Entrant, in standings: Standings) throws -> EntrantStanding {
        try XCTUnwrap(standings.ranked.first { $0.entrantID == entrant.id })
    }

    /// The one that matters: Rounds played before the rename are named by the
    /// new name too, because nothing anywhere stored the old one.
    func test_aRenameNamesTheEntrantOnRoundsAlreadyPlayed() throws {
        let ali = Entrant(name: "Ali")
        let veli = Entrant(name: "Veli")
        let match = makeMatch(
            entrants: [ali, veli],
            rounds: [Round(deltas: [ali.id: 20, veli.id: 5]), Round(deltas: [ali.id: 10, veli.id: 15])]
        )
        let store = MatchStore()
        store.add(match)

        store.rename(ali, to: "Cem")

        let scoresheet = Scoresheet(match: match, engine: SurvivalEngine())
        // The Scoresheet keys its cells by id and takes its column headings
        // off the Match's Entrants, so both halves of the sheet move together.
        XCTAssertEqual(match.entrants.map(\.name), ["Cem", "Veli"])
        XCTAssertEqual(scoresheet.rows.first?.deltas[ali.id], 20)
        XCTAssertEqual(try standing(ali, in: scoresheet.totals).name, "Cem")
    }

    func test_aRenameLeavesTotalsDeltasAndOutStateWhereTheyWere() throws {
        let ali = Entrant(name: "Ali")
        let veli = Entrant(name: "Veli")
        let match = makeMatch(
            entrants: [ali, veli],
            rounds: [Round(deltas: [ali.id: 20, veli.id: 5]), Round(deltas: [ali.id: 10, veli.id: 15])]
        )
        let store = MatchStore()
        store.add(match)
        let before = SurvivalEngine().standings(for: match)

        store.rename(ali, to: "Cem")

        let after = SurvivalEngine().standings(for: match)
        XCTAssertEqual(after.ranked.map(\.total), before.ranked.map(\.total))
        XCTAssertEqual(after.ranked.map(\.deltaFromLastRound), before.ranked.map(\.deltaFromLastRound))
        XCTAssertEqual(after.ranked.map(\.isOut), before.ranked.map(\.isOut))
        XCTAssertEqual(after.isOver, before.isOver)
    }

    /// A typo is worth fixing for someone who has stopped accumulating score,
    /// so being Out is no bar to a rename — and the rename does not bring them
    /// back in.
    func test_anOutEntrantCanBeRenamedAndStaysOut() throws {
        let ali = Entrant(name: "Ali")
        let veli = Entrant(name: "Veli")
        let cem = Entrant(name: "Cem")
        let match = makeMatch(
            entrants: [ali, veli, cem],
            rounds: [Round(deltas: [ali.id: 120, veli.id: 5, cem.id: 10])]
        )
        let store = MatchStore()
        store.add(match)
        XCTAssertTrue(try standing(ali, in: SurvivalEngine().standings(for: match)).isOut)

        store.rename(ali, to: "Ayşe")

        let after = try standing(ali, in: SurvivalEngine().standings(for: match))
        XCTAssertEqual(after.name, "Ayşe")
        XCTAssertTrue(after.isOut)
        XCTAssertEqual(after.total, 120)
    }

    /// The result line and the stat tiles read the same names as the rows, so
    /// a rename reaches the end of the Match as well as the middle of it.
    func test_aRenameReachesTheResultLineAndTheStatTiles() throws {
        let ali = Entrant(name: "Ali")
        let veli = Entrant(name: "Veli")
        let match = makeMatch(
            entrants: [ali, veli],
            rounds: [Round(deltas: [ali.id: 120, veli.id: 5])]
        )
        let store = MatchStore()
        store.add(match)

        store.rename(veli, to: "Zeynep")

        let standings = SurvivalEngine().standings(for: match)
        XCTAssertEqual(standings.result, "Zeynep wins!")
        let stats = PlayStats(variant: .gongaStandard, match: match, standings: standings)
        XCTAssertEqual(stats.leadValue, "Zeynep · 5")
    }

    /// Archived is a visibility flag and nothing else: an Archived Match still
    /// takes Rounds, so refusing it a rename would be an inconsistency with
    /// nothing behind it.
    func test_anArchivedMatchIsStillRenameable() throws {
        let ali = Entrant(name: "Ali")
        let match = makeMatch(entrants: [ali, Entrant(name: "Veli")], rounds: [])
        let store = MatchStore()
        store.add(match)
        store.archive(match)

        store.rename(ali, to: "Cem")

        XCTAssertTrue(match.archived)
        XCTAssertEqual(match.entrants.first?.name, "Cem")
    }

    /// A Match made before the uniqueness rule can hold two Alis. It opens and
    /// scores like any other — the rule is checked on a candidate name at the
    /// point of editing, never swept over what is already stored.
    func test_aMatchAlreadyHoldingTwoIdenticalNamesStillScores() throws {
        let first = Entrant(name: "Ali")
        let second = Entrant(name: "Ali")
        let match = makeMatch(
            entrants: [first, second],
            rounds: [Round(deltas: [first.id: 20, second.id: 5])]
        )

        let standings = SurvivalEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.count, 2)
        XCTAssertEqual(try standing(first, in: standings).total, 20)
        XCTAssertEqual(try standing(second, in: standings).total, 5)
    }
}
