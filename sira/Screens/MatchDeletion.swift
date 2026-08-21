import SwiftUI

/// A Match the player has asked to delete, read off the Match at the moment
/// they asked and held as plain values from then on.
///
/// Values rather than the Match itself, because confirming deletes the Match
/// while the sheet showing it is still coming down: a sheet holding the object
/// would be reading a deleted model to draw its last frame.
struct PendingDeletion: Identifiable {
    let id: Match.ID
    /// The Match named as its Home card names it.
    let title: String
    let roundCount: Int

    init(match: Match) {
        id = match.id
        title = MatchDateTitle.text(for: match.createdAt)
        roundCount = match.rounds.count
    }
}

/// What a press-and-hold on a Match card offers. Deletion only: Archive and
/// Restore keep the swipe they already have.
///
/// A view of its own rather than an inline menu body so that the items — their
/// wording, their order, and Delete's destructive role — can be snapshot like
/// any other surface. What the snapshot cannot show is the chrome around them,
/// which is the system's and is drawn in the system's colours whichever theme
/// the app is in.
struct MatchCardMenu: View {
    let onDelete: () -> Void

    var body: some View {
        Button(role: .destructive, action: onDelete) {
            Label("Delete Match", systemImage: "trash")
        }
    }
}

/// The confirmation between the menu item and the deletion.
///
/// A themed sheet rather than a system confirmation dialog, for the same
/// reason the Rejoin offer is one: this is a decision the app asks the player
/// to make, and it is drawn on the app's own surface, in whichever theme they
/// are in, rather than in system chrome that answers to neither.
struct DeleteMatchSheet: View {
    let deletion: PendingDeletion
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    var body: some View {
        DecisionSheet(title: "Delete this Match?", explanation: Self.explanation(for: deletion)) {
            SheetButton(
                title: "Delete Match",
                // The palette's one warning colour — the red of a Gonga pip in
                // Paper and of a tile's dot in Felt — so the destructive
                // action reads as destructive in both themes. White on it
                // rather than a theme ink, which is dark in one theme and
                // light in the other and legible on red in only one of them.
                emphasis: .filled(background: theme.pip, foreground: .white),
                action: onDelete
            )
            SheetButton(title: "Keep it", emphasis: .outlined) {
                dismiss()
            }
        }
    }

    /// What the player is agreeing to, in a sentence: which Match, everything
    /// that goes with it, and that there is no getting it back.
    ///
    /// This wording is the whole safeguard — the only thing standing between a
    /// mis-tap and an evening's scores — so it is a function that can be
    /// asserted rather than a string built inside a view body.
    static func explanation(for deletion: PendingDeletion) -> String {
        let subject: String
        switch deletion.roundCount {
        case 0: subject = "\(deletion.title) and its players"
        case 1: subject = "\(deletion.title), its players and the 1 Round played"
        default: subject = "\(deletion.title), its players and all \(deletion.roundCount) Rounds played"
        }
        return "\(subject) will be deleted for good. There is no undo."
    }
}
