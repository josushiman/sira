import Foundation

/// Every word on the offer sheet.
///
/// Here rather than in the view's body for the reason `DeleteMatchSheet`'s
/// explanation is: this wording is the app asking for money, and what it claims
/// has to be assertable by a test rather than checked by eye. Two things about
/// it are load-bearing.
///
/// **It never names a price.** The number is always StoreKit's `displayPrice`
/// for the player's storefront, handed in — so the price is right in every
/// currency, and a tier change in App Store Connect is not a code change.
///
/// **No benefit claims an existing feature is gated.** Every Variant, team
/// play, Çifte, Gösterge, Rejoin, Undo, the Scoresheet and Standings are all
/// in the free games and stay there. Only the number of games that can be
/// *started* is gated.
///
/// "Games", never "Matches" — Home's own word for them (`CONTEXT.md`).
enum UnlockCopy {
    /// The offer's promise, kept short because `displayTitle` is 28pt heavy.
    static let title = "Keep the game moving."

    /// What the purchase gives a player, in a sentence.
    static let explanation =
        "One payment gives your game nights a permanent home for every score to come."

    /// What the payment gives. Three lines, each of them true.
    static let benefits = [
        "Start as many games as you like",
        "Pay once, keep it for good",
        "Receive any new features for free"
    ]

    /// The primary action. Carries StoreKit's own price string, which is why
    /// this is a function rather than a constant.
    ///
    /// Falls back to the bare word when StoreKit has not answered yet — offline
    /// at launch, most likely. The button stays live, because the purchase
    /// itself asks for the product again and has something to say if it still
    /// cannot reach it; a dead button with no explanation would be worse than
    /// an honest failure a tap later.
    static func buy(price: String?) -> String {
        guard let price else { return "Unlock Sıra" }
        return "Unlock Sıra for \(price)"
    }

    /// While Apple has the purchase. The label changes rather than vanishing,
    /// so the button that was tapped is visibly the thing that is happening.
    static let buyInFlight = "Just a moment…"

    /// The app's only Restore affordance — a real control, on the one sheet
    /// that is guaranteed to be reachable.
    static let restore = "Restore purchase"

    /// The promo code affordance. A question rather than a label, because it
    /// is addressed only to the player who already has one — anybody else
    /// reads it, finds it is not about them, and moves on.
    ///
    /// It does not say "enter" or "redeem" anything, because nothing is
    /// entered here: the tap hands over to the App Store's own redemption
    /// sheet, which is the only place a promo code for the Unlock can be
    /// typed. Sıra never sees a code and never checks one (`UnlockStore
    /// .redeemCode`).
    static let redeemCode = "Have a promo code?"

    /// The way out. One tap, and Home is where it was.
    static let dismiss = "Not now"

    /// A purchase that did not complete. Says the thing the player is actually
    /// worried about first: no money moved.
    static let purchaseFailed =
        "That didn't go through, and you haven't been charged. You can try again."

    /// Restore reaching Apple and finding nothing — an answer, not an error, so
    /// it says what to do about it.
    static let nothingToRestore =
        "No purchase found on this Apple Account. If you bought Sıra with a "
        + "different one, sign in with that account and try again."

    /// Restore that could not reach Apple at all.
    static let restoreFailed =
        "Sıra couldn't reach the App Store, and you haven't been charged. "
        + "You can try again."

    /// Ask to Buy: the request is with somebody else now, and the app will
    /// unlock on its own when they approve it.
    static let awaitingApproval =
        "Your request has been sent for approval. Sıra unlocks by itself once "
        + "it's approved."
}
