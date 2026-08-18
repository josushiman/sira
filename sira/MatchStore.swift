import SwiftUI

/// The in-memory list of every Match, shared by the Home list, Setup, and Play
/// screens so a Round added in Play is immediately visible in Home's summary
/// line and filter. Persistence is out of scope for this spec.
@Observable
final class MatchStore {
    var matches: [Match]

    init(matches: [Match] = []) {
        self.matches = matches
    }

    func add(_ match: Match) {
        matches.append(match)
    }

    /// A two-way Binding to the Match with `id`, so Play can mutate it in
    /// place. Matches are only ever appended or edited in this store, never
    /// removed, so the id is guaranteed to be present for any id this store
    /// itself has handed out.
    func binding(for id: Match.ID) -> Binding<Match> {
        guard let index = matches.firstIndex(where: { $0.id == id }) else {
            fatalError("No Match with id \(id) in the store")
        }
        return Binding(
            get: { self.matches[index] },
            set: { self.matches[index] = $0 }
        )
    }
}

extension MatchStore {
    static func seeded() -> MatchStore {
        let alice = Entrant(name: "Alice")
        let bob = Entrant(name: "Bob")
        let carol = Entrant(name: "Carol")

        let inProgress = Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [alice, bob],
            rounds: [Round(deltas: [alice.id: 20, bob.id: 15])]
        )

        let finished = Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [alice, carol],
            rounds: [Round(deltas: [alice.id: 110, carol.id: 40])],
            archived: true
        )

        return MatchStore(matches: [inProgress, finished])
    }
}
