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
        gostergeFinds: [Entrant.ID: Int] = [:],
        cifteOn: Bool = false,
        theme: Theme,
        testName: String = #function
    ) {
        let view = OkeyStandardRoundEntryView(
            entrants: entrants,
            roundNumber: 3,
            losingEntrantID: losingEntrantID,
            gostergeFinds: gostergeFinds,
            cifteOn: cifteOn
        ) { _, _, _ in }
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

    func test_teamSelectedWithGostergeFinds_paper() {
        assertEntry(losingEntrantID: teamB.id, gostergeFinds: [teamA.id: 1], theme: .paper)
    }

    func test_teamSelectedWithGostergeFinds_felt() {
        assertEntry(losingEntrantID: teamB.id, gostergeFinds: [teamA.id: 1], theme: .felt)
    }

    func test_okeyStandardCifteOn_paper() {
        assertEntry(losingEntrantID: teamB.id, cifteOn: true, theme: .paper)
    }

    func test_okeyStandardCifteOn_felt() {
        assertEntry(losingEntrantID: teamB.id, cifteOn: true, theme: .felt)
    }
}
