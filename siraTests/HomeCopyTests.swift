import XCTest
@testable import sira

/// Home's catalogue copy counts the catalogue rather than quoting it. The
/// literal readings are pinned alongside the counts they came from, so a
final class HomeCopyTests: XCTestCase {
    func test_theHeroLineExplainsTheValueOfTrackingScoresHere() {
        XCTAssertEqual(HomeCopy.heroLine, "Track every round in one place — no pen and paper needed.")
    }

    func test_aGameCardSaysHowManyVariantsItLeadsTo() {
        XCTAssertEqual(HomeCopy.gameSubtitle(for: .gonga), "1 variant")
        XCTAssertEqual(HomeCopy.gameSubtitle(for: .okey), "2 variants")
    }

    /// The retired names are what this whole pass is for: no Home copy may
    /// advertise a Variant that no longer exists.
    func test_noHomeCopyNamesARetiredVariant() {
        let copy = [HomeCopy.heroLine, HomeCopy.gameSubtitle(for: .gonga), HomeCopy.gameSubtitle(for: .okey)]

        for line in copy {
            for retired in ["101 / 151", "21 / 101", "Okey 21", "Gonga 151"] {
                XCTAssertFalse(line.contains(retired), "\(line) still names \(retired)")
            }
        }
    }
}
