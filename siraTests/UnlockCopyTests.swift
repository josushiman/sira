import XCTest
@testable import sira

/// What the offer sheet claims, asserted the way `DeleteMatchSheet`'s
/// explanation is.
///
/// This is the app asking for money. Two things about the wording are
/// load-bearing and neither can be left to be checked by eye: it must not name
/// a price, and it must not claim to unlock a feature that is already free.
final class UnlockCopyTests: XCTestCase {
    /// Everything the sheet can put on screen, in one list, so that a line
    /// added later is covered by these tests without being added to them.
    private var everyLine: [String] {
        UnlockCopy.benefits + [
            UnlockCopy.title,
            UnlockCopy.explanation,
            UnlockCopy.buy(price: nil),
            UnlockCopy.buyInFlight,
            UnlockCopy.restore,
            UnlockCopy.redeemCode,
            UnlockCopy.dismiss,
            UnlockCopy.purchaseFailed,
            UnlockCopy.nothingToRestore,
            UnlockCopy.restoreFailed,
            UnlockCopy.awaitingApproval
        ]
    }

    /// The price is StoreKit's for the player's storefront, always. A number
    /// written down here is right in one country and wrong everywhere else, and
    /// wrong everywhere the day the tier changes.
    func test_noLineNamesAPriceOfItsOwn() {
        for line in everyLine {
            XCTAssertFalse(
                line.contains(where: \.isNumber),
                "\"\(line)\" carries a number, and the only number on this sheet is StoreKit's"
            )
            for symbol in ["£", "$", "€", "₺", "TL"] {
                XCTAssertFalse(line.contains(symbol), "\"\(line)\" carries a currency")
            }
        }
    }

    /// Deliberately not the price Sıra charges, in either currency. The literal
    /// this ticket bans should not be greppable anywhere in the repo, test
    /// fixtures included — and what is being asserted is that whatever StoreKit
    /// hands over comes out the other side, which any two strings prove.
    func test_theBuyButtonCarriesTheSuppliedPriceAndNothingElse() {
        XCTAssertEqual(UnlockCopy.buy(price: "£7.49"), "Unlock Sıra for £7.49")
        XCTAssertEqual(UnlockCopy.buy(price: "¥480"), "Unlock Sıra for ¥480")
    }

    /// Only the number of games that can be *started* is gated. Every Variant,
    /// team play, Çifte, Gösterge, Rejoin, Undo, the Scoresheet and Standings
    /// are in the free games and stay there — a benefit line claiming one of
    /// them would be untrue, and inaccurate App Store metadata besides.
    func test_noBenefitClaimsToUnlockAFeature() {
        let features = [
            "Gonga", "Okey", "variant", "Variant", "team", "Team", "Çifte",
            "Gösterge", "Rejoin", "Undo", "Scoresheet", "Standings", "player"
        ]
        for benefit in UnlockCopy.benefits {
            for feature in features {
                XCTAssertFalse(
                    benefit.contains(feature),
                    "\"\(benefit)\" claims to unlock \(feature), which was never locked"
                )
            }
        }
    }

    /// One payment, said in as many words: what the player is agreeing to is
    /// the thing they most need to know before agreeing to it.
    func test_theOfferSaysItIsNotASubscription() {
        let stated = UnlockCopy.explanation + UnlockCopy.benefits.joined(separator: " ")
        XCTAssertTrue(stated.contains("subscription"))
    }

    /// A failure the player can act on: no money moved, and try again.
    func test_everyFailureSaysNoMoneyMoved() {
        for message in [UnlockCopy.purchaseFailed, UnlockCopy.restoreFailed] {
            XCTAssertTrue(message.contains("haven't been charged"), message)
            XCTAssertTrue(message.contains("try again"), message)
        }
    }

    /// Restore finding nothing is an answer rather than an error, so it says
    /// what to do next.
    func test_nothingToRestoreSaysWhatToDoAboutIt() {
        XCTAssertTrue(UnlockCopy.nothingToRestore.contains("Apple Account"))
        XCTAssertTrue(UnlockCopy.nothingToRestore.contains("try again"))
    }

    /// "Games", never "Matches" — Home's own word for them.
    func test_theSheetTalksAboutGamesRatherThanMatches() {
        for line in everyLine {
            XCTAssertFalse(line.contains("Match"), "\"\(line)\" says Match where the player says game")
        }
    }
}
