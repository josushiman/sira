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
