import Foundation

/// A name about to be given to an Entrant — typed into the rename sheet, or
/// left blank there — together with everything needed to judge it: the seat it
/// is for, the Match's Entrant mode, and which Entrant is being renamed.
///
/// A value with no Match, store or view behind it, so the rule can be tested
/// exhaustively without building either. `resolved(against:)` is the whole of
/// it: hand it the Entrants already in the Match and it answers with the name
/// to store, or with the name it clashed against.
struct EntrantName {
    /// What the player typed, exactly as typed. Trimming is the resolver's
    /// business, so a field can hand over its contents mid-edit without
    /// deciding anything.
    let text: String
    /// The seat this name is for, which decides the fallback an empty field
    /// materialises. A seat rather than a position in a list: seats are unique
    /// and never renumbered, so two Entrants who both leave the field blank
    /// cannot land on the same fallback.
    let seat: Int
    /// Whether this Match is played by players or teams — the noun the
    /// fallback is built from.
    let mode: EntrantMode
    /// The Entrant being renamed, excluded from the duplicate check so that
    /// re-saving someone under the name they already hold is a no-op rather
    /// than a clash with themselves. `nil` when the name is for an Entrant who
    /// is not in the Match yet.
    let renaming: Entrant.ID?

    init(_ text: String, seat: Int, mode: EntrantMode, renaming: Entrant.ID? = nil) {
        self.text = text
        self.seat = seat
        self.mode = mode
        self.renaming = renaming
    }

    /// What the Match makes of this name, given the Entrants it already holds.
    ///
    /// `existing` is the Match's Entrants including the one being renamed —
    /// callers hand over the roster they have rather than pre-filtering it,
    /// and `renaming` is what decides who is exempt.
    ///
    /// Judges the candidate alone and never sweeps the roster: a Match started
    /// before this rule can hold two Alis, and it stays openable and scorable
    /// until one of them is edited.
    func resolved(against existing: [Entrant]) -> Resolution {
        let name = trimmed.isEmpty ? fallback : trimmed
        let folded = Self.folded(name)
        let clash = existing.first { entrant in
            entrant.id != renaming && Self.folded(entrant.name) == folded
        }
        guard let clash else { return .accepted(name) }
        return .duplicate(clash.name)
    }

    /// The name an empty field materialises — `Player 3`, `Team 2`. Baked into
    /// the Entrant rather than resolved at display time, which is why it is
    /// not exempt from the duplicate check: after creation nothing tells it
    /// from the same name typed by hand.
    var fallback: String { "\(mode.entrantNoun.capitalized) \(seat + 1)" }

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Two names are the same name when they fold to the same string: trimmed,
    /// and lowercased under a **pinned Turkish locale**.
    ///
    /// Pinned rather than inherited from the device, because the default
    /// folding maps `I` to `i` and Turkish maps it to `ı`. Left to
    /// `Locale.current`, `ALI` and `Ali` would be one name on an English phone
    /// and two on a Turkish one — and the pair a Turkish speaker is actually
    /// typing is the second. Whose phone it is has nothing to do with which
    /// names the table can tell apart.
    private static func folded(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(with: comparisonLocale)
    }

    private static let comparisonLocale = Locale(identifier: "tr_TR")
}

extension EntrantName {
    /// What the Match made of the name: the one to store, or the one it
    /// clashed against.
    enum Resolution: Equatable {
        /// Store this. Trimmed, or the seat's fallback where the field was
        /// left empty.
        case accepted(String)
        /// Refused, carrying the name **as another Entrant already holds it**
        /// rather than as it was just typed — that is the one on screen for
        /// the player to go and look at.
        case duplicate(String)

        /// The name to store, or `nil` where there isn't one. What a Save
        /// button is enabled by, and what it saves.
        var name: String? {
            switch self {
            case .accepted(let name): return name
            case .duplicate: return nil
            }
        }

        /// Why this name cannot be saved, in a sentence, or `nil` when it can
        /// — read back beside the field the way `VariantParameter`'s
        /// `unstartableReason` reads back beside Setup's Start button.
        var rejection: String? {
            switch self {
            case .accepted: return nil
            case .duplicate(let name): return "\(name) is already in this Match. Pick another name."
            }
        }
    }
}
