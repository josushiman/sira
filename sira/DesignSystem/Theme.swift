import SwiftUI

/// One of the prototype's two color-token sets — "Paper" (`THEMES.pad`) or
/// "Felt" (`THEMES.felt`) from the Claude Design source. Resolved from the
/// system color scheme only; there is no persisted preference or picker.
/// Night and Clay are intentionally not implemented (`docs/adr/0002`).
struct Theme: Equatable {
    let name: String
    let background: Color
    let surface: Color
    let ink: Color
    let line: Color
    let track: Color
    let accent: Color
    let accent2: Color
    let onAccent: Color
    let tile: Color
    let tileInk: Color
    let cardFace: Color
    let cardBack: Color
    let pip: Color
    /// Rotating palette used to color dot badges by Entrant/Match index.
    /// Eight entries so a full Gonga table (up to 8 players) never has two
    /// Entrants sharing a badge color.
    let dots: [Color]

    /// The Entrant/Match-index-th color from the rotating dot palette.
    func dot(_ index: Int) -> Color {
        dots[index % dots.count]
    }
}

extension Theme {
    /// `THEMES.pad` — used when the system is in light mode.
    static let paper = Theme(
        name: "Paper",
        background: Color(hex: 0xF2EDE1),
        surface: Color(hex: 0xFBF8F0),
        ink: Color(hex: 0x1A1815),
        line: Color(hex: 0x1A1815).opacity(0.11),
        track: Color(hex: 0x1A1815).opacity(0.06),
        accent: Color(hex: 0x1F5F46),
        accent2: Color(hex: 0xB4552F),
        onAccent: Color(hex: 0xFBF8F0),
        tile: Color(hex: 0xEFE4C9),
        tileInk: Color(hex: 0x1A1815),
        cardFace: Color(hex: 0xFBF8F0),
        cardBack: Color(hex: 0xE6DECB),
        pip: Color(hex: 0xB4552F),
        dots: [0x1F5F46, 0xB4552F, 0x3C5A82, 0x6E5385, 0x726B2E, 0x9B4A62, 0x2F7F7A, 0x8A5A2B].map(Color.init(hex:))
    )

    /// `THEMES.felt` — used when the system is in dark mode.
    static let felt = Theme(
        name: "Felt",
        background: Color(hex: 0x123A2C),
        surface: Color(hex: 0x174937),
        ink: Color(hex: 0xF1EEE2),
        line: Color(hex: 0xF1EEE2).opacity(0.14),
        track: Color(hex: 0xF1EEE2).opacity(0.09),
        accent: Color(hex: 0xE4C46A),
        accent2: Color(hex: 0xE0906A),
        onAccent: Color(hex: 0x123A2C),
        tile: Color(hex: 0xEFE4C9),
        tileInk: Color(hex: 0x123A2C),
        cardFace: Color(hex: 0xF1EEE2),
        cardBack: Color(hex: 0x0D2E23),
        pip: Color(hex: 0xC2452F),
        dots: [0xE4C46A, 0xE0906A, 0x8FC2A4, 0xB9A6DC, 0x6FB0C4, 0xDE8896, 0x9FC96F, 0xD2B08C].map(Color.init(hex:))
    )

    /// Maps the system's color scheme onto Paper (light) or Felt (dark).
    static func resolved(for colorScheme: ColorScheme) -> Theme {
        switch colorScheme {
        case .dark: return .felt
        default: return .paper
        }
    }
}

private extension Color {
    nonisolated init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.paper
}

extension EnvironmentValues {
    /// The resolved Paper/Felt token set for the current color scheme.
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    /// Resolves `theme` from the environment's color scheme and injects it,
    /// so descendants can simply read `@Environment(\.theme)`.
    func themed() -> some View {
        modifier(ThemeResolverModifier())
    }
}

private struct ThemeResolverModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.environment(\.theme, Theme.resolved(for: colorScheme))
    }
}
