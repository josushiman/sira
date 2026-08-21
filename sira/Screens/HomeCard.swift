import Foundation

/// A Match as Home's list draws it: every line of the card read off the Match
/// when Home's body runs, and held as plain values from then on.
///
/// Values rather than the Match itself, for the reason `PendingDeletion` holds
/// values: a card that keeps the Match is a card that reads it again whenever
/// SwiftUI redraws the row, and one of the moments SwiftUI redraws a row is
/// just after the Match behind it was deleted. Reading any property of a
/// deleted model traps — SwiftData has no backing data left to answer with —
/// so the card that outlives its Match by a frame took the app down with it.
///
/// Nothing is lost by holding values. A card is rebuilt whenever Home's body
/// runs, and Home's body reads the same properties this init does, so a Round
/// added in Play still reaches the list: the observation that used to sit in
/// the card now sits one view up.
struct HomeCard: Identifiable {
    let id: Match.ID
    let game: Game
    /// The Match named as its card names it — the date it was started.
    let title: String
    /// Where the Match is up to: "Finished", "Archived", or the Round it is on.
    let statusText: String
    /// Archived-but-unfinished is the one status that reads muted rather than
    /// as the accent-coloured "where the Match is up to" pill.
    let statusIsMuted: Bool
    let entrantsText: String
    let variantLabel: String
    /// The leader/result line under the card's divider.
    let summaryText: String
    let archived: Bool
    /// What the delete confirmation counts when it says what goes.
    let roundCount: Int

    init(match: Match, variant: Variant) {
        let engine = variant.winCondition.engine
        let standings = engine.standings(for: match)
        let entrantCount = match.entrants.count

        id = match.id
        game = match.game
        title = MatchDateTitle.text(for: match.createdAt)
        archived = match.archived
        roundCount = match.rounds.count
        variantLabel = variant.label
        summaryText = MatchSummary(match: match, engine: engine).text

        if standings.isOver {
            statusText = "Finished"
        } else if match.archived {
            statusText = "Archived"
        } else {
            statusText = "Round \(match.rounds.count + 1)"
        }
        statusIsMuted = match.archived && !standings.isOver

        switch match.mode {
        case .players:
            entrantsText = "\(entrantCount) \(entrantCount == 1 ? "player" : "players")"
        case .teams:
            entrantsText = "\(entrantCount) \(entrantCount == 1 ? "team" : "teams")"
        }
    }
}
