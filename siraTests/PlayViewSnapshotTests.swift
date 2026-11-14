import XCTest
import SwiftUI
import SwiftData
import SnapshotTesting
@testable import sira

final class PlayViewSnapshotTests: XCTestCase {
    /// The same native scroll composition as Play, starting at the bottom so
    /// the reference covers three-digit Rounds, the retained header and totals.
    private func assertLongScoresheet(theme: Theme, names: [String], width: CGFloat = 320,
                                      size: DynamicTypeSize = .large, testName: String = #function) {
        let entrants = names.map { Entrant(name: $0) }
        let rounds = (0..<104).map { index in
            let winner = entrants[index % 4].id
            let deltas = Dictionary(uniqueKeysWithValues: zip(entrants, [20, 30, 40, 50]).map {
                ($0.id, $0.id == winner ? 0 : $1)
            })
            return Round(deltas: deltas, cifteCallers: index % 4 == 1 ? [entrants[0].id] : [],
                         okeyAtanID: index % 4 == 2 ? winner : nil)
        }
        let match = Match(game: .okey, variant: .okey101, mode: .players, entrants: entrants, rounds: rounds)
        let view = ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ScoresheetView(match: match, engine: LowestTotalEngine())
            }
            .padding(.horizontal, 22)
        }
        .defaultScrollAnchor(.bottom)
        .background(theme.background)
        .foregroundStyle(theme.ink)
        .environment(\.theme, theme)
        .dynamicTypeSize(size)
        .frame(width: width, height: 520)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: width, height: 520)), testName: testName)
    }

    func test_okey101LongScoresheetCompact_paper() {
        assertLongScoresheet(theme: .paper, names: ["Alice", "Bob", "Cem", "Dila"])
    }

    func test_okey101LongScoresheetCompact_felt() {
        assertLongScoresheet(theme: .felt, names: ["Alice", "Bob", "Cem", "Dila"])
    }

    func test_okey101LongScoresheetDefaultNames_paper() {
        assertLongScoresheet(theme: .paper, names: ["Player 1", "Player 2", "Player 3", "Player 4"])
    }

    func test_okey101LongScoresheetLongNamesLargerType_felt() {
        assertLongScoresheet(theme: .felt, names: ["Alexandra", "Benedict", "Cemalettin", "Dilara"],
                            width: 375, size: .xxxLarge)
    }

    private func assertPlay(_ match: Match, tab: PlayTab, theme: Theme, testName: String = #function) {
        // Play mutates only through the store, so it needs one even to render a
        // Match it never changes — the alternative was an optional store, which
        // would have left the buttons looking live while dropping every Round.
        let store = MatchStore()
        store.add(match)
        // Snapshot screen content directly. Navigation is covered separately;
        // nested NavigationStack hosts leak toolbar insets between iOS 27 renders.
        let view = PlayView(match: match, initialTab: tab)
        .environment(store)
        .modelContainer(store.container)
        .environment(\.theme, theme)
        .frame(width: 402, height: 874)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 874)), testName: testName)
    }

    private func endableMatch(tied: Bool = false, allTied: Bool = false) -> Match {
        let entrants = ["Alice", "Bob", "Cem", "Dila"].map { Entrant(name: $0) }
        let scores = allTied ? [70, 70, 70, 70] : (tied ? [70, 105, 70, 165] : [70, 105, 100, 165])
        return Match(game: .okey, variant: .okey101, mode: .players, entrants: entrants,
                     rounds: [Round(deltas: Dictionary(uniqueKeysWithValues: zip(entrants.map(\.id), scores)))])
    }

    private func assertEndConfirmation(theme: Theme, tied: Bool = false, testName: String = #function) {
        let view = EndMatchSheet(match: endableMatch(tied: tied), onEnd: {})
            .environment(\.theme, theme)
            .frame(width: 402, height: 650)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 650)), testName: testName)
    }

    func test_okey101EndConfirmation_paper() { assertEndConfirmation(theme: .paper) }
    func test_okey101EndConfirmation_felt() { assertEndConfirmation(theme: .felt) }
    func test_okey101TiedEndConfirmation_paper() { assertEndConfirmation(theme: .paper, tied: true) }
    func test_okey101TiedEndConfirmation_felt() { assertEndConfirmation(theme: .felt, tied: true) }

    func test_okey101TiedEndConfirmationLargeType_paper() {
        let view = EndMatchSheet(match: endableMatch(allTied: true), onEnd: {})
            .environment(\.theme, .paper)
            .dynamicTypeSize(.accessibility3)
            .frame(width: 402, height: 874)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 874)))
    }

    private func assertEnded(tab: PlayTab = .standings, theme: Theme, tied: Bool = false, testName: String = #function) {
        let match = endableMatch(tied: tied)
        match.end()
        assertPlay(match, tab: tab, theme: theme, testName: testName)
    }

    func test_okey101EndedStandings_paper() { assertEnded(theme: .paper) }
    func test_okey101EndedStandings_felt() { assertEnded(theme: .felt) }
    func test_okey101TiedEndedStandings_paper() { assertEnded(theme: .paper, tied: true) }
    func test_okey101TiedEndedStandings_felt() { assertEnded(theme: .felt, tied: true) }
    func test_okey101ReadOnlyScoresheet_paper() { assertEnded(tab: .scoresheet, theme: .paper) }
    func test_okey101ReadOnlyScoresheet_felt() { assertEnded(tab: .scoresheet, theme: .felt) }
    private func assertResumed(tab: PlayTab = .standings, theme: Theme, testName: String = #function) {
        let match = endableMatch(tied: true)
        match.end()
        match.resume()
        assertPlay(match, tab: tab, theme: theme, testName: testName)
    }
    func test_okey101ResumedStandings_paper() { assertResumed(theme: .paper) }
    func test_okey101ResumedStandings_felt() { assertResumed(theme: .felt) }
    func test_okey101ResumedScoresheet_paper() { assertResumed(tab: .scoresheet, theme: .paper) }
    func test_okey101ResumedScoresheet_felt() { assertResumed(tab: .scoresheet, theme: .felt) }
    func test_okey101AllTiedLongNamesRemainReadable_felt() {
        let match = endableMatch(allTied: true)
        for (entrant, name) in zip(match.entrants, ["Alexandra", "Benedict", "Cemalettin", "Dilara"]) {
            entrant.name = name
        }
        match.end()
        assertPlay(match, tab: .standings, theme: .felt)
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

    /// A Gonga table with every seat taken. There is nowhere to put a
    /// newcomer, so the Add row is gone rather than present and refusing.
    private var fullTableMatch: Match {
        let entrants = (0..<Variant.gongaStandard.maxEntrants).map { Entrant(name: "P\($0 + 1)") }
        return Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: entrants,
            rounds: [Round(deltas: Dictionary(uniqueKeysWithValues: entrants.map { ($0.id, 12) }))]
        )
    }

    /// Okey 101 with two of its four seats free — the case a free-seat rule
    /// alone would let through. There is no running total a newcomer could be
    /// brought in on, so there is no row.
    private var okey101RoomToSpareMatch: Match {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        return Match(
            game: .okey,
            variant: .okey101,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 20, b.id: 0])]
        )
    }

    /// The Add row as the table reads it before agreeing to anything: the free
    /// seat's colour in outline, and the score the newcomer would start on.
    /// Alice is Out on the highest total there is, which is the total the row
    /// must *not* be previewing.
    private var addableMatch: Match {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cem")
        return Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [a, b, c],
            rounds: [Round(deltas: [a.id: 120, b.id: 61, c.id: 40])]
        )
    }

    func test_standingsAddRow_paper() {
        assertPlay(addableMatch, tab: .standings, theme: .paper)
    }

    func test_standingsAddRow_felt() {
        assertPlay(addableMatch, tab: .standings, theme: .felt)
    }

    /// The three ways the row is hidden entirely. Only `.paper` for each: what
    /// is being asserted is an absence, and an absence looks the same in both
    /// Themes.
    func test_standingsNoAddRowAtAFullTable_paper() {
        assertPlay(fullTableMatch, tab: .standings, theme: .paper)
    }

    func test_standingsNoAddRowOnAnOkeyMatch_paper() {
        assertPlay(okey101RoomToSpareMatch, tab: .standings, theme: .paper)
    }

    func test_okey101LiveStandings_paper() {
        assertPlay(doubledMatch, tab: .standings, theme: .paper)
    }

    func test_okey101LiveStandings_felt() {
        assertPlay(doubledMatch, tab: .standings, theme: .felt)
    }

    private var freshOkey101: Match {
        Match(game: .okey, variant: .okey101, mode: .players,
              entrants: [Entrant(name: "Alice"), Entrant(name: "Bob"), Entrant(name: "Cem"), Entrant(name: "Dila")])
    }

    func test_okey101ZeroRounds_paper() {
        assertPlay(freshOkey101, tab: .standings, theme: .paper)
    }

    func test_okey101ZeroRounds_felt() {
        assertPlay(freshOkey101, tab: .standings, theme: .felt)
    }

    func test_standingsNoAddRowOnADecidedMatch_paper() {
        assertPlay(overMatch, tab: .standings, theme: .paper)
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
