import SwiftUI

/// The offer, raised over a dimmed Home when a player with no free games left
/// taps Gonga or Okey.
///
/// The app's own bottom-sheet idiom — `DecisionSheet` and `SheetButton`, the
/// same surface the Rejoin offer and the delete confirmation compose — rather
/// than anything new. A paywall is not the screen to introduce a shape the app
/// has never used.
///
/// Takes values and hands back taps, exactly as `RejoinSheet` does. Nothing in
/// here knows what a `UnlockStore` is, which is what lets every one of its
/// states be snapshot without a purchase anywhere near them.
struct UnlockSheet: View {
    /// StoreKit's price for this player's storefront, or `nil` if it has not
    /// answered yet. The app has no price of its own to fall back on.
    let displayPrice: String?
    let status: UnlockStore.Status
    let onBuy: () -> Void
    let onRestore: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    var body: some View {
        DecisionSheet(title: UnlockCopy.title, explanation: UnlockCopy.explanation) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(UnlockCopy.benefits, id: \.self) { benefit in
                    benefitCard(benefit)
                }
                if let note {
                    noteLine(note)
                }
            }
            .padding(.top, 14)
        } actions: {
            SheetButton(
                title: isInFlight ? UnlockCopy.buyInFlight : UnlockCopy.buy(price: displayPrice),
                // The theme's accent, whatever the theme has made of it: gold
                // on Felt, dark green on Paper, with `onAccent` flipping to
                // match. The one pairing that is legible in both without a
                // colour being chosen here.
                emphasis: .filled(background: theme.accent, foreground: theme.onAccent),
                action: onBuy
            )
            // The two ways that are not buying, side by side under the one
            // that is: neither of them is the sheet's question, and stacking
            // three full-width buttons gave the last two the same weight as
            // the first. Out on the left, Restore on the right — the order a
            // thumb reaching for the way out expects.
            //
            // Outlined rather than plain text, and full height: this is the
            // app's only Restore affordance, and one the App Store requires to
            // be findable. A caption-sized link under the fold fails that.
            HStack(spacing: 9) {
                SheetButton(title: UnlockCopy.dismiss, emphasis: .outlined) { dismiss() }
                SheetButton(title: UnlockCopy.restore, emphasis: .outlined, action: onRestore)
            }
        }
        // While Apple has the purchase, the app's own controls come out of
        // reach — Apple draws the payment sheet over this one, and a live Buy
        // button underneath it is a second purchase waiting to be started. The
        // sheet stays up and stays readable; it just stops taking taps.
        .disabled(isInFlight)
        .opacity(isInFlight ? 0.6 : 1)
    }

    private var isInFlight: Bool { status == .inFlight }

    /// The inline message, if there is one to show. Inline rather than an alert
    /// so that the sheet stays where it is and trying again is one tap — a
    /// dialog over a sheet is two dismissals and a lost train of thought.
    private var note: String? {
        switch status {
        case .ready, .inFlight: return nil
        case let .purchaseFailed(message): return message
        case .nothingToRestore: return UnlockCopy.nothingToRestore
        case .awaitingApproval: return UnlockCopy.awaitingApproval
        }
    }

    /// The inline message: a failure, or Restore finding nothing.
    ///
    /// The text is ink rather than the warning colour, and the warning colour
    /// is a bar beside it. `accent2` on Paper's background comes to 4.20:1,
    /// which is under WCAG AA for text and comfortably over the 3:1 a
    /// non-text element is held to — so the colour marks the line and the ink
    /// carries the words. This message is what a player reads to find out
    /// whether they have been charged; it is not the place to trade legibility
    /// for a tint.
    private func noteLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(theme.accent2)
                .frame(width: 3)
            Text(text)
                .siraStyle(.caption)
                .foregroundStyle(theme.ink.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 6)
    }

    /// One benefit, on a card of its own.
    ///
    /// A card rather than a bullet because these are the three things the
    /// payment buys, and a run of dotted lines under an explanation reads as a
    /// footnote to it. Each one on its own surface makes them the list they
    /// are — and gives a two-line benefit somewhere to be without the second
    /// line looking like a fourth item.
    ///
    /// `track` for the fill: ink at 0.06, so the card sits a shade off the
    /// sheet in both themes without a colour of its own being invented here.
    private func benefitCard(_ text: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(theme.accent)
                .frame(width: 7, height: 7)
            Text(text)
                .siraStyle(.body)
                .foregroundStyle(theme.ink.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.track, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview("UnlockSheet") {
    // Deliberately neither the real price nor a plausible one: what the app
    // charges is App Store Connect's to say and StoreKit's to render, and a
    // price written down in here — even in a preview — is the first half of it
    // being written down somewhere that ships. Long, too, because a currency
    // whose string runs to a dozen characters is the layout worth looking at.
    let samplePrice = "1.234,56 TL"
    return VStack(spacing: 0) {
        ForEach([Theme.paper, Theme.felt], id: \.name) { theme in
            UnlockSheet(displayPrice: samplePrice, status: .ready, onBuy: {}, onRestore: {})
                .environment(\.theme, theme)
        }
    }
}
