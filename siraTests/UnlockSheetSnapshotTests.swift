import XCTest
import SwiftUI
import SnapshotTesting
@testable import sira

/// The offer, in every state it has, in both themes (`docs/adr/0004`).
///
/// Both themes because `accent` is gold in Felt and dark green in Paper, with
/// `onAccent` flipping to match: a sheet that leaned on the gold would be
/// unreadable the moment it was recoloured, and the only way to know it was not
/// is to look at both. Prior art is `RejoinSheetSnapshotTests`, which composes
/// the same `DecisionSheet`.
///
/// The price is a long localised string throughout, deliberately: the layout
/// that has to hold is the one a player outside the UK sees, and it is the
/// wider of the two.
final class UnlockSheetSnapshotTests: XCTestCase {
    /// Neither the real price nor a plausible one — what Sıra charges is App
    /// Store Connect's to say and StoreKit's to render. Long enough to prove
    /// the button does not break around it.
    private let price = "1.234,56 TL"

    private func assertSheet(
        _ status: UnlockStore.Status,
        theme: Theme,
        displayPrice: String?,
        testName: String = #function
    ) {
        let view = UnlockSheet(
            displayPrice: displayPrice,
            status: status,
            onBuy: {},
            onRestore: {}
        )
        .environment(\.theme, theme)
        // Pinned rather than left to the simulator's own setting. The sheet
        // draws its own surface but its text inherits the ambient foreground,
        // so a device sitting in dark appearance renders Paper's cream sheet
        // with white type on it — a difference that is the simulator's and not
        // the app's, and one that has no business failing this test.
        .environment(\.colorScheme, theme == .paper ? .light : .dark)
        .frame(width: 402, height: 900)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 900)), testName: testName)
    }

    // MARK: - Default

    func test_offer_paper() {
        assertSheet(.ready, theme: .paper, displayPrice: price)
    }

    func test_offer_felt() {
        assertSheet(.ready, theme: .felt, displayPrice: price)
    }

    // MARK: - In flight

    /// Apple has the purchase and draws its own payment sheet over this one.
    /// The app's controls are visibly out of reach rather than gone.
    func test_purchaseInFlight_paper() {
        assertSheet(.inFlight, theme: .paper, displayPrice: price)
    }

    func test_purchaseInFlight_felt() {
        assertSheet(.inFlight, theme: .felt, displayPrice: price)
    }

    // MARK: - Failed

    func test_purchaseFailed_paper() {
        assertSheet(.purchaseFailed(UnlockCopy.purchaseFailed), theme: .paper, displayPrice: price)
    }

    func test_purchaseFailed_felt() {
        assertSheet(.purchaseFailed(UnlockCopy.purchaseFailed), theme: .felt, displayPrice: price)
    }

    // MARK: - Restore found nothing

    func test_nothingToRestore_paper() {
        assertSheet(.nothingToRestore, theme: .paper, displayPrice: price)
    }

    func test_nothingToRestore_felt() {
        assertSheet(.nothingToRestore, theme: .felt, displayPrice: price)
    }

    // MARK: - Waiting for approval

    /// Ask to Buy. Neither bought nor failed — the request is with somebody
    /// else, and the app unlocks by itself when they approve it. A fifth state
    /// beyond the four the ticket names, and one that ships on screen, so it is
    /// snapshot like the rest.
    func test_awaitingApproval_paper() {
        assertSheet(.awaitingApproval, theme: .paper, displayPrice: price)
    }

    func test_awaitingApproval_felt() {
        assertSheet(.awaitingApproval, theme: .felt, displayPrice: price)
    }

    // MARK: - No price yet

    /// StoreKit has not answered — offline at launch. The button keeps a word
    /// of its own rather than a gap where a price should be.
    func test_offerWithNoPriceYet_paper() {
        assertSheet(.ready, theme: .paper, displayPrice: nil)
    }

    func test_offerWithNoPriceYet_felt() {
        assertSheet(.ready, theme: .felt, displayPrice: nil)
    }
}
