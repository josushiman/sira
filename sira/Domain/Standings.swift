import Foundation

struct EntrantStanding: Identifiable, Equatable {
    let entrantID: Entrant.ID
    var name: String
    var total: Int
    var isOut: Bool
    var deltaFromLastRound: Int

    var id: Entrant.ID { entrantID }
}

struct Standings: Equatable {
    var ranked: [EntrantStanding]
    var isOver: Bool
    var result: String?

    /// Whether the Match these Standings describe still accepts changes to its
    /// roster — a rename now, an Add later. True while the Match is being
    /// played, false once its Win Condition has decided it: a settled result
    /// is not something to reopen.
    ///
    /// Being **Archived** has no say in it. That is a visibility flag and
    /// nothing more — an Archived Match still takes Rounds — so refusing it a
    /// rename would be an inconsistency with nothing behind it. Neither has
    /// being **Out**: a name typed wrong is worth fixing for an Entrant who
    /// has stopped accumulating score.
    ///
    /// Here rather than on the screen that acts on it, so that the two
    /// controls the rule governs cannot come to disagree about when a Match is
    /// still live, and so the rule can be asserted without a view.
    var acceptsRosterEdits: Bool { !isOver }
}
