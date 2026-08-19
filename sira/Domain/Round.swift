import Foundation

struct RejoinEvent: Hashable {
    let id: Entrant.ID
    let to: Int
}

struct Round: Identifiable, Hashable {
    let id: UUID
    /// Per-Entrant deltas for the keypad entry styles (Survival, Fixed Rounds),
    /// stored **raw** — exactly the counts the player entered, never scaled by
    /// Çifte or any other Round modifier. The Engines are the only place a
    /// multiplier is applied (`docs/adr/0005`). Unused by Elimination Rounds,
    /// which are described instead by `losingEntrantID` and `gostergeFinds`.
    var deltas: [Entrant.ID: Int]
    var rejoins: [RejoinEvent]
    /// Çifte: doubles this Round's deltas as each Engine applies them (every
    /// delta for Survival/Fixed Rounds, only the penalty for Elimination).
    var cifte: Bool
    /// Elimination only: the Entrant that lost this Round, taking the −2 penalty.
    var losingEntrantID: Entrant.ID?
    /// Elimination only: Gösterge finds per Entrant this Round, capped at 1 each.
    var gostergeFinds: [Entrant.ID: Int]

    init(
        id: UUID = UUID(),
        deltas: [Entrant.ID: Int] = [:],
        rejoins: [RejoinEvent] = [],
        cifte: Bool = false,
        losingEntrantID: Entrant.ID? = nil,
        gostergeFinds: [Entrant.ID: Int] = [:]
    ) {
        self.id = id
        self.deltas = deltas
        self.rejoins = rejoins
        self.cifte = cifte
        self.losingEntrantID = losingEntrantID
        self.gostergeFinds = gostergeFinds
    }
}
