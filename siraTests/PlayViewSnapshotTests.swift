import XCTest
import SwiftUI
import SwiftData
import SnapshotTesting
@testable import sira

final class PlayViewSnapshotTests: XCTestCase {
    private func assertPlay(_ match: Match, tab: PlayTab, theme: Theme, testName: String = #function) {
        // Play mutates only through the store, so it needs one even to render a
        // Match it never changes — the alternative was an optional store, which
        // would have left the buttons looking live while dropping every Round.
        let store = MatchStore()
        store.add(match)
        let view = NavigationStack {
            PlayView(match: match, initialTab: tab)
        }
        .environment(store)
        .modelContainer(store.container)
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

    /// An Okey 101 Match whose middle Rounds were doubled — one by Okey atmak,
    /// one by a Çifte call — so the scoresheet has both annotations to draw.
    private var doubledMatch: Match {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cem")
        return Match(
            game: .okey,
            variant: .okey101,
            mode: .players,
            entrants: [a, b, c],
            rounds: [
                Round(deltas: [a.id: 20, b.id: 34, c.id: 12]),
                Round(deltas: [a.id: 0, b.id: 22, c.id: 41], okeyAtanID: a.id),
                Round(deltas: [a.id: 15, b.id: 0, c.id: 30], cifteCallers: [b.id, c.id]),
            ]
        )
    }

    /// A Match with no Rounds scored yet — Play still heads home rather than
    /// back into Setup.
    private var freshMatch: Match {
        Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [Entrant(name: "Alice"), Entrant(name: "Bob")]
        )
    }

    func test_standingsFreshMatch_felt() {
        assertPlay(freshMatch, tab: .standings, theme: .felt)
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

    func test_scoresheetWithDoubledRounds_paper() {
        assertPlay(doubledMatch, tab: .scoresheet, theme: .paper)
    }

    func test_scoresheetWithDoubledRounds_felt() {
        assertPlay(doubledMatch, tab: .scoresheet, theme: .felt)
    }
}
