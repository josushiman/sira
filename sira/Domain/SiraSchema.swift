import Foundation
import SwiftData

/// The stored shape of a Match, at version 1.
///
/// Declared as a `VersionedSchema` from the first release rather than left as a
/// bare model list, so that the first migration this app ever needs is only a
/// migration — not also the change that introduces versioning to a store that
/// is already on people's devices. This domain changed in three consecutive
/// commits before it was ever stored; assuming it has now stopped changing
/// would be optimistic.
/// The model types are named here rather than nested inside this enum, which is
/// the other way it is commonly written. While there is one version the two are
/// equivalent, and top-level types keep `Match` spelled `Match` across the ~25
/// files that use it. The cost is paid on the day a v2 arrives: v1's shape then
/// has to be preserved by copying today's declarations *into* this enum, so that
/// `SiraSchemaV1` still describes what is actually on devices while the live
/// types move on. A migration stage is the thing that maps between them.
///
/// Version 1.0.0 has since absorbed three **additive** changes, all properties
/// with defaults that SwiftData lightweight-migrates: `Round.joins` (empty),
/// `Entrant.arrivedMidMatch` (`false` — seated at Setup, which every Entrant
/// stored before it truthfully was) and `Match.started`. Recorded here rather
/// than left implicit, because the recipe above says v1's shape is recovered
/// by copying today's declarations into this enum, and today's declarations
/// are no longer the shape 1.0.0 first described.
///
/// The third is where the run of luck ends, and it is worth being precise
/// about why. `Match.started` is the first of these whose default is *wrong*
/// for data written before it: a Match with Rounds on it was scored, and
/// `false` says it was not. What covers that is not the schema but a
/// reconciliation at launch — `MatchStore.discardUnstartedMatches()` believes
/// the Rounds over the default — which is a migration living outside the
/// migration plan.
///
/// It is done that way because nothing has shipped: there are no devices
/// holding v1 data, so cutting a v2 here would be a stage that migrates
/// nothing, and the launch sweep has to exist regardless. The next such change
/// does not get the same argument. Cut a v2 then, and move this reconciliation
/// into its stage where it belongs.
///
/// The fourth change is `StartedMatchTally`, a new entity rather than a new
/// property. SwiftData lightweight-migrates that too — an added table, which
/// reads back holding no rows — and `MatchStore` treats no row as a tally of
/// zero, so nothing has to exist before the first Match Starts.
///
/// Zero is the *wrong* answer for a store that already holds Started Matches,
/// which is the same kind of wrongness `Match.started` had, and it is covered
/// the same way and only as far: `discardUnstartedMatches()` counts the
/// Matches it Starts at launch, which reaches data written before the flag
/// existed. Data written after the flag and before this tally is already
/// Started, so the sweep does not look at it and it goes uncounted — a player
/// in that window would get their three Free Matches over again. That window
/// is entirely pre-release, which is the only reason it is acceptable to leave
/// it. It is the second thing owed to the v2 stage when one is cut.
enum SiraSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Match.self, Round.self, Entrant.self, StartedMatchTally.self, UnlockCache.self]
    }
}

/// The current schema, which every container is opened against. One alias to
/// update when a v2 arrives, rather than a version named at each call site.
typealias SiraSchema = SiraSchemaV1

/// How the store gets from one schema version to the next.
///
/// Empty while there is only one version — there is nothing to migrate from.
/// It exists now so that adding v2 is a matter of appending a stage to a plan
/// the container already uses, rather than introducing a plan and a migration
/// in the same change.
enum SiraMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SiraSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
