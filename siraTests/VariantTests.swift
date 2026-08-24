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

    func test_okeyOffersOkeyAnd101() {
        XCTAssertEqual(Variant.all(for: .okey).map(\.id), ["okey-standard", "okey-101"])
    }

    /// Variant ids are a persistence contract: a Match stores this string and
    /// resolves its rules from it, so renaming one orphans every Match that
    /// names it. Asserted explicitly so a rename fails here rather than
    /// silently orphaning data.
    ///
    /// `gonga-101` and `gonga-151` were retired for `gonga-standard`, and
    /// `okey-21` for `okey-standard`, while this assertion said they were
    /// frozen — a thing to do only on the evidence that made it free: no
    /// release tags, `SiraSchemaV1` still at 1.0.0 with an empty
    /// `SiraMigrationPlan`, and no Match stored on any device — the same
    /// ground `docs/adr/0007` records the previous id rename standing on.
    /// Changing an id after that is a migration, not an edit to this test.
    func test_everyVariantIdIsFrozen() {
        XCTAssertEqual(Variant.gongaStandard.id, "gonga-standard")
        XCTAssertEqual(Variant.okeyStandard.id, "okey-standard")
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

    func test_onlyOkeyIsPlayedInTeams() {
        XCTAssertEqual(Variant.okeyStandard.entrantMode, .teams)
        XCTAssertEqual(Variant.gongaStandard.entrantMode, .players)
        XCTAssertEqual(Variant.okey101.entrantMode, .players)
    }

    /// Merging the two Gongas has not quietly shrunk the table.
    func test_gongaSeatsUpToEightPlayers() {
        XCTAssertEqual(Variant.gongaStandard.maxEntrants, 8)
    }

    func test_okey101SeatsUpToFourPlayersAndOkeyExactlyTwoTeams() {
        XCTAssertEqual(Variant.okey101.maxEntrants, 4)
        XCTAssertEqual(Variant.okeyStandard.maxEntrants, 2)
    }

    // MARK: - Çifte

    func test_gongaHasNoCifteConcept() {
        XCTAssertFalse(Variant.gongaStandard.supportsCifte)
    }

    func test_bothOkeyVariantsSupportCifte() {
        XCTAssertTrue(Variant.okeyStandard.supportsCifte)
        XCTAssertTrue(Variant.okey101.supportsCifte)
    }

    // MARK: - Shape, never values

    /// A Variant describes how a Match is scored and says nothing about how
    /// far it runs. The number is the table's: chosen at Setup and stored on
    /// the Match, so there is no constant here for a later release to move
    /// underneath a Match already resting on it.
    ///
    /// Asserted over every shipped Variant rather than over the three that
    /// used to carry a number, so a fourth cannot arrive with one.
    func test_noVariantCarriesANumberToBePlayedAt() {
        for game in Game.allCases {
            for variant in Variant.all(for: game) {
                XCTAssertNil(variant.limit, "\(variant.id) carries a limit")
                XCTAssertNil(variant.startingScore, "\(variant.id) carries a starting score")
                XCTAssertNil(variant.roundCount, "\(variant.id) carries a Round count")
            }
        }
    }

    func test_okeyStandardIsLabelledOkey() {
        XCTAssertEqual(Variant.okeyStandard.label, "Okey")
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

    func test_okeyReadsItsRulesBackAtWhateverStartingScoreIsChosen() {
        XCTAssertEqual(
            Variant.okeyStandard.ruleText(at: 31),
            "Teams of 2 count down from 31. The losing team takes \u{2212}2 each Round; each Gösterge find deducts 1 from the other team. First team to reach 0 loses."
        )
    }

    /// The Picker card runs before Setup has asked for the starting score, so
    /// it may not quote the one it used to be named after.
    func test_okeysPickerRuleTextQuotesNoNumber() {
        XCTAssertFalse(Variant.okeyStandard.ruleText.contains("21"))
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
