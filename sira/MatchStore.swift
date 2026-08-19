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

        // Fixed creation dates: Home titles each card with its Match's date and
        // orders the list by it, so seeded Matches can't use "now" without
        // making previews and snapshot tests change from one day to the next.
        let inProgress = Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [alice, bob],
            rounds: [Round(deltas: [alice.id: 20, bob.id: 15])],
            createdAt: .fixture(year: 2026, month: 3, day: 14)
        )

        let finished = Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [alice, carol],
            rounds: [Round(deltas: [alice.id: 110, carol.id: 40])],
            archived: true,
            createdAt: .fixture(year: 2026, month: 2, day: 2)
        )

        return MatchStore(matches: [inProgress, finished])
    }
}

extension Date {
    /// A fixed calendar date in UTC, for seeded/preview Matches that must look
    /// the same on every run.
    static func fixture(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        components.timeZone = TimeZone(secondsFromGMT: 0)
        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }
}
