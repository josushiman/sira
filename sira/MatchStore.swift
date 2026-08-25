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
    /// Throws rather than crashing when the store cannot be opened, leaving
    /// what to do about that to the caller. The app itself does not use this
    /// directly — it opens through `init(recoveringAt:)`, which is this plus a
    /// second chance.
    convenience init(
        storedAt url: URL,
        saveContext: @escaping (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        self.init(
            container: try Self.container(for: ModelConfiguration(url: url)),
            saveContext: saveContext
        )
    }

    /// A store over the database at `url`, recovering rather than failing when
    /// that database cannot be opened: the unreadable files are moved aside
    /// under a timestamped name and a fresh store is opened in their place, so
    /// the app launches with an empty Home and the old data is still on the
    /// device.
    ///
    /// There is deliberately no in-memory fallback. An app that opens, accepts
    /// Rounds and writes none of them is the worse of the two failures — it
    /// looks like it is working — so if the fresh store cannot be opened
    /// either, this throws rather than pretending.
    convenience init(
        recoveringAt url: URL,
        saveContext: @escaping (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        self.init(container: try Self.recoveredContainer(at: url), saveContext: saveContext)
    }

    private static func recoveredContainer(at url: URL) throws -> ModelContainer {
        do {
            return try container(for: ModelConfiguration(url: url))
        } catch {
            try moveAside(url)
            return try container(for: ModelConfiguration(url: url))
        }
    }

    /// Moves the store at `url` out of the way, along with the sidecar files
    /// SQLite keeps beside it, under a name stamped with the moment they were
    /// set aside.
    ///
    /// Moved rather than removed, always: data that cannot be read today may
    /// be readable by the build that ships next week, and deleting a player's
    /// Matches to make the app start again is not a trade this app gets to
    /// make on their behalf.
    ///
    /// Throwing here aborts the recovery and, from `forApp()`, the launch. That
    /// is the honest outcome for the case it describes: nothing can be moved
    /// out of the way, so a fresh store cannot be put in its place either
    /// without writing over data this app has promised to keep. The one cause
    /// that would be self-inflicted — a name already in use — is ruled out by
    /// `unusedMovedAsideName(...)` rather than left to the clock.
    private static func moveAside(_ url: URL) throws {
        let directory = url.deletingLastPathComponent()
        let movedName = unusedMovedAsideName(for: url, in: directory)

        for suffix in storeFileSuffixes {
            let source = directory.appending(path: url.lastPathComponent + suffix)
            guard FileManager.default.fileExists(atPath: source.path) else { continue }
            try FileManager.default.moveItem(
                at: source,
                to: directory.appending(path: movedName + suffix)
            )
        }
    }

    /// The store file itself — the empty suffix — plus SQLite's write-ahead log
    /// and shared memory files, which are named after it and are as much a part
    /// of the data as it is. Moving the store alone would hand the fresh one
    /// the tail of the old.
    private static let storeFileSuffixes = ["", "-wal", "-shm"]

    /// A name for the set-aside store that no file in `directory` is using —
    /// timestamped, as the ticket asks, and then disambiguated if that is
    /// somehow not enough.
    ///
    /// The clock alone would nearly always do. "Nearly" is the problem: a
    /// second recovery landing on a name already taken makes the move throw,
    /// which turns a launch this code exists to rescue into one that fails, so
    /// the collision is checked for rather than assumed away.
    private static func unusedMovedAsideName(for url: URL, in directory: URL) -> String {
        let stem = url.deletingPathExtension().lastPathComponent
        let extensionSuffix = url.pathExtension.isEmpty ? "" : ".\(url.pathExtension)"
        let stamp = unreadableNameFormatter.string(from: Date())

        func isFree(_ name: String) -> Bool {
            storeFileSuffixes.allSatisfy { suffix in
                !FileManager.default.fileExists(atPath: directory.appending(path: name + suffix).path)
            }
        }

        var name = "\(stem)-unreadable-\(stamp)\(extensionSuffix)"
        var attempt = 2
        while !isFree(name) {
            name = "\(stem)-unreadable-\(stamp)-\(attempt)\(extensionSuffix)"
            attempt += 1
        }
        return name
    }

    private static let unreadableNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd-HHmmss.SSS"
        return formatter
    }()

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

    /// Renames an Entrant.
    ///
    /// Nothing else has to move with it. Every screen reads a name off the
    /// Entrant as it renders and every score is keyed on `Entrant.ID`, so this
    /// one write is the rename everywhere at once — Rounds already played
    /// included — and no total, delta or Out state is touched by it.
    ///
    /// The name is expected to have been through `EntrantName` already: this
    /// records a decision rather than making one, exactly as `recordRejoin`
    /// does with a target.
    func rename(_ entrant: Entrant, to name: String) {
        entrant.name = name
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

    /// Removes `match` for good, taking its Entrants and Rounds with it —
    /// SwiftData cascades to both, which is what `Match`'s relationships
    /// declare and what makes deleting one Match unable to touch another's
    /// history.
    ///
    /// There is no pending-deletion state and nothing to undo: a Match that is
    /// deleted-but-restorable is a third durability state, and this app
    /// persists exactly one thing. The confirmation on the way in is where the
    /// player gets to change their mind.
    ///
    /// A deletion whose save fails behaves like every other change here: it
    /// stands in memory, the failure is surfaced, and the next save that
    /// succeeds writes it out along with it. Until one does, the Match is off
    /// Home and still on the disk — which is the same window every other
    /// mutation has, and is why the player is told rather than left to find
    /// out at the next launch.
    func delete(_ match: Match) {
        context.delete(match)
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
    /// Unreadable data does not stop the app: it is moved aside and a fresh
    /// store opened, so a corrupt file costs the player their history rather
    /// than their app, and even then only until a build that can read it comes
    /// along. Crashing here therefore means a store that could not be opened
    /// *and* could not be replaced — the device is not writable — which no
    /// amount of falling back can turn into a working app.
    static func forApp() -> MatchStore {
        do {
            return try MatchStore(recoveringAt: defaultStoreURL())
        } catch {
            fatalError("Could not open or replace the Match store: \(error)")
        }
    }
}
