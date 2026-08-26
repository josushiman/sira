import XCTest
import SwiftUI
@testable import sira

/// Every text-on-background pair the offer sheet draws, in both themes,
/// measured against WCAG AA.
///
/// A snapshot proves the sheet was laid out; it cannot prove it can be read.
/// This is the sheet that asks for money, so what it is legible against is
/// asserted rather than eyeballed — and asserted in both themes, because
/// `accent` is gold in Felt and dark green in Paper with `onAccent` flipping to
/// match. A design that leaned on the gold would fail here the moment it was
/// recoloured, which is the point: Paper is designed rather than recoloured.
final class UnlockSheetContrastTests: XCTestCase {
    /// AA for body text. The sheet's own lines are all body-sized or smaller.
    private let bodyMinimum = 4.5
    /// AA for large text — 18pt bold and up. The title and the filled button's
    /// label are the only two that qualify, and both clear the body threshold
    /// anyway; this is here so the intent of each assertion is stated rather
    /// than implied.
    private let largeMinimum = 3.0

    func test_everyTextPairOnTheSheetClearsWCAGAA() {
        for theme in [Theme.paper, Theme.felt] {
            // The title, and the sentence under it.
            assertContrast(theme.ink, on: theme.background, atLeast: largeMinimum, theme, "title")
            assertContrast(theme.ink.opacity(0.7), on: theme.background, atLeast: bodyMinimum, theme, "explanation")
            // The benefit lines, which sit on a card rather than on the sheet.
            // Measured against the card's own fill, composited: `track` is ink
            // at 0.06, which darkens Paper's background and lightens Felt's,
            // and a ratio taken against the sheet behind it would be a ratio
            // for a surface the words are not on.
            let card = composite(theme.track, over: theme.background)
            assertContrast(theme.ink.opacity(0.75), on: card, atLeast: bodyMinimum, theme, "benefit")
            // The inline message — a failure, or Restore finding nothing.
            assertContrast(theme.ink.opacity(0.9), on: theme.background, atLeast: bodyMinimum, theme, "message")
            // The Buy button, which is the accent filled with its own on-colour.
            assertContrast(theme.onAccent, on: theme.accent, atLeast: largeMinimum, theme, "buy button")
            // Restore and Not now, which are outlined rather than filled.
            assertContrast(theme.ink.opacity(0.75), on: theme.background, atLeast: bodyMinimum, theme, "outlined button")
            // The promo code link. Caption-sized, so it is held to the body
            // threshold rather than the large one — the quietest line on the
            // sheet is still one a player has to be able to read.
            assertContrast(theme.ink.opacity(0.7), on: theme.background, atLeast: bodyMinimum, theme, "promo code link")
        }
    }

    /// The benefit bullet, which is decoration beside a line that carries the
    /// meaning — so it is held to the non-text threshold rather than a text
    /// one, and is here because "it's decorative" should be a decision on the
    /// record rather than an omission.
    func test_theSheetsNonTextMarkersClearTheNonTextThreshold() {
        for theme in [Theme.paper, Theme.felt] {
            assertContrast(
                theme.accent,
                on: composite(theme.track, over: theme.background),
                atLeast: 3.0,
                theme,
                "benefit bullet"
            )
            // The bar beside the inline message, which is where the warning
            // colour went once it turned out not to be legible as text on
            // Paper — see `UnlockSheet.noteLine(_:)`.
            assertContrast(theme.accent2, on: theme.background, atLeast: 3.0, theme, "message bar")
        }
    }

    private func assertContrast(
        _ foreground: Color,
        on background: Color,
        atLeast minimum: Double,
        _ theme: Theme,
        _ label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let ratio = contrastRatio(of: foreground, on: background)
        XCTAssertGreaterThanOrEqual(
            ratio,
            minimum,
            "\(theme.name): \(label) is \(String(format: "%.2f", ratio)):1, short of \(minimum):1",
            file: file,
            line: line
        )
    }

    /// WCAG's own formula, on the colour as it actually lands on screen:
    /// a translucent ink is composited over the background first, because that
    /// is what the eye is given and a ratio taken before compositing would
    /// flatter every muted line on the sheet.
    private func contrastRatio(of foreground: Color, on background: Color) -> Double {
        let back = components(of: background)
        let front = components(of: foreground)
        let composited = (0..<3).map { front.rgb[$0] * front.alpha + back.rgb[$0] * (1 - front.alpha) }
        let lighter = max(luminance(composited), luminance(back.rgb))
        let darker = min(luminance(composited), luminance(back.rgb))
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// A translucent colour laid over an opaque one, as an opaque colour —
    /// what the eye is actually given where a card sits on the sheet, and the
    /// background the words on that card have to be legible against.
    private func composite(_ overlay: Color, over base: Color) -> Color {
        let back = components(of: base)
        let front = components(of: overlay)
        let mixed = (0..<3).map { front.rgb[$0] * front.alpha + back.rgb[$0] * (1 - front.alpha) }
        return Color(red: mixed[0], green: mixed[1], blue: mixed[2])
    }

    private func components(of color: Color) -> (rgb: [Double], alpha: Double) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return ([Double(red), Double(green), Double(blue)], Double(alpha))
    }

    private func luminance(_ rgb: [Double]) -> Double {
        let linear = rgb.map { channel in
            channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
    }
}
