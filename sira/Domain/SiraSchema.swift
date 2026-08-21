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
enum SiraSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Match.self, Round.self, Entrant.self]
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
