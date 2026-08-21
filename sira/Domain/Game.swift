import Foundation

/// One of the two games Sıra keeps score for. Stored on a Match, so its raw
/// values are part of the stored form and must stay stable — the same contract
/// `Variant.id` carries.
enum Game: String, Codable, Hashable, CaseIterable {
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
