import XCTest
@testable import sira

final class ScoresheetTests: XCTestCase {
    func test_longLowestTotalHistoryKeepsOrderedRowsModifiersAndMissingEntryZeros() {
        let entrants = ["Alice", "Bob", "Cem", "Dila"].map { Entrant(name: $0) }
        let a = entrants[0].id, b = entrants[1].id, c = entrants[2].id, d = entrants[3].id
        let rounds = (0..<26).flatMap { _ in [
            Round(deltas: [a: 0, b: 10, c: 20, d: 30]),
            Round(deltas: [a: 10, b: 0, c: 20, d: 30], cifteCallers: [b]),
            Round(deltas: [a: 10, b: 20, c: 0, d: 30], cifteCallers: [a], okeyAtanID: c),
            Round(deltas: [a: 10, b: 20, c: 30]),
        ] }
        let match = Match(game: .okey, variant: .okey101, mode: .players, entrants: entrants, rounds: rounds)
            .withEntrantsAndRoundsStoredOutOfOrder()

        let sheet = Scoresheet(match: match, engine: LowestTotalEngine())

        XCTAssertEqual(sheet.rows.map(\.id), rounds.map(\.id))
        XCTAssertEqual(sheet.rows.map(\.roundNumber), Array(1...104))
        for block in 0..<26 {
            XCTAssertEqual(sheet.rows[block * 4].deltas, [a: 0, b: 10, c: 20, d: 30])
            XCTAssertEqual(sheet.rows[block * 4 + 1].deltas, [a: 20, b: 0, c: 40, d: 60])
            XCTAssertEqual(sheet.rows[block * 4 + 2].deltas, [a: 40, b: 40, c: 0, d: 60])
            XCTAssertEqual(sheet.rows[block * 4 + 3].deltas, [a: 10, b: 20, c: 30, d: 0])
            XCTAssertEqual(sheet.rows[block * 4 + 1].cifteCallers, [b])
            XCTAssertEqual(sheet.rows[block * 4 + 2].cifteCallers, [a])
            XCTAssertEqual(sheet.rows[block * 4 + 2].okeyAtanID, c)
        }
        XCTAssertEqual(Dictionary(uniqueKeysWithValues: sheet.totals.ranked.map { ($0.entrantID, $0.total) }),
                       [a: 1820, b: 1820, c: 2340, d: 3900])
        XCTAssertEqual(sheet.totals, LowestTotalEngine().standings(for: match))
        XCTAssertEqual(match.rounds[2].deltas, [a: 10, b: 20, c: 0, d: 30])
    }

    func test_scoresheetHonorsTheSuppliedEngineEvenForALowestTotalMatch() {
        let entrant = Entrant(name: "Alice")
        let match = Match(game: .okey, variant: .okey101, mode: .players, entrants: [entrant],
                          rounds: [Round(deltas: [entrant.id: 20]), Round(deltas: [entrant.id: 30])])
        let sheet = Scoresheet(match: match, engine: SevenPerRoundEngine())
        XCTAssertEqual(sheet.rows.map { $0.deltas[entrant.id] }, [7, 7])
        XCTAssertEqual(sheet.totals.ranked.map(\.total), [14])
    }

    private struct SevenPerRoundEngine: MatchEngine {
        func standings(for match: Match, rounds: [Round]) -> Standings {
            Standings(ranked: match.entrants.map {
                EntrantStanding(entrantID: $0.id, name: $0.name, total: rounds.count * 7,
                                isOut: false, deltaFromLastRound: rounds.isEmpty ? 0 : 7)
            }, isOver: false, result: nil)
        }
    }

    private let variant = Variant.gongaStandard
    private let engine = SurvivalEngine()

    private func makeMatch(entrants: [Entrant], rounds: [Round]) -> Match {
        Match(game: .gonga, variant: variant, number: 101, mode: .players, entrants: entrants, rounds: rounds)
    }

    func test_oneRowPerSavedRoundWithEachEntrantsDeltaForThatRound() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let round1 = Round(deltas: [a.id: 20, b.id: 5])
        let round2 = Round(deltas: [a.id: 10, b.id: 15])
        let match = makeMatch(entrants: [a, b], rounds: [round1, round2])

        let scoresheet = Scoresheet(match: match, engine: engine)

        XCTAssertEqual(scoresheet.rows.count, 2)
        XCTAssertEqual(scoresheet.rows[0].id, round1.id)
        XCTAssertEqual(scoresheet.rows[0].roundNumber, 1)
        XCTAssertEqual(scoresheet.rows[0].deltas, [a.id: 20, b.id: 5])
        XCTAssertEqual(scoresheet.rows[1].id, round2.id)
        XCTAssertEqual(scoresheet.rows[1].roundNumber, 2)
        XCTAssertEqual(scoresheet.rows[1].deltas, [a.id: 10, b.id: 15])
    }

    func test_totalsRowMatchesEnginesCurrentStandings() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 20, b.id: 5]),
                Round(deltas: [a.id: 10, b.id: 15]),
            ]
        )

        let scoresheet = Scoresheet(match: match, engine: engine)

        XCTAssertEqual(scoresheet.totals, engine.standings(for: match))
    }

    func test_cifteRoundsRowReflectsTheDoubledDelta() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 10, b.id: 5], cifteCallers: [a.id, b.id])]
        )

        let scoresheet = Scoresheet(match: match, engine: engine)

        XCTAssertEqual(scoresheet.rows[0].deltas, [a.id: 20, b.id: 10])
    }

    func test_rowCarriesItsRoundsModifiers() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 10, b.id: 5]),
                Round(deltas: [a.id: 0, b.id: 12], cifteCallers: [b.id], okeyAtanID: a.id),
            ]
        )

        let scoresheet = Scoresheet(match: match, engine: engine)

        XCTAssertEqual(scoresheet.rows[0].cifteCallers, [])
        XCTAssertNil(scoresheet.rows[0].okeyAtanID)
        XCTAssertEqual(scoresheet.rows[1].cifteCallers, [b.id])
        XCTAssertEqual(scoresheet.rows[1].okeyAtanID, a.id)
    }

    func test_deltaDerivationIsUnchangedByTheModifiersPresence() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        // The same Round scored twice: once with the modifiers recorded on it,
        // once with the doubling entered by hand and no modifiers at all. The
        // rows must agree — carrying the facts changes nothing about the
        // Standings diffs the rows are derived from.
        let annotated = makeMatch(
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 0, b.id: 12], okeyAtanID: a.id)]
        )
        let plain = makeMatch(
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 0, b.id: 24])]
        )

        XCTAssertEqual(
            Scoresheet(match: annotated, engine: engine).rows[0].deltas,
            Scoresheet(match: plain, engine: engine).rows[0].deltas
        )
    }

    func test_rejoinRowAlsoCarryingModifiersKeepsItsRejoinDelta() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 110, b.id: 20]),
                Round(
                    deltas: [a.id: 0, b.id: 10],
                    rejoins: [RejoinEvent(id: a.id, to: 20)],
                    okeyAtanID: a.id
                ),
            ]
        )

        let scoresheet = Scoresheet(match: match, engine: engine)

        // Alice rejoins at 20 from 110, doubling or not; Bob's 10 doubles.
        XCTAssertEqual(scoresheet.rows[1].deltas[a.id], -90)
        XCTAssertEqual(scoresheet.rows[1].deltas[b.id], 20)
        XCTAssertEqual(scoresheet.rows[1].okeyAtanID, a.id)
    }

    func test_roundAfterAnEntrantIsOutShowsZeroDeltaForThem() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 110, b.id: 20]),
                Round(deltas: [a.id: 5, b.id: 30]),
            ]
        )

        let scoresheet = Scoresheet(match: match, engine: engine)

        XCTAssertEqual(scoresheet.rows[1].deltas[a.id], 0)
        XCTAssertEqual(scoresheet.rows[1].deltas[b.id], 30)
    }

    func test_rejoinRoundsDeltaReflectsTheResetToTheRejoinTarget() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 110, b.id: 20]),
                Round(deltas: [a.id: 0, b.id: 0], rejoins: [RejoinEvent(id: a.id, to: 20)]),
            ]
        )

        let scoresheet = Scoresheet(match: match, engine: engine)

        // Alice's total goes from 110 (Out) to 20 (rejoined), a delta of -90.
        XCTAssertEqual(scoresheet.rows[1].deltas[a.id], -90)
    }

    func test_undoingARoundRemovesItsRowAndUpdatesTotalsImmediately() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 20, b.id: 5]),
                Round(deltas: [a.id: 10, b.id: 15]),
            ]
        )

        _ = match.undoLastRound()

        let scoresheet = Scoresheet(match: match, engine: engine)

        XCTAssertEqual(scoresheet.rows.count, 1)
        XCTAssertEqual(scoresheet.totals, engine.standings(for: match))
        let aliceTotal = scoresheet.totals.ranked.first { $0.entrantID == a.id }!.total
        XCTAssertEqual(aliceTotal, 20)
    }

    func test_aMatchWhoseRoundsAreStoredOutOfOrderScoresAndReadsInSequenceOrder() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        // Order is load-bearing here: Alice goes Out on the first Round and
        // rejoins at 20, so the second Round's 10 lands on 20 rather than on
        // the 105 it would if these Rounds were scored the other way round.
        let played = [
            Round(deltas: [a.id: 105, b.id: 5], rejoins: [RejoinEvent(id: a.id, to: 20)]),
            Round(deltas: [a.id: 10, b.id: 15]),
        ]
        let inOrder = makeMatch(entrants: [a, b], rounds: played)
        let outOfOrder = inOrder.withEntrantsAndRoundsStoredOutOfOrder()

        let expected = Scoresheet(match: inOrder, engine: engine)
        let actual = Scoresheet(match: outOfOrder, engine: engine)

        XCTAssertEqual(actual.rows.map(\.id), played.map(\.id))
        XCTAssertEqual(actual.rows.map(\.roundNumber), [1, 2])
        XCTAssertEqual(actual.rows.map(\.deltas), expected.rows.map(\.deltas))
        XCTAssertEqual(actual.totals, expected.totals)

        // And the fixture really is order-sensitive, so the assertions above
        // aren't passing because both orders happen to score the same.
        let reversed = makeMatch(entrants: [a, b], rounds: played.reversed())
        XCTAssertNotEqual(engine.standings(for: reversed), expected.totals)
    }

    /// A Round played before an Entrant arrived carries no entry for them at
    /// all — which is what lets the Scoresheet draw a dash there rather than a
    /// zero, a distinction a missing key can make and a value of 0 cannot.
    func test_roundsBeforeAJoinCarryNoEntryForTheJoinerRatherThanAZero() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cara")
        let match = makeMatch(
            entrants: [a, b, c],
            rounds: [
                Round(deltas: [a.id: 20, b.id: 5]),
                Round(deltas: [a.id: 10, b.id: 15], joins: [JoinEvent(id: c.id, to: 30)]),
                Round(deltas: [a.id: 5, b.id: 5, c.id: 12]),
            ]
        )

        let scoresheet = Scoresheet(match: match, engine: engine)

        XCTAssertNil(scoresheet.rows[0].deltas[c.id])
        // The join Round reads like a Rejoin's: the total they entered on,
        // shown as the jump it is.
        XCTAssertEqual(scoresheet.rows[1].deltas[c.id], 30)
        XCTAssertEqual(scoresheet.rows[2].deltas[c.id], 12)
    }
}
