import XCTest
import SwiftUI
@testable import sira

final class ThemeTests: XCTestCase {
    func test_lightColorSchemeResolvesToPaper() {
        XCTAssertEqual(Theme.resolved(for: .light), .paper)
    }

    func test_darkColorSchemeResolvesToFelt() {
        XCTAssertEqual(Theme.resolved(for: .dark), .felt)
    }

    /// Gonga seats up to 8 players, so every Entrant at a full table needs a
    /// distinct badge color rather than wrapping onto an earlier one.
    func test_bothThemesHaveOneDistinctDotColorPerMaximumTableSize() {
        for theme in [Theme.paper, Theme.felt] {
            XCTAssertEqual(theme.dots.count, 8, "\(theme.name)")
            XCTAssertEqual(Set(theme.dots).count, 8, "\(theme.name) has duplicate dot colors")
        }
    }
}
