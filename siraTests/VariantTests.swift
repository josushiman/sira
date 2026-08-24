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

    // "No Variant carries the number it is played at" is enforced by the type
    // and so has no test here: `Variant` declares no `limit`, `startingScore`
    // or `roundCount`, leaving nothing for a fourth Variant to arrive with and
    // nothing for a caller to read instead of `Match.variantNumber`.

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

    /// A Round count of 1 is inside `VariantParameter`'s legal range, and the
    /// readback has to survive it — the same singular `VariantParameter` gets
    /// right in the Match's number phrase.
    func test_aSingleRoundReadsBackInTheSingular() {
        XCTAssertEqual(
            Variant.okey101.ruleText(at: 1),
            "Individuals only. Accumulate points each Round over 1 Round. Lowest total when the Rounds run out wins."
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

    /// Nothing renders Gonga's `ruleText` today: the Picker is the only screen
    /// that shows it and Gonga skips the Picker, while Setup shows its header
    /// off `label` and its blurb off `ruleText(at:)`. It is kept against a
    /// second Gonga Variant, which would put Gonga back through the Picker and
    /// this string on a card — and it is asserted now, while it is cheap, so
    /// that the day it is rendered it is not quoting a limit the player has not
    /// been asked for yet.
    func test_gongasPickerRuleTextQuotesNoNumber() {
        XCTAssertFalse(Variant.gongaStandard.ruleText.contains("101"))
        XCTAssertFalse(Variant.gongaStandard.ruleText.contains("151"))
    }

    func test_gongaIsLabelledGonga() {
        XCTAssertEqual(Variant.gongaStandard.label, "Gonga")
    }
}
