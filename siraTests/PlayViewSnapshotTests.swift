import XCTest
import SwiftUI
import SnapshotTesting
@testable import sira

final class PlayViewSnapshotTests: XCTestCase {
    private func assertPlay(_ match: Match, tab: PlayTab, theme: Theme, testName: String = #function) {
        let view = NavigationStack {
            PlayView(match: .constant(match), initialTab: tab)
        }
        .environment(\.theme, theme)
        .frame(width: 402, height: 874)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 874)), testName: testName)
    }

    private var midMatch: Match {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cem")
        return Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [a, b, c],
            rounds: [
                Round(deltas: [a.id: 20, b.id: 34, c.id: 12]),
                Round(deltas: [a.id: 10, b.id: 22, c.id: 41]),
            ]
        )
    }

    private var overMatch: Match {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        return Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 20, b.id: 110])]
        )
    }

    func test_standingsMidMatch_paper() {
        assertPlay(midMatch, tab: .standings, theme: .paper)
    }

    func test_standingsMidMatch_felt() {
        assertPlay(midMatch, tab: .standings, theme: .felt)
    }

    func test_standingsMatchOver_paper() {
        assertPlay(overMatch, tab: .standings, theme: .paper)
    }

    func test_standingsMatchOver_felt() {
        assertPlay(overMatch, tab: .standings, theme: .felt)
    }

    func test_scoresheet_paper() {
        assertPlay(midMatch, tab: .scoresheet, theme: .paper)
    }

    func test_scoresheet_felt() {
        assertPlay(midMatch, tab: .scoresheet, theme: .felt)
    }
}
