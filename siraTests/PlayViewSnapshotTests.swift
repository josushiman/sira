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
            variant: .gongaStandard,
            number: 101,
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
            variant: .gongaStandard,
            number: 101,
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
            number: 8,
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
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [Entrant(name: "Alice"), Entrant(name: "Bob")]
        )
    }

    /// Four Entrants level at the top — the longest Closest to out copy a
    /// Gonga table is likely to produce, and the check that naming all of them
    /// still fits the tile rather than needing one picked arbitrarily.
    private var tiedMatch: Match {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cem")
        let d = Entrant(name: "Dila")
        return Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [a, b, c, d],
            rounds: [Round(deltas: [a.id: 40, b.id: 40, c.id: 40, d.id: 40])]
        )
    }

    /// A name far longer than a row is wide, among short ones. Setup accepts a
    /// name of any length, so this is a Match a player can really make — and
    /// Rename will let them make it from Play too. It is the long name that
    /// has to give way: not the dot-badge, not the Out tag beside it, not the
    /// progress bar or the "N left" figure under it, and not the Scoresheet's
    /// other columns.
    ///
    /// The long-named Entrant is the one who busts, so the Standings row has a
    /// tag beside the truncated name rather than the name alone. That is the
    /// Out tag; a leader's Leads tag is wider still, and no fixture can hold
    /// both, since an Entrant who is Out is never the one leading.
    ///
    /// Only `.paper` is snapshotted. A Theme changes what the row is painted
    /// in and not how wide anything in it is, so a felt pair would cost a
    /// second reference image to assert the same truncation twice.
    private var longNameMatch: Match {
        let a = Entrant(name: "AbdurrahmanoğullarındanmışçasınaymışAbdurrahmanoğullarındanmışçasınaymış")
        let b = Entrant(name: "Bo")
        let c = Entrant(name: "Cem")
        let d = Entrant(name: "Dila")
        return Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [a, b, c, d],
            rounds: [
                Round(deltas: [a.id: 60, b.id: 34, c.id: 12, d.id: 20]),
                Round(deltas: [a.id: 60, b.id: 10, c.id: 5, d.id: 8]),
            ]
        )
    }

    func test_standingsTiedClosestToOut_paper() {
        assertPlay(tiedMatch, tab: .standings, theme: .paper)
    }

    func test_standingsTiedClosestToOut_felt() {
        assertPlay(tiedMatch, tab: .standings, theme: .felt)
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

    func test_standingsLongName_paper() {
        assertPlay(longNameMatch, tab: .standings, theme: .paper)
    }

    func test_scoresheetLongName_paper() {
        assertPlay(longNameMatch, tab: .scoresheet, theme: .paper)
    }
}
