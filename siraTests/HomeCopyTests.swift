import XCTest
@testable import sira

/// Home's catalogue copy counts the catalogue rather than quoting it. The
/// literal readings are pinned alongside the counts they came from, so a
/// Variant added or retired fails here — one file, next to the reason — rather
/// than leaving Home quietly advertising a catalogue that has moved on, which
/// is exactly what "101 / 151" did.
final class HomeCopyTests: XCTestCase {
    func test_theHeroLineCountsTheGamesAndVariantsThatExist() {
        let variants = Game.allCases.reduce(0) { $0 + Variant.all(for: $1).count }

        XCTAssertEqual(HomeCopy.heroLine, "Two games, three variants, one running tally that nobody can argue with.")
        XCTAssertEqual(Game.allCases.count, 2)
        XCTAssertEqual(variants, 3)
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
