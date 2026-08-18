import Foundation

struct Variant: Identifiable, Hashable {
    let id: String
    let game: Game
    let label: String
    let ruleText: String
    let winCondition: WinCondition
    /// Survival: the score an Entrant must stay at or under before going Out.
    let limit: Int?
    /// Elimination: the score Entrants count down from.
    let startingScore: Int?
    /// Fixed Rounds: the number of Rounds the Match runs for.
    let roundCount: Int?
    let teamsOnly: Bool
}

extension Variant {
    static let gonga101 = Variant(
        id: "gonga-101",
        game: .gonga,
        label: "Gonga 101",
        ruleText: "Accumulate points each Round. Go over 101 and you're Out. Last one standing wins.",
        winCondition: .survival,
        limit: 101,
        startingScore: nil,
        roundCount: nil,
        teamsOnly: false
    )
}
