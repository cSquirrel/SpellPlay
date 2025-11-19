# SwiftData Migration Guide

This guide explains how to handle schema migrations for the WordCraft app using SwiftData's VersionedSchema.

## Overview

The WordCraft app uses SwiftData's `VersionedSchema` and `SchemaMigrationPlan` for proper schema versioning. **SwiftData handles most migrations automatically** - you typically don't need to write migration code for simple changes.

## Architecture

### Current Implementation

- **VersionedSchema**: `WordCraftSchemaV1_0_0` - Defines schema version 1.0.0
- **Model Encapsulation**: All models (`SpellingTest`, `Word`, `PracticeSession`) are defined within `extension WordCraftSchemaV1_0_0`
- **Migration Plan**: `WordCraftMigrationPlan` - Defines migration stages between schema versions
- **Top-level Typealiases**: Convenient access to current schema models

### File Structure

```
WordCraft/Models/
├── SchemaVersions.swift      # VersionedSchema definitions and migration plan
├── SpellingTest.swift         # Model defined in extension WordCraftSchemaV1_0_0
├── Word.swift                 # Model defined in extension WordCraftSchemaV1_0_0
└── PracticeSession.swift      # Model defined in extension WordCraftSchemaV1_0_0
```

## When SwiftData Handles Migrations Automatically

These changes require **no migration code**:

- ✅ Adding optional properties
- ✅ Adding new models
- ✅ Adding new relationships
- ✅ Removing properties (data is lost, but app doesn't crash)

## When You Need Manual Migration

You only need to write migration code for:

- ❌ Renaming properties
- ❌ Changing property types (e.g., `Int` → `Int64`)
- ❌ Making properties required (need to set default values)
- ❌ Complex data transformations

## Creating a New Schema Version

### Step 1: Modify the Model Classes

Modify the existing model classes as needed. For example, adding a new property:

```swift
// WordCraft/Models/SpellingTest.swift
extension WordCraftSchemaV1_0_0 {
    @Model
    final class SpellingTest {
        // ... existing properties
        var difficulty: String?  // New optional property
    }
}
```

### Step 2: Create New VersionedSchema

Create a new schema version in `SchemaVersions.swift`:

```swift
// WordCraft/Models/SchemaVersions.swift

// Keep the old version!
enum WordCraftSchemaV1_0_0: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [SpellingTest.self, Word.self, PracticeSession.self]
    }
}

// Create new version
enum WordCraftSchemaV2_0_0: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [SpellingTest.self, Word.self, PracticeSession.self]  // Updated models
    }
}

// Update current schema
typealias CurrentSchema = WordCraftSchemaV2_0_0

// Update top-level typealiases
typealias SpellingTest = WordCraftSchemaV2_0_0.SpellingTest
typealias Word = WordCraftSchemaV2_0_0.Word
typealias PracticeSession = WordCraftSchemaV2_0_0.PracticeSession
```

### Step 3: Move Models to New Schema Extension

Move the model definitions to the new schema extension:

```swift
// WordCraft/Models/SpellingTest.swift
extension WordCraftSchemaV2_0_0 {  // Changed from V1_0_0
    @Model
    final class SpellingTest {
        // ... properties including new ones
        var difficulty: String?
    }
}
```

### Step 4: Update Migration Plan

Add the new schema and migration stage to the migration plan:

```swift
enum WordCraftMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            WordCraftSchemaV1_0_0.self,  // Old version
            WordCraftSchemaV2_0_0.self    // New version
        ]
    }
    
    static var stages: [MigrationStage] {
        [
            // Lightweight migration - SwiftData handles automatically
            .lightweight(
                fromVersion: WordCraftSchemaV1_0_0.self,
                toVersion: WordCraftSchemaV2_0_0.self
            )
        ]
    }
}
```

### Step 5: Update App Initialization

The app automatically uses the new schema via `CurrentSchema`:

```swift
// WordCraftApp.swift - no changes needed!
// It already uses CurrentSchema which now points to V2_0_0
```

## Migration Patterns

### Pattern 1: Adding Optional Property

**No migration needed** - SwiftData handles this automatically with lightweight migration.

1. Add property to model in current schema extension
2. Create new VersionedSchema (e.g., V2_0_0)
3. Move model to new schema extension
4. Add lightweight migration stage

### Pattern 2: Adding Required Property

Requires custom migration to set default values:

```swift
// 1. Create new schema version (V2_0_0)
// 2. Add required property to model
extension WordCraftSchemaV2_0_0 {
    @Model
    final class SpellingTest {
        var difficulty: String  // Required property
    }
}

// 3. Add custom migration stage
static var stages: [MigrationStage] {
    [
        .custom(
            fromVersion: WordCraftSchemaV1_0_0.self,
            toVersion: WordCraftSchemaV2_0_0.self,
            willMigrate: { context in
                // Set default values for existing records
                let descriptor = FetchDescriptor<WordCraftSchemaV1_0_0.SpellingTest>()
                let tests = try context.fetch(descriptor)
                for test in tests {
                    // Access through old schema version
                    // Set default value
                }
            }
        )
    ]
}
```

### Pattern 3: Renaming Property

Requires custom migration with data copying:

```swift
// Step 1: Add new property alongside old one
extension WordCraftSchemaV2_0_0 {
    @Model
    final class SpellingTest {
        var lastPracticed: Date?      // Old property (keep temporarily)
        var lastPracticeDate: Date?    // New property
    }
}

// Step 2: Custom migration to copy data
.custom(
    fromVersion: WordCraftSchemaV1_0_0.self,
    toVersion: WordCraftSchemaV2_0_0.self,
    willMigrate: { context in
        // Copy data from old property to new property
    }
)

// Step 3: In next version (V3_0_0), remove old property
```

### Pattern 4: Changing Property Type

Requires custom migration with type conversion:

```swift
.custom(
    fromVersion: WordCraftSchemaV1_0_0.self,
    toVersion: WordCraftSchemaV2_0_0.self,
    willMigrate: { context in
        // Convert property types
        // Example: Int to Int64
    }
)
```

## Best Practices

1. **Always Use VersionedSchema from the Start**
   - Never start without versioning - it causes migration issues later
   - Always encapsulate models in schema extensions

2. **Keep Old Schema Versions**
   - Never delete old VersionedSchema definitions
   - They're needed for migration paths

3. **Prefer Optional Properties**
   - Adding optional properties requires no migration code
   - Only make properties required if absolutely necessary

4. **Test Migrations Thoroughly**
   - Test with real data structures
   - Test on simulator and device
   - Test on different iOS versions
   - Test migration from each previous version

5. **Document Changes**
   - Document what changed and why in schema comments
   - Note any data loss scenarios
   - Document migration strategy

## Current Schema Structure

### Version 1.0.0 (Current)

- `WordCraftSchemaV1_0_0` - Initial schema
- Models: `SpellingTest`, `Word`, `PracticeSession`
- All models encapsulated in `extension WordCraftSchemaV1_0_0`
- No migration stages (initial version)

## Example: Complete Migration (Adding Optional Property)

Here's a complete example for adding an optional property:

### 1. Modify Model

```swift
// WordCraft/Models/SpellingTest.swift
extension WordCraftSchemaV2_0_0 {  // New version
    @Model
    final class SpellingTest {
        @Attribute(.unique) var id: UUID
        var name: String
        var createdAt: Date
        var lastPracticed: Date?
        var difficulty: String?  // NEW: Optional property
        
        @Relationship(deleteRule: .cascade)
        var words: [Word] = []
        
        init(name: String) {
            self.id = UUID()
            self.name = name
            self.createdAt = Date()
            self.lastPracticed = nil
            self.difficulty = nil  // Initialize new property
        }
    }
}
```

### 2. Create New Schema Version

```swift
// WordCraft/Models/SchemaVersions.swift
enum WordCraftSchemaV2_0_0: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [SpellingTest.self, Word.self, PracticeSession.self]
    }
}

typealias CurrentSchema = WordCraftSchemaV2_0_0
typealias SpellingTest = WordCraftSchemaV2_0_0.SpellingTest
```

### 3. Update Migration Plan

```swift
enum WordCraftMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [WordCraftSchemaV1_0_0.self, WordCraftSchemaV2_0_0.self]
    }
    
    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: WordCraftSchemaV1_0_0.self,
                toVersion: WordCraftSchemaV2_0_0.self
            )
        ]
    }
}
```

That's it! SwiftData handles the migration automatically.

## Troubleshooting

### App Crashes After Schema Change

- Check if you're making a required property without custom migration
- Verify migration plan includes all schema versions
- Ensure models are properly encapsulated in schema extensions
- Check for nil values in required properties

### Migration Not Running

- Verify migration plan is registered in `ModelContainer` initialization
- Check that all schema versions are listed in `schemas` array
- Ensure migration stages are correctly defined

### Data Loss

- Review custom migration code for data transformation
- Check if properties were removed without migration
- Verify required properties have defaults set in custom migrations

## Summary

- **Use VersionedSchema**: Always encapsulate models in schema extensions
- **Most changes**: No migration code needed (SwiftData handles automatically)
- **Complex changes**: Use custom migration stages
- **Keep old schemas**: Never delete previous VersionedSchema definitions
- **Test thoroughly**: Test all migration paths
