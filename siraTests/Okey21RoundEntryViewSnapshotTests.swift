import XCTest
import SwiftUI
import SnapshotTesting
@testable import sira

final class Okey21RoundEntryViewSnapshotTests: XCTestCase {
    private let teamA = Entrant(name: "Ekrem & Su")
    private let teamB = Entrant(name: "Ada & Barış")

    private var entrants: [Entrant] { [teamA, teamB] }

    private func assertEntry(
        losingEntrantID: Entrant.ID? = nil,
        gostergeFinderID: Entrant.ID? = nil,
        cifteCallers: Set<Entrant.ID> = [],
        okeyAttiOn: Bool = false,
        theme: Theme,
        testName: String = #function
    ) {
        let view = Okey21RoundEntryView(
            entrants: entrants,
            roundNumber: 3,
            losingEntrantID: losingEntrantID,
            gostergeFinderID: gostergeFinderID,
            cifteCallers: cifteCallers,
            okeyAttiOn: okeyAttiOn
        ) { _, _, _, _ in }
        .environment(\.theme, theme)
        .frame(width: 402, height: 874)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 874)), testName: testName)
    }

    func test_noTeamSelected_paper() {
        assertEntry(theme: .paper)
    }

    func test_noTeamSelected_felt() {
        assertEntry(theme: .felt)
    }

    func test_teamSelectedWithGostergeFind_paper() {
        assertEntry(losingEntrantID: teamB.id, gostergeFinderID: teamA.id, theme: .paper)
    }

    func test_teamSelectedWithGostergeFind_felt() {
        assertEntry(losingEntrantID: teamB.id, gostergeFinderID: teamA.id, theme: .felt)
    }

    func test_okey21CifteOn_paper() {
        assertEntry(losingEntrantID: teamB.id, cifteCallers: [teamA.id], theme: .paper)
    }

    func test_okey21CifteOn_felt() {
        assertEntry(losingEntrantID: teamB.id, cifteCallers: [teamA.id], theme: .felt)
    }

    func test_okey21CifteCalledByBothTeams_paper() {
        assertEntry(losingEntrantID: teamB.id, cifteCallers: [teamA.id, teamB.id], theme: .paper)
    }

    func test_okey21CifteCalledByBothTeams_felt() {
        assertEntry(losingEntrantID: teamB.id, cifteCallers: [teamA.id, teamB.id], theme: .felt)
    }

    func test_okey21OkeyAttiOn_paper() {
        assertEntry(losingEntrantID: teamB.id, okeyAttiOn: true, theme: .paper)
    }

    func test_okey21OkeyAttiOn_felt() {
        assertEntry(losingEntrantID: teamB.id, okeyAttiOn: true, theme: .felt)
    }

    func test_okey21BothModifiersOn_paper() {
        assertEntry(losingEntrantID: teamB.id, cifteCallers: [teamA.id], okeyAttiOn: true, theme: .paper)
    }

    func test_okey21BothModifiersOn_felt() {
        assertEntry(losingEntrantID: teamB.id, cifteCallers: [teamA.id], okeyAttiOn: true, theme: .felt)
    }
}
