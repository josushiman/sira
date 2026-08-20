import XCTest
@testable import sira

final class VariantTests: XCTestCase {
    // MARK: - Catalogue

    func test_gongaOffersBoth101And151() {
        XCTAssertEqual(Variant.all(for: .gonga).map(\.id), ["gonga-101", "gonga-151"])
    }

    func test_okeyOffersStandardAnd101() {
        XCTAssertEqual(Variant.all(for: .okey).map(\.id), ["okey-21", "okey-101"])
    }

    /// Variant ids are a persistence contract: a Match stores this string and
    /// resolves its rules from it, so renaming one orphans every Match that
    /// names it. Asserted explicitly so a rename fails here rather than
    /// silently orphaning data.
    func test_everyVariantIdIsFrozen() {
        XCTAssertEqual(Variant.gonga101.id, "gonga-101")
        XCTAssertEqual(Variant.gonga151.id, "gonga-151")
        XCTAssertEqual(Variant.okeyStandard.id, "okey-21")
        XCTAssertEqual(Variant.okey101.id, "okey-101")
    }

    func test_everyVariantBelongsToTheGameItIsListedUnder() {
        for game in Game.allCases {
            for variant in Variant.all(for: game) {
                XCTAssertEqual(variant.game, game, "\(variant.id) is listed under \(game)")
            }
        }
    }

    // MARK: - Entrant mode

    func test_onlyOkeyStandardIsPlayedInTeams() {
        XCTAssertEqual(Variant.okeyStandard.entrantMode, .teams)
        XCTAssertEqual(Variant.gonga101.entrantMode, .players)
        XCTAssertEqual(Variant.gonga151.entrantMode, .players)
        XCTAssertEqual(Variant.okey101.entrantMode, .players)
    }

    func test_gongaSeatsUpToEightPlayers() {
        XCTAssertEqual(Variant.gonga101.maxEntrants, 8)
        XCTAssertEqual(Variant.gonga151.maxEntrants, 8)
    }

    func test_okey101SeatsUpToFourPlayersAndOkeyStandardExactlyTwoTeams() {
        XCTAssertEqual(Variant.okey101.maxEntrants, 4)
        XCTAssertEqual(Variant.okeyStandard.maxEntrants, 2)
    }

    // MARK: - Çifte

    func test_gongaHasNoCifteConcept() {
        XCTAssertFalse(Variant.gonga101.supportsCifte)
        XCTAssertFalse(Variant.gonga151.supportsCifte)
    }

    func test_bothOkeyVariantsSupportCifte() {
        XCTAssertTrue(Variant.okeyStandard.supportsCifte)
        XCTAssertTrue(Variant.okey101.supportsCifte)
    }

    // MARK: - Scoring parameters

    func test_survivalVariantsCarryTheirOwnLimit() {
        XCTAssertEqual(Variant.gonga101.limit, 101)
        XCTAssertEqual(Variant.gonga151.limit, 151)
    }

    func test_okeyStandardCountsDownFromTwentyOne() {
        XCTAssertEqual(Variant.okeyStandard.startingScore, 21)
    }

    func test_okeyStandardIsLabelledOkey21() {
        XCTAssertEqual(Variant.okeyStandard.label, "Okey 21")
    }
}
