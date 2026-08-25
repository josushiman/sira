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

    /// How many of the three Free Matches are left — what Home's meter draws
    /// and, from ticket 03, what the wall asks.
    ///
    /// Held here as well as stored so that reading it is not a fetch on every
    /// redraw, and so that it changes observably: this is the property Home
    /// watches, and a count living only in a `StartedMatchTally` fetched on
    /// demand would move without telling anyone.
    ///
    /// The stored row is the truth and this is loaded from it at init, so the
    /// two agree at every launch. Between launches they are kept in step by
    /// `recordStart()` being the only thing that moves either.
    private(set) var freeMatches: FreeMatches

    /// Whether this device has ever seen a verified Unlock — the local half of
    /// `GameAccess`, and a **cache of a truth Apple owns** rather than a source
    /// of truth (`UnlockCache`, `docs/adr/0011`).
    ///
    /// Kept here, beside the meter, because it is durable state that changes
    /// through a save like every other durable state in the app, and because
    /// the two things `GameAccess` is made of are then durable in one place.
    /// What decides its value is `UnlockStore`, which is the only thing that
    /// has ever spoken to StoreKit; this store records what it was told.
    ///
    /// Held in memory as well as stored for the same reason `freeMatches` is:
    /// Home watches it, and a value fetched on demand would move without
    /// telling anyone.
    private(set) var hasSeenUnlock: Bool

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
        // Read once, here, rather than fetched wherever it is asked for. A
        // store over a database holding no tally reads as zero — a fresh
        // install, and the reinstall case with it, both of which start with
        // three Free Matches.
        let stored = (try? container.mainContext.fetch(FetchDescriptor<StartedMatchTally>()))?.first
        self.freeMatches = FreeMatches(startedMatches: stored?.startedMatches ?? 0)
        // And the same for the Unlock: no row is the honest answer for a
        // device that has never seen a verified purchase, and for one whose
        // cache StoreKit has not written yet.
        let cached = (try? container.mainContext.fetch(FetchDescriptor<UnlockCache>()))?.first
        self.hasSeenUnlock = cached?.hasSeenVerifiedUnlock ?? false
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
        // A Match built with Rounds arrives Started — `Match.init` says so
        // from the Rounds themselves — and a Match that arrives Started has
        // consumed a Free Match as surely as one that Starts a Round at a
        // time. Recorded here so that the tally counts Started Matches however
        // they came to be, rather than only those that went through
        // `addRound`. Setup's Match has no Rounds and costs nothing until one
        // is scored on it, which is the path the app itself takes.
        if match.started { recordStart() }
        save()
    }

    /// Adds `round` as the Match's latest. The Round is inserted alongside so
    /// that it is a stored object in its own right rather than reachable only
    /// through the Match that happens to hold it.
    /// Whether this Round Starts the Match is read before it is added rather
    /// than after: `Match.addRound` Starts the Match on the way through, so by
    /// the time it returns every Match looks Started and the Round that did it
    /// is indistinguishable from the ones after. Asked here, and the tally
    /// moves inside the same `save()` as the Round, so a Free Match can never
    /// be spent by a Round that did not reach the disk or kept by one that
    /// did.
    func addRound(_ round: Round, to match: Match) {
        let starting = !match.started
        context.insert(round)
        match.addRound(round)
        if starting { recordStart() }
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

    /// Seats a new Entrant at the Match's next free seat, entering on `total`,
    /// and records the arrival against the Match's latest Round — so Undo
    /// reverses a mistaken add exactly as it reverses a mistaken score.
    ///
    /// The Entrant is inserted alongside for the same reason a Round is: a
    /// stored object in its own right rather than one reachable only through
    /// the Match that happens to hold it.
    ///
    /// Both the name and the total are expected to have been decided already —
    /// the name by `EntrantName`, the total by `RosterAddition`. This records
    /// the arrival rather than judging it, exactly as `recordRejoin` does.
    func addEntrant(_ entrant: Entrant, to match: Match, joiningOn total: Int) {
        context.insert(entrant)
        match.addEntrant(entrant, joiningOn: total)
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

    /// Clears out the Matches that were set up and never scored, and is the
    /// app's first act at launch (`forApp()`).
    ///
    /// Home lists Started Matches only, so an un-Started one is unreachable
    /// the moment the player leaves it — backed out of, or lost to iOS
    /// reclaiming the app mid-Match. There is nothing to preserve: a Match
    /// with no Rounds has no tally, only a Variant choice and some Entrant
    /// names. Left alone it would sit on the device forever, invisible.
    ///
    /// Run at launch and nowhere else, because the one un-Started Match that
    /// must survive is the one being played right now — Setup hands Play a
    /// Match before its first Round, and at launch there is no such Match.
    ///
    /// A Match carrying Rounds is Started first rather than swept up with the
    /// rest. Data written before the flag existed reads back as un-Started
    /// whatever it holds, and deleting a played Match because a default said
    /// so is not a trade this app gets to make on the player's behalf. The
    /// Rounds are older than the flag, and they are believed over it.
    func discardUnstartedMatches() {
        let matches = (try? context.fetch(FetchDescriptor<Match>())) ?? []
        for match in matches where !match.started {
            if match.rounds.isEmpty {
                context.delete(match)
            } else if match.start() {
                // Started here rather than by a Round, and counted all the
                // same: the Rounds are the evidence the game was played, and a
                // tally that believed the flag over them would hand back Free
                // Matches this player has already spent. The `if` is what
                // keeps it to once — `start()` answers `true` only the first
                // time — so a launch that sweeps nothing counts nothing.
                recordStart()
            }
        }
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

    /// Records what StoreKit last said about the Unlock: `true` from a
    /// verified transaction, `false` from an explicitly revoked or refunded
    /// one.
    ///
    /// Silence is not a value this takes. Nothing calls it when StoreKit
    /// returns nothing, which is what leaves a device that has seen a purchase
    /// unlocked offline — the rule lives in `UnlockStore`, and this is the
    /// write it asks for once the rule has been applied.
    ///
    /// A no-op when nothing changes, so that the entitlement check every
    /// launch performs does not write a row and a save for an answer the
    /// device already had.
    ///
    /// Re-locking touches nothing else. Every Match, Round and Entrant is
    /// exactly where it was, and stays readable and scorable: what a revocation
    /// changes is what the player may *start*.
    func recordUnlock(seen: Bool) {
        guard seen != hasSeenUnlock else { return }
        let cache = (try? context.fetch(FetchDescriptor<UnlockCache>()))?.first ?? {
            let fresh = UnlockCache()
            context.insert(fresh)
            return fresh
        }()
        cache.hasSeenVerifiedUnlock = seen
        hasSeenUnlock = seen
        save()
    }

    /// Dismisses the save failure the player has been told about. The change it
    /// refers to stays in memory either way — this clears the message, not the
    /// data.
    func acknowledgeSaveFailure() {
        saveFailure = nil
    }

    /// Counts one Match Starting, against the stored tally and the count held
    /// here, and saves neither: every caller is mid-mutation and about to
    /// save, and going through their `save()` is what puts the Start and the
    /// Round that caused it in one write.
    ///
    /// The stored row is created on first use rather than at launch, so
    /// opening the app and not playing writes nothing, and a store that has
    /// never seen a Start holds no tally to read back.
    ///
    /// A save that then fails leaves this exactly as it leaves everything else
    /// here: the change stands in memory, the failure is surfaced, and the
    /// next save that succeeds writes it out. A Free Match spent on screen and
    /// not on the disk is the same window every other mutation has.
    private func recordStart() {
        let tally = (try? context.fetch(FetchDescriptor<StartedMatchTally>()))?.first ?? {
            let fresh = StartedMatchTally()
            context.insert(fresh)
            return fresh
        }()
        tally.recordStart()
        freeMatches = FreeMatches(startedMatches: tally.startedMatches)
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
            let store = try MatchStore(recoveringAt: defaultStoreURL())
            // Before anything reads them: a Match set up and never scored is
            // unreachable now that Home lists Started Matches only, and the
            // launch it did not survive is the last moment it could be tidied
            // away on the player's behalf.
            store.discardUnstartedMatches()
            return store
        } catch {
            fatalError("Could not open or replace the Match store: \(error)")
        }
    }
}
