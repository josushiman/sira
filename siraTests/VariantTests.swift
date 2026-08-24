import XCTest
@testable import sira

final class VariantTests: XCTestCase {
    // MARK: - Catalogue

    func test_gongaOffersBoth101And151() {
        XCTAssertEqual(Variant.all(for: .gonga).map(\.id), ["gonga-101", "gonga-151"])
    }

    func test_okeyOffers21And101() {
        XCTAssertEqual(Variant.all(for: .okey).map(\.id), ["okey-21", "okey-101"])
    }

    /// Variant ids are a persistence contract: a Match stores this string and
    /// resolves its rules from it, so renaming one orphans every Match that
    /// names it. Asserted explicitly so a rename fails here rather than
    /// silently orphaning data.
    func test_everyVariantIdIsFrozen() {
        XCTAssertEqual(Variant.gonga101.id, "gonga-101")
        XCTAssertEqual(Variant.gonga151.id, "gonga-151")
        XCTAssertEqual(Variant.okey21.id, "okey-21")
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

    func test_onlyOkey21IsPlayedInTeams() {
        XCTAssertEqual(Variant.okey21.entrantMode, .teams)
        XCTAssertEqual(Variant.gonga101.entrantMode, .players)
        XCTAssertEqual(Variant.gonga151.entrantMode, .players)
        XCTAssertEqual(Variant.okey101.entrantMode, .players)
    }

    func test_gongaSeatsUpToEightPlayers() {
        XCTAssertEqual(Variant.gonga101.maxEntrants, 8)
        XCTAssertEqual(Variant.gonga151.maxEntrants, 8)
    }

    func test_okey101SeatsUpToFourPlayersAndOkey21ExactlyTwoTeams() {
        XCTAssertEqual(Variant.okey101.maxEntrants, 4)
        XCTAssertEqual(Variant.okey21.maxEntrants, 2)
    }

    // MARK: - Çifte

    func test_gongaHasNoCifteConcept() {
        XCTAssertFalse(Variant.gonga101.supportsCifte)
        XCTAssertFalse(Variant.gonga151.supportsCifte)
    }

    func test_bothOkeyVariantsSupportCifte() {
        XCTAssertTrue(Variant.okey21.supportsCifte)
        XCTAssertTrue(Variant.okey101.supportsCifte)
    }

    // MARK: - Scoring parameters

    func test_survivalVariantsCarryTheirOwnLimit() {
        XCTAssertEqual(Variant.gonga101.limit, 101)
        XCTAssertEqual(Variant.gonga151.limit, 151)
    }

    func test_okey21CountsDownFromTwentyOne() {
        XCTAssertEqual(Variant.okey21.startingScore, 21)
    }

    func test_okey21IsLabelledOkey21() {
        XCTAssertEqual(Variant.okey21.label, "Okey 21")
    }

    // MARK: - The rules read back at a chosen number

    func test_theRulesRestateThemselvesAtWhateverNumberIsChosen() {
        XCTAssertEqual(
            Variant.okey101.ruleText(at: 5),
            "Individuals only. Accumulate points each Round over 5 Rounds. Lowest total when the Rounds run out wins."
        )
    }

    /// The Picker runs before anything is chosen, so its copy cannot quote a
    /// number — it says a number is coming instead of naming one that is not
    /// binding.
    func test_thePickersRuleTextQuotesNoNumber() {
        XCTAssertFalse(Variant.okey101.ruleText.contains("8"))
        XCTAssertFalse(Variant.okey101.ruleText.contains("12"))
    }

    /// Gonga and Okey gain theirs along with their chips.
    func test_onlyTheVariantThatAsksForANumberReadsItsRulesBack() {
        XCTAssertNil(Variant.gonga101.ruleText(at: 101))
        XCTAssertNil(Variant.okey21.ruleText(at: 21))
    }
}
