import XCTest
import SwiftUI
import SnapshotTesting
@testable import sira

final class OkeyStandardRoundEntryViewSnapshotTests: XCTestCase {
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
        let view = OkeyStandardRoundEntryView(
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

    func test_okeyStandardCifteOn_paper() {
        assertEntry(losingEntrantID: teamB.id, cifteCallers: [teamA.id], theme: .paper)
    }

    func test_okeyStandardCifteOn_felt() {
        assertEntry(losingEntrantID: teamB.id, cifteCallers: [teamA.id], theme: .felt)
    }

    func test_okeyStandardCifteCalledByBothTeams_paper() {
        assertEntry(losingEntrantID: teamB.id, cifteCallers: [teamA.id, teamB.id], theme: .paper)
    }

    func test_okeyStandardCifteCalledByBothTeams_felt() {
        assertEntry(losingEntrantID: teamB.id, cifteCallers: [teamA.id, teamB.id], theme: .felt)
    }

    func test_okeyStandardOkeyAttiOn_paper() {
        assertEntry(losingEntrantID: teamB.id, okeyAttiOn: true, theme: .paper)
    }

    func test_okeyStandardOkeyAttiOn_felt() {
        assertEntry(losingEntrantID: teamB.id, okeyAttiOn: true, theme: .felt)
    }

    func test_okeyStandardBothModifiersOn_paper() {
        assertEntry(losingEntrantID: teamB.id, cifteCallers: [teamA.id], okeyAttiOn: true, theme: .paper)
    }

    func test_okeyStandardBothModifiersOn_felt() {
        assertEntry(losingEntrantID: teamB.id, cifteCallers: [teamA.id], okeyAttiOn: true, theme: .felt)
    }
}
