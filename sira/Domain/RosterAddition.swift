import Foundation

/// The offer the Add row makes: a free seat at this Match's table, and the
/// total whoever takes it starts on.
///
/// A value derived at render time and never held, so the number in front of
/// the table moves as Rounds are scored and as Entrants go Out, with the sheet
/// still on screen. Cached when the screen opened, it would go stale exactly
/// when it matters — the table agrees the number out loud before anyone sits
/// down, and a number they can watch move is one they can trust.
///
/// `nil` — no offer, so no row at all rather than a row that is shown and
/// disabled — covers every way a Match has no seat to give away, and covers
/// them with one question each rather than a list of exceptions:
///
/// - **The table is full.** The Variant's maximum is how many people can play,
///   whether they sat down at Setup or halfway through.
/// - **The Match is decided.** A settled result is not something to reopen,
///   which is the Standings' own rule (`acceptsRosterEdits`) rather than a
///   second one stated here.
/// - **The Match cannot say what a newcomer would start on.** Only a Survival
///   Match is played to a running total someone can be brought in on; a Match
///   counting down, or one racing a fixed number of Rounds, has no highest
///   total still in to inherit. This is what keeps both Okey Variants out
///   without either being named — and, just as deliberately, without Gonga
///   being named either.
struct RosterAddition {
    /// The seat the joiner takes, which decides their dot-badge colour for the
    /// rest of the Match and the fallback name an empty field materialises.
    let seat: Int
    /// The total they enter on: the highest among Entrants **still in**.
    ///
    /// The Rejoin target, unchanged and not a parallel implementation of it —
    /// including its cap at the Match's limit and its fallback for the Round
    /// where everybody busts at once. A Rejoin and a join land an Entrant on a
    /// total by the same rule, and two spellings of one rule is one spelling
    /// too many.
    ///
    /// Entrants who are **Out** are excluded, because an Out Entrant typically
    /// holds the highest total on the table: inheriting it would start the
    /// newcomer beyond everyone actually playing, or past the limit and
    /// straight back Out.
    let total: Int

    init?(match: Match, variant: Variant, standings: Standings) {
        guard standings.acceptsRosterEdits,
              match.entrants.count < variant.maxEntrants,
              let engine = variant.winCondition.engine as? SurvivalEngine
        else { return nil }
        self.seat = match.nextSeat
        self.total = engine.rejoinTarget(for: match)
    }

    /// What the Add row reads under its label — the number for the table to
    /// agree out loud before anyone commits to it.
    var joinPhrase: String { "joins on \(total)" }
}
