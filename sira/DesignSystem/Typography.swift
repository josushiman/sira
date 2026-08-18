import SwiftUI

/// Font family names as registered from the bundled font files
/// (`sira/Resources/Fonts/`, `docs/adr/0001-bundle-brand-fonts.md`).
///
/// Bricolage Grotesque ships as a single variable font. Its default named
/// instance's PostScript name is used to look it up; `.fontWeight()` then
/// interpolates the `wght` axis, giving every weight in 400/500/600/800
/// without needing separate static files.
enum FontFamily {
    static let display = "BricolageGrotesque-96ptExtraBold"
    static let mono = "IBM Plex Mono"
}

/// A semantic text role from the prototype's typography, mapped onto a
/// Dynamic Type-scalable SwiftUI font. Sizes here approximate the
/// prototype's visual hierarchy rather than copying its literal pixel
/// values (`docs/adr/0003-native-navigation-and-type-scaling-over-literal-port.md`).
enum SiraTextRole {
    // Bricolage Grotesque (display)
    /// Home's "Keep the score honest." hero headline.
    case displayHero
    /// Screen titles: "Which variant?", "Who's playing?".
    case displayTitle
    /// Card/row titles: Game names, Variant labels, Entrant names.
    case headline
    /// Secondary emphasis text: buttons, input text.
    case subheadline
    /// Paragraph body text: rule text, hints, descriptions.
    case body
    /// Small supporting text: empty states, notes.
    case caption

    // IBM Plex Mono
    /// Uppercase tracked section eyebrows: "YOUR GAMES", "ROUND 3".
    case monoEyebrow
    /// Meta/numeric line text: deltas, sub-labels.
    case monoLabel
    /// Emphasized numeric values: scores, tile numbers.
    case monoValue
    /// The largest numeric emphasis: standings score.
    case monoValueLarge
    /// Small uppercase tracked pill/tag text: LEADS, OUT, FINISHED.
    case monoTag
}

private struct RoleMetrics {
    let family: String
    let size: CGFloat
    let relativeTo: Font.TextStyle
    let weight: Font.Weight
    let tracking: CGFloat?
    let uppercase: Bool

    init(
        family: String,
        size: CGFloat,
        relativeTo: Font.TextStyle,
        weight: Font.Weight,
        tracking: CGFloat? = nil,
        uppercase: Bool = false
    ) {
        self.family = family
        self.size = size
        self.relativeTo = relativeTo
        self.weight = weight
        self.tracking = tracking
        self.uppercase = uppercase
    }
}

private extension SiraTextRole {
    var metrics: RoleMetrics {
        switch self {
        case .displayHero:
            RoleMetrics(family: FontFamily.display, size: 34, relativeTo: .largeTitle, weight: .heavy)
        case .displayTitle:
            RoleMetrics(family: FontFamily.display, size: 28, relativeTo: .title, weight: .heavy)
        case .headline:
            RoleMetrics(family: FontFamily.display, size: 19, relativeTo: .title3, weight: .semibold)
        case .subheadline:
            RoleMetrics(family: FontFamily.display, size: 16, relativeTo: .headline, weight: .medium)
        case .body:
            RoleMetrics(family: FontFamily.display, size: 15, relativeTo: .body, weight: .regular)
        case .caption:
            RoleMetrics(family: FontFamily.display, size: 13, relativeTo: .footnote, weight: .regular)
        case .monoEyebrow:
            RoleMetrics(family: FontFamily.mono, size: 10, relativeTo: .caption2, weight: .medium, tracking: 1.6, uppercase: true)
        case .monoLabel:
            RoleMetrics(family: FontFamily.mono, size: 11, relativeTo: .caption, weight: .regular)
        case .monoValue:
            RoleMetrics(family: FontFamily.mono, size: 17, relativeTo: .title3, weight: .semibold)
        case .monoValueLarge:
            RoleMetrics(family: FontFamily.mono, size: 23, relativeTo: .title2, weight: .semibold)
        case .monoTag:
            RoleMetrics(family: FontFamily.mono, size: 9, relativeTo: .caption2, weight: .semibold, tracking: 1.1, uppercase: true)
        }
    }
}

extension Font {
    /// The scalable SwiftUI font for a prototype text role.
    static func sira(_ role: SiraTextRole) -> Font {
        let m = role.metrics
        return .custom(m.family, size: m.size, relativeTo: m.relativeTo).weight(m.weight)
    }
}

extension Text {
    /// Builds text styled for a prototype text role, string content included
    /// — needed so uppercase-transformed roles (`monoEyebrow`, `monoTag`) can
    /// uppercase the string directly (`Text.textCase` isn't available on
    /// `Text`, only on `View`).
    init(sira role: SiraTextRole, _ content: String) {
        let m = role.metrics
        self = Text(m.uppercase ? content.uppercased() : content).siraStyle(role)
    }

    /// Applies a prototype text role's font and tracking to existing Text.
    /// Does not apply uppercase transformation — use `Text(sira:_:)` for
    /// roles that need it.
    func siraStyle(_ role: SiraTextRole) -> Text {
        let m = role.metrics
        var text = font(.sira(role))
        if let tracking = m.tracking {
            text = text.tracking(tracking)
        }
        return text
    }
}
