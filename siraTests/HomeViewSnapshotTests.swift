import XCTest
import SwiftUI
import SwiftData
import SnapshotTesting
@testable import sira

final class HomeViewSnapshotTests: XCTestCase {
    private func assertHome(_ store: MatchStore, theme: Theme, testName: String = #function) {
        let view = NavigationStack {
            HomeView()
        }
        .environment(store)
        .environment(Navigator())
        // Home reads its Matches with `@Query`, which reads the container
        // rather than the store object — without this it renders an empty list
        // whatever the store holds.
        .modelContainer(store.container)
        .environment(\.theme, theme)
        .frame(width: 402, height: 1200)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 1200)), testName: testName)
    }

    func test_populatedMatchListAndInlineGameCards_paper() {
        assertHome(.seeded(), theme: .paper)
    }

    func test_populatedMatchListAndInlineGameCards_felt() {
        assertHome(.seeded(), theme: .felt)
    }

    /// Two Gonga Matches, one to 101 and one to 201. They carry the same
    /// label, so the metadata line is the only thing telling them apart — the
    /// job the two old Gonga Variants used to do with their names.
    ///
    /// The second seats eight, which is also the widest that line gets:
    /// `8 players · to 201` beside a Round pill and the Variant label, in a
    /// row that neither wraps nor truncates. A custom limit is what made it
    /// long enough to be worth pinning.
    private func storeWithTwoLimits() -> MatchStore {
        let store = MatchStore()

        let alice = Entrant(name: "Alice")
        let bob = Entrant(name: "Bob")
        store.add(Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [alice, bob],
            rounds: [Round(deltas: [alice.id: 20, bob.id: 15])],
            createdAt: .fixture(year: 2026, month: 3, day: 14, hour: 21)
        ))

        let eight = ["Carol", "Dede", "Emre", "Fatma", "Gizem", "Hakan", "Işıl", "Kerem"]
            .map { Entrant(name: $0) }
        store.add(Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 201,
            mode: .players,
            entrants: eight,
            rounds: [Round(deltas: Dictionary(uniqueKeysWithValues: eight.enumerated().map { ($0.element.id, $0.offset * 20) }))],
            createdAt: .fixture(year: 2026, month: 3, day: 12, hour: 20)
        ))

        return store
    }

    func test_twoMatchesOfOneVariantAtDifferentLimits_paper() {
        assertHome(storeWithTwoLimits(), theme: .paper)
    }

    func test_twoMatchesOfOneVariantAtDifferentLimits_felt() {
        assertHome(storeWithTwoLimits(), theme: .felt)
    }

    func test_emptyState_paper() {
        assertHome(MatchStore(), theme: .paper)
    }

    func test_emptyState_felt() {
        assertHome(MatchStore(), theme: .felt)
    }

    /// A Match set up and backed out of before its first Round. Home reads as
    /// empty — not as a list with an unscored row in it — which is the whole
    /// visible effect of Started on this screen.
    private func storeWithOnlyAnUnStartedMatch() -> MatchStore {
        let store = MatchStore()
        store.add(Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [Entrant(name: "Alice"), Entrant(name: "Bob")],
            createdAt: .fixture(year: 2026, month: 3, day: 14, hour: 21)
        ))
        return store
    }

    func test_onlyAnUnStartedMatch_paper() {
        assertHome(storeWithOnlyAnUnStartedMatch(), theme: .paper)
    }

    func test_onlyAnUnStartedMatch_felt() {
        assertHome(storeWithOnlyAnUnStartedMatch(), theme: .felt)
    }

    // MARK: - The free-game meter

    /// A store that has played `count` Matches, one Round each — the only way
    /// a free game is spent — with fixed dates so the cards read the same on
    /// every run.
    ///
    /// The Matches are what makes each of these a real Home rather than a
    /// meter on its own: the list grows by one card as the meter fills by one
    /// mark, which is the thing the player is meant to connect.
    private func storeWithFreeGamesUsed(_ count: Int) -> MatchStore {
        let store = MatchStore()
        for index in 0..<count {
            let alice = Entrant(name: "Alice")
            let bob = Entrant(name: "Bob")
            let match = Match(
                game: .gonga,
                variant: .gongaStandard,
                number: 101,
                mode: .players,
                entrants: [alice, bob],
                createdAt: .fixture(year: 2026, month: 3, day: 10 + index, hour: 21)
            )
            store.add(match)
            store.addRound(Round(deltas: [alice.id: 20, bob.id: 15]), to: match)
        }
        return store
    }

    /// Nothing played yet: three free games left, and the meter's first
    /// showing — the one that has to explain itself without a word from
    /// anywhere else on the screen.
    func test_noFreeGamesUsed_paper() {
        assertHome(storeWithFreeGamesUsed(0), theme: .paper)
    }

    func test_noFreeGamesUsed_felt() {
        assertHome(storeWithFreeGamesUsed(0), theme: .felt)
    }

    func test_oneFreeGameUsed_paper() {
        assertHome(storeWithFreeGamesUsed(1), theme: .paper)
    }

    func test_oneFreeGameUsed_felt() {
        assertHome(storeWithFreeGamesUsed(1), theme: .felt)
    }

    func test_twoFreeGamesUsed_paper() {
        assertHome(storeWithFreeGamesUsed(2), theme: .paper)
    }

    func test_twoFreeGamesUsed_felt() {
        assertHome(storeWithFreeGamesUsed(2), theme: .felt)
    }

    /// All three gone. Every mark is filled and the label takes the accent
    /// colour — the meter's only change on reaching the limit. Nothing is
    /// blocked here and no offer appears: that is ticket 03.
    func test_allThreeFreeGamesUsed_paper() {
        assertHome(storeWithFreeGamesUsed(3), theme: .paper)
    }

    func test_allThreeFreeGamesUsed_felt() {
        assertHome(storeWithFreeGamesUsed(3), theme: .felt)
    }
}
