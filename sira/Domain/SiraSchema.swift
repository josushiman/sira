import Foundation
import SwiftData

/// The frozen V1 stored shape. Keep these declarations independent of the live
/// models: changing a live model must never rewrite the schema on old devices.
/// V1 includes the additive joins, arrival, Started, tally and Unlock changes
/// made before V2. Only stored properties and their relationships belong here.
enum SiraSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Match.self, Round.self, Entrant.self, StartedMatchTally.self, UnlockCache.self]
    }

    @Model
    final class Match {
        var id: UUID
        var game: Game
        var variantId: String
        var limit: Int?
        var startingScore: Int?
        var roundCount: Int?
        var mode: EntrantMode
        @Relationship(deleteRule: .cascade, inverse: \Entrant.match)
        private(set) var storedEntrants: [Entrant]
        @Relationship(deleteRule: .cascade, inverse: \Round.match)
        private(set) var storedRounds: [Round]
        var archived: Bool
        var started: Bool = false
        var createdAt: Date

        init(
            id: UUID = UUID(), game: Game, variantId: String,
            limit: Int? = nil, startingScore: Int? = nil, roundCount: Int? = nil,
            mode: EntrantMode, storedEntrants: [Entrant], storedRounds: [Round],
            archived: Bool = false, createdAt: Date = Date()
        ) {
            self.id = id
            self.game = game
            self.variantId = variantId
            self.limit = limit
            self.startingScore = startingScore
            self.roundCount = roundCount
            self.mode = mode
            self.storedEntrants = storedEntrants
            self.storedRounds = storedRounds
            self.archived = archived
            self.createdAt = createdAt
        }
    }

    @Model
    final class Round {
        var id: UUID
        private(set) var sequence = 0
        var deltas: [UUID: Int]
        var rejoins: [RejoinEvent]
        var joins: [JoinEvent] = []
        var cifteCallers: Set<UUID>
        var okeyAtanID: UUID?
        var losingEntrantID: UUID?
        var gostergeFinderID: UUID?
        private(set) var match: Match?

        init(
            id: UUID = UUID(), sequence: Int = 0, deltas: [UUID: Int] = [:],
            rejoins: [RejoinEvent] = [], joins: [JoinEvent] = [],
            cifteCallers: Set<UUID> = [], okeyAtanID: UUID? = nil,
            losingEntrantID: UUID? = nil, gostergeFinderID: UUID? = nil
        ) {
            self.id = id
            self.sequence = sequence
            self.deltas = deltas
            self.rejoins = rejoins
            self.joins = joins
            self.cifteCallers = cifteCallers
            self.okeyAtanID = okeyAtanID
            self.losingEntrantID = losingEntrantID
            self.gostergeFinderID = gostergeFinderID
        }
    }

    @Model
    final class Entrant {
        var id: UUID
        var name: String
        private(set) var sequence = 0
        private(set) var arrivedMidMatch = false
        private(set) var match: Match?

        init(id: UUID = UUID(), name: String, sequence: Int = 0, arrivedMidMatch: Bool = false) {
            self.id = id
            self.name = name
            self.sequence = sequence
            self.arrivedMidMatch = arrivedMidMatch
        }
    }

    @Model
    final class StartedMatchTally {
        var startedMatches: Int

        init(startedMatches: Int = 0) { self.startedMatches = startedMatches }
    }

    @Model
    final class UnlockCache {
        var hasSeenVerifiedUnlock: Bool

        init(hasSeenVerifiedUnlock: Bool = false) {
            self.hasSeenVerifiedUnlock = hasSeenVerifiedUnlock
        }
    }
}

enum SiraSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Match.self, Round.self, Entrant.self, StartedMatchTally.self, UnlockCache.self]
    }
}

/// The schema every new or reopened container uses.
typealias SiraSchema = SiraSchemaV2

enum SiraMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SiraSchemaV1.self, SiraSchemaV2.self] }

    static var stages: [MigrationStage] {
        [.custom(
            fromVersion: SiraSchemaV1.self,
            toVersion: SiraSchemaV2.self,
            willMigrate: nil,
            didMigrate: { context in
                // The old target is deliberately retained in this preparatory
                // release. Capture its result before ticket 02 retires its
                // meaning, without changing a Match's archive visibility.
                let matches = try context.fetch(FetchDescriptor<Match>())
                var inferredStarts = 0
                for match in matches {
                    match.prepareCountBasedEnding()
                    if !match.rounds.isEmpty, match.start() { inferredStarts += 1 }
                }

                // V1's Started flag and tally were added separately. Rounds
                // prove missing Starts; an already-Started, zero-Round Match
                // is history too. Never lower a tally, which can include
                // Matches since deleted, or count an existing Start twice.
                let knownStarts = matches.filter(\.started).count
                let storedTally = try context.fetch(FetchDescriptor<StartedMatchTally>()).first
                if knownStarts > 0 || storedTally != nil {
                    let tally = storedTally ?? StartedMatchTally()
                    if storedTally == nil { context.insert(tally) }
                    let accountedStarts = tally.startedMatches + (storedTally == nil ? 0 : inferredStarts)
                    tally.startedMatches = max(accountedStarts, knownStarts)
                }
                try context.save()
            }
        )]
    }
}
