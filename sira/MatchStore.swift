import Foundation
import SwiftData

/// The one place a Match is created, changed or removed — and, because every
/// mutation here is followed by an explicit save, the one place durability can
/// be reasoned about.
///
/// Every mutation in the app goes through here rather than being performed on a
/// Match by whichever screen happens to hold it, so that the mutation and the
/// save that has to accompany it stay in one place and no screen can perform
/// half the pair.
///
/// Saving is explicit rather than left to SwiftData's autosave, which stays on
/// as a backstop. A Match takes a handful of writes a minute, so there is
/// nothing to batch, and a Round written only when the framework next decides
/// to flush is a Round that looks saved in the simulator and is lost to a real
/// reclaim on a real device.
///
/// Reading is not the store's job: Home reads Matches with `@Query`, which is
/// the framework's own mechanism and does it better than a hand-maintained
/// array.
@Observable
final class MatchStore {
    let container: ModelContainer

    /// The most recent save that did not reach the disk, or `nil` when the
    /// last one did. The player is told about it — a tally that has silently
    /// stopped being recorded is the one failure this app cannot afford — and
    /// the change itself is left in memory, so play continues against the
    /// Standings on screen rather than against a Round that was thrown away.
    private(set) var saveFailure: SaveFailure?

    /// Writing the context out. Injected so tests can exercise the failure
    /// path: SwiftData offers no way to make a real save fail on demand, and
    /// what happens when the disk is full is the behaviour worth pinning down
    /// here.
    private let saveContext: (ModelContext) throws -> Void

    /// The context every mutation runs against — the container's own main
    /// context, which is also the one `@Query` reads from, so a Round added in
    /// Play is visible in Home's summary line without anything being told to
    /// refresh.
    var context: ModelContext { container.mainContext }

    init(
        container: ModelContainer,
        saveContext: @escaping (ModelContext) throws -> Void = { try $0.save() }
    ) {
        self.container = container
        self.saveContext = saveContext
        // Stated rather than inherited from the framework's default. Every
        // mutation here saves explicitly, so autosave is only ever a backstop —
        // but it is one this store means to have, and a default is not a
        // decision until someone writes it down.
        container.mainContext.autosaveEnabled = true
    }

    /// A store over a fresh in-memory container: previews, view tests, and any
    /// test that needs a database but not a disk.
    ///
    /// Fails loudly: a container that cannot be built in memory is a broken
    /// schema, which is a programmer error rather than the corrupt-file case
    /// ticket 07 handles.
    convenience init(saveContext: @escaping (ModelContext) throws -> Void = { try $0.save() }) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            self.init(container: try Self.container(for: configuration), saveContext: saveContext)
        } catch {
            fatalError("Could not build an in-memory Match store: \(error)")
        }
    }

    /// A store over the database at `url`, created there if there isn't one
    /// yet. This is what makes a Match outlive the app: everything written
    /// through the store is on the device, and a store built over the same url
    /// in a later launch reads it back.
    ///
    /// Throws rather than crashing when the store cannot be opened. Ticket 07
    /// turns that into recovery; until then it is at least a failure a caller
    /// can see.
    convenience init(
        storedAt url: URL,
        saveContext: @escaping (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        self.init(
            container: try Self.container(for: ModelConfiguration(url: url)),
            saveContext: saveContext
        )
    }

    private static func container(for configuration: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(
            for: Schema(SiraSchema.models),
            migrationPlan: SiraMigrationPlan.self,
            configurations: configuration
        )
    }

    func add(_ match: Match) {
        context.insert(match)
        save()
    }

    /// Adds `round` as the Match's latest. The Round is inserted alongside so
    /// that it is a stored object in its own right rather than reachable only
    /// through the Match that happens to hold it.
    func addRound(_ round: Round, to match: Match) {
        context.insert(round)
        match.addRound(round)
        save()
    }

    /// Records an accepted Rejoin. Declining one is not here because declining
    /// changes nothing that is stored — the Round that put the Entrant Out was
    /// saved as it was entered, and staying Out is what that Round already
    /// says.
    func recordRejoin(_ rejoin: RejoinEvent, in match: Match) {
        match.recordRejoin(rejoin)
        save()
    }

    /// Removes the Match's most recent Round and deletes it.
    ///
    /// Both halves matter: dropping the Round from the relationship is what
    /// reverses the score, and deleting it is what stops the Round outliving
    /// the Match's memory of it as an orphan.
    func undoLastRound(in match: Match) {
        guard let undone = match.undoLastRound() else { return }
        context.delete(undone)
        save()
    }

    func archive(_ match: Match) {
        match.archive()
        save()
    }

    func restore(_ match: Match) {
        match.restore()
        save()
    }

    /// Dismisses the save failure the player has been told about. The change it
    /// refers to stays in memory either way — this clears the message, not the
    /// data.
    func acknowledgeSaveFailure() {
        saveFailure = nil
    }

    /// Writes the context out, recording rather than raising a failure.
    ///
    /// A failed save leaves the context's pending changes exactly where they
    /// are, so the Match on screen is still the Match the player entered, and
    /// the next save that succeeds writes it out along with everything that
    /// failed before it.
    private func save() {
        do {
            try saveContext(context)
            saveFailure = nil
        } catch {
            saveFailure = SaveFailure(error: error)
        }
    }
}

extension MatchStore {
    /// A save that did not reach the disk. Carries the underlying error for
    /// diagnosis; what the player is shown is deliberately not the error's own
    /// wording, which describes a database rather than a game.
    struct SaveFailure {
        let error: Error
    }
}

extension MatchStore {
    /// Where the app keeps its Matches: one database in Application Support,
    /// which iOS backs up and does not purge, so a Match survives being
    /// restored onto a new device.
    static func defaultStoreURL() throws -> URL {
        let directory = URL.applicationSupportDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "Sira.store")
    }

    /// The store the app itself runs on, over the database on the device.
    ///
    /// Crashes when that store cannot be opened, which is a stopgap and is
    /// ticket 07's whole subject: an unreadable file should be moved aside and
    /// the app should open empty. It is written this way rather than falling
    /// back to an in-memory container because an app that looks like it is
    /// working while saving nothing is the worse of the two failures.
    static func forApp() -> MatchStore {
        do {
            return try MatchStore(storedAt: defaultStoreURL())
        } catch {
            fatalError("Could not open the Match store: \(error)")
        }
    }
}
