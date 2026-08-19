import Foundation

enum Game: String, Hashable, CaseIterable {
    case gonga
    case okey

    /// What this Game's table calls finishing the Round by discarding the
    /// joker — Okey's tile vocabulary, or the card word Gonga players use.
    /// The concept is Okey atmak either way; only the label differs.
    var okeyAtmakLabel: String {
        switch self {
        case .gonga: return "Jokeri att\u{131}"
        case .okey: return "Okey att\u{131}"
        }
    }
}
