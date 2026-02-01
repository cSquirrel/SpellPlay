import Foundation
import SwiftData

/// Version 1.0.0 - Initial schema
enum WordCraftSchemaV1_0_0: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            SpellingTest.self,
            Word.self,
            PracticeSession.self,
            UserProgress.self,
        ]
    }
}

/// Current schema version
typealias CurrentSchema = WordCraftSchemaV1_0_0

/// Top-level typealiases for easy access to current schema models
typealias SpellingTest = WordCraftSchemaV1_0_0.SpellingTest
typealias Word = WordCraftSchemaV1_0_0.Word
typealias PracticeSession = WordCraftSchemaV1_0_0.PracticeSession
typealias UserProgress = WordCraftSchemaV1_0_0.UserProgress

/// Migration plan for schema versions
enum WordCraftMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [WordCraftSchemaV1_0_0.self]
    }

    static var stages: [MigrationStage] {
        // No migrations yet - this is the initial version
        // Add migration stages here when creating new schema versions
        // Example:
        // [.lightweight(fromVersion: WordCraftSchemaV1_0_0.self, toVersion: WordCraftSchemaV2_0_0.self)]
        []
    }
}
