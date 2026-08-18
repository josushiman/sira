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
}
