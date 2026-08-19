import XCTest
import SwiftUI
import SnapshotTesting
@testable import sira

final class HomeViewSnapshotTests: XCTestCase {
    private func assertHome(_ store: MatchStore, theme: Theme, testName: String = #function) {
        let view = NavigationStack {
            HomeView()
        }
        .environment(store)
        .environment(\.theme, theme)
        // Pinned "today" so the seeded Matches' card dates render the same way
        // in any year the suite is run.
        .environment(\.now, .fixture(year: 2026, month: 8, day: 19))
        .frame(width: 402, height: 1200)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 1200)), testName: testName)
    }

    func test_populatedMatchListAndInlineGameCards_paper() {
        assertHome(.seeded(), theme: .paper)
    }

    func test_populatedMatchListAndInlineGameCards_felt() {
        assertHome(.seeded(), theme: .felt)
    }

    func test_emptyState_paper() {
        assertHome(MatchStore(), theme: .paper)
    }

    func test_emptyState_felt() {
        assertHome(MatchStore(), theme: .felt)
    }
}
