import Foundation
import SwiftData

/// The one place a Match is created, changed or removed.
///
/// Every mutation in the app goes through here rather than being performed on a
/// Match by whichever screen happens to hold it, so that the mutation and what
/// has to accompany it — deleting an undone Round now, saving in ticket 06 —
/// stay in one place and no screen can perform half the pair.
///
/// Reading is not the store's job: Home reads Matches with `@Query`, which is
/// the framework's own mechanism and does it better than a hand-maintained
/// array.
///
/// The container is in memory for now, so the app behaves exactly as it did
/// before — seeded at launch, losing everything on quit. Durability on disk is
/// ticket 06.
@Observable
final class MatchStore {
    let container: ModelContainer

    /// The context every mutation runs against — the container's own main
    /// context, which is also the one `@Query` reads from, so a Round added in
    /// Play is visible in Home's summary line without anything being told to
    /// refresh.
    var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
    }

    /// A store over a fresh in-memory container.
    ///
    /// Fails loudly: a container that cannot be built in memory is a broken
    /// schema, which is a programmer error rather than the corrupt-file case
    /// ticket 07 handles.
    convenience init() {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(
                for: Schema(SiraSchema.models),
                migrationPlan: SiraMigrationPlan.self,
                configurations: configuration
            )
            self.init(container: container)
        } catch {
            fatalError("Could not build an in-memory Match store: \(error)")
        }
    }

    func add(_ match: Match) {
        context.insert(match)
    }

    /// Adds `round` as the Match's latest. The Round is inserted alongside so
    /// that it is a stored object in its own right rather than reachable only
    /// through the Match that happens to hold it.
    func addRound(_ round: Round, to match: Match) {
        context.insert(round)
        match.addRound(round)
    }

    func recordRejoin(_ rejoin: RejoinEvent, in match: Match) {
        match.recordRejoin(rejoin)
    }

    /// Removes the Match's most recent Round and deletes it.
    ///
    /// Both halves matter: dropping the Round from the relationship is what
    /// reverses the score, and deleting it is what stops the Round outliving
    /// the Match's memory of it as an orphan.
    func undoLastRound(in match: Match) {
        guard let undone = match.undoLastRound() else { return }
        context.delete(undone)
    }

    func archive(_ match: Match) {
        match.archive()
    }

    func restore(_ match: Match) {
        match.restore()
    }
}

extension MatchStore {
    /// A store holding the two fixture Matches.
    ///
    /// Previews and view tests only — the app opens on whatever the player has
    /// actually created, which before ticket 06 means an empty Home on every
    /// launch.
    static func seeded() -> MatchStore {
        let store = MatchStore()

        // Each Match builds its own Alice. An Entrant belongs to exactly one
        // Match (`docs/adr/0007`), so handing the same one to both would move
        // her out of the first rather than have her play in two.
        let alice = Entrant(name: "Alice")
        let bob = Entrant(name: "Bob")

        // Fixed creation dates: Home titles each card with its Match's date and
        // orders the list by it, so seeded Matches can't use "now" without
        // making previews and snapshot tests change from one day to the next.
        store.add(Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [alice, bob],
            rounds: [Round(deltas: [alice.id: 20, bob.id: 15])],
            createdAt: .fixture(year: 2026, month: 3, day: 14, hour: 21)
        ))

        let aliceAgain = Entrant(name: "Alice")
        let carol = Entrant(name: "Carol")

        store.add(Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [aliceAgain, carol],
            rounds: [Round(deltas: [aliceAgain.id: 110, carol.id: 40])],
            archived: true,
            createdAt: .fixture(year: 2026, month: 2, day: 2, hour: 19, minute: 45)
        ))

        return store
    }
}

extension Date {
    /// A fixed calendar date and time, for seeded/preview Matches that must
    /// look the same on every run. Built in the current time zone so the
    /// rendered clock time is the one asked for wherever the tests run.
    static func fixture(year: Int, month: Int, day: Int, hour: Int = 12, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = .current
        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }
}
