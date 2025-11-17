# SwiftData Model Versioning Example

## How Model Classes Are Versioned

In SwiftData, **you don't create separate versions of model classes**. Instead:

1. **Modify the existing model class** when you need changes
2. **Create a new VersionedSchema** that references the updated models
3. **SwiftData automatically migrates** between schema versions

## Example: Adding a Property to SpellingTest

### Step 1: Modify the Model Class

```swift
// SpellPlay/Models/SpellingTest.swift
@Model
final class SpellingTest {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var lastPracticed: Date?
    
    // NEW: Add optional property
    var difficulty: String?  // ← New property added
    
    @Relationship(deleteRule: .cascade)
    var words: [Word] = []
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.lastPracticed = nil
        self.difficulty = nil  // ← Initialize new property
    }
}
```

### Step 2: Create New VersionedSchema

```swift
// SpellPlay/Models/SchemaVersions.swift

// OLD VERSION (keep this!)
enum SpellPlaySchemaV1_0_0: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            SpellingTest.self,  // Original version (without difficulty)
            Word.self,
            PracticeSession.self
        ]
    }
}

// NEW VERSION
enum SpellPlaySchemaV2_0_0: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            SpellingTest.self,  // Updated version (with difficulty property)
            Word.self,
            PracticeSession.self
        ]
    }
}

// Update current schema
typealias CurrentSchema = SpellPlaySchemaV2_0_0
```

### Step 3: Update Migration Plan

```swift
enum SpellPlayMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            SpellPlaySchemaV1_0_0.self,  // Old version
            SpellPlaySchemaV2_0_0.self   // New version
        ]
    }
    
    static var stages: [MigrationStage] {
        [
            // Lightweight migration - SwiftData handles it automatically
            .lightweight(
                fromVersion: SpellPlaySchemaV1_0_0.self,
                toVersion: SpellPlaySchemaV2_0_0.self
            )
        ]
    }
}
```

### Step 4: Update App Initialization

The app initialization in `SpellPlayApp.swift` automatically uses the new schema:

```swift
var modelContainer: ModelContainer = {
    let migrationPlan = SpellPlayMigrationPlan.self
    let schema = Schema(CurrentSchema.models)  // Uses V2_0_0 now
    
    // ... rest of initialization
}()
```

## Key Points

1. **Same Model Class**: You modify `SpellingTest` directly, not create `SpellingTestV2`
2. **VersionedSchema Tracks Changes**: Each VersionedSchema represents the state of all models at that version
3. **Automatic Migration**: For optional properties, SwiftData migrates automatically
4. **Keep Old Schemas**: Always keep previous VersionedSchema definitions for migration

## For Complex Changes

If you need to rename a property or change types, you might need:

1. **Custom Migration Stage**: Instead of `.lightweight()`, use `.custom()` with transformation logic
2. **Temporary Properties**: Keep old property temporarily, copy data, then remove

## Current Implementation

Right now, we have:
- `SpellPlaySchemaV1_0_0` - Initial schema with SpellingTest, Word, PracticeSession
- Models are the "current" versions referenced by V1_0_0
- When you change models, create V2_0_0 that references the updated models

