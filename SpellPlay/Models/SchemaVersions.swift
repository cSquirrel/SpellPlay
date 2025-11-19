//
//  SchemaVersions.swift
//  WordCraft
//
//  SwiftData schema versioning
//
//  HOW MODEL VERSIONING WORKS:
//  - You don't create separate versions of model classes (e.g., SpellingTestV1, SpellingTestV2)
//  - Instead, you modify the existing model classes (SpellingTest, Word, etc.) when needed
//  - Each VersionedSchema references the current state of the model classes at that version
//  - When you change a model, create a new VersionedSchema (e.g., V2_0_0) that references the updated models
//  - SwiftData compares schemas and migrates automatically for simple changes (adding optional properties)
//  - For complex changes, add custom migration stages to the MigrationPlan
//

import Foundation
import SwiftData

/// Version 1.0.0 - Initial schema
enum WordCraftSchemaV1_0_0: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            SpellingTest.self,
            Word.self,
            PracticeSession.self
        ]
    }
}

/// Current schema version
typealias CurrentSchema = WordCraftSchemaV1_0_0

/// Top-level typealiases for easy access to current schema models
typealias SpellingTest = WordCraftSchemaV1_0_0.SpellingTest
typealias Word = WordCraftSchemaV1_0_0.Word
typealias PracticeSession = WordCraftSchemaV1_0_0.PracticeSession

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
        return []
    }
}

