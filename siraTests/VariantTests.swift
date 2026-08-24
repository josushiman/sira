import XCTest
@testable import sira

final class VariantTests: XCTestCase {
    // MARK: - Catalogue

    /// One Gonga, not two. The limit that used to be the difference between
    /// them is a number Setup asks for, so there is nothing left to pick
    /// between — which is why Home lands on Setup rather than the Picker.
    func test_gongaOffersOneVariant() {
        XCTAssertEqual(Variant.all(for: .gonga).map(\.id), ["gonga-standard"])
    }

    func test_okeyOffers21And101() {
        XCTAssertEqual(Variant.all(for: .okey).map(\.id), ["okey-21", "okey-101"])
    }

    /// Variant ids are a persistence contract: a Match stores this string and
    /// resolves its rules from it, so renaming one orphans every Match that
    /// names it. Asserted explicitly so a rename fails here rather than
    /// silently orphaning data.
    func test_everyVariantIdIsFrozen() {
        XCTAssertEqual(Variant.gongaStandard.id, "gonga-standard")
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
        XCTAssertEqual(Variant.gongaStandard.entrantMode, .players)
        XCTAssertEqual(Variant.okey101.entrantMode, .players)
    }

    /// Merging the two Gongas has not quietly shrunk the table.
    func test_gongaSeatsUpToEightPlayers() {
        XCTAssertEqual(Variant.gongaStandard.maxEntrants, 8)
    }

    func test_okey101SeatsUpToFourPlayersAndOkey21ExactlyTwoTeams() {
        XCTAssertEqual(Variant.okey101.maxEntrants, 4)
        XCTAssertEqual(Variant.okey21.maxEntrants, 2)
    }

    // MARK: - Çifte

    func test_gongaHasNoCifteConcept() {
        XCTAssertFalse(Variant.gongaStandard.supportsCifte)
    }

    func test_bothOkeyVariantsSupportCifte() {
        XCTAssertTrue(Variant.okey21.supportsCifte)
        XCTAssertTrue(Variant.okey101.supportsCifte)
    }

    // MARK: - Scoring parameters

    /// The constant a Gonga Match carrying no limit of its own is scored by,
    /// which is every Match started before Setup asked for one. It goes with
    /// the rest of the Variant values once nothing falls back to it.
    func test_survivalVariantsCarryTheirOwnLimit() {
        XCTAssertEqual(Variant.gongaStandard.limit, 101)
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

    func test_gongaReadsItsRulesBackAtWhateverLimitIsChosen() {
        XCTAssertEqual(
            Variant.gongaStandard.ruleText(at: 201),
            "Accumulate points each Round. Go over 201 and you're Out. Last one standing wins."
        )
    }

    /// Okey gains its own along with its chips.
    func test_onlyTheVariantThatAsksForANumberReadsItsRulesBack() {
        XCTAssertNil(Variant.okey21.ruleText(at: 21))
    }

    /// The Picker never shows Gonga now, but its card copy is what Setup's
    /// header and any future second Gonga would read, and it may not quote a
    /// limit the player has not been asked for yet.
    func test_gongasPickerRuleTextQuotesNoNumber() {
        XCTAssertFalse(Variant.gongaStandard.ruleText.contains("101"))
        XCTAssertFalse(Variant.gongaStandard.ruleText.contains("151"))
    }

    func test_gongaIsLabelledGonga() {
        XCTAssertEqual(Variant.gongaStandard.label, "Gonga")
    }
}
