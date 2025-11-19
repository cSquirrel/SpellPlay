# Data Migration Strategy Implementation

## Overview
Implement a comprehensive SwiftData migration system to handle schema changes safely, preserve user data across app updates, and provide infrastructure for future model evolution without data loss.

## Current State

### Current Implementation
- Basic `ModelContainer` initialization with no versioning
- No migration handling - schema changes would cause crashes or data loss
- Models: `SpellingTest`, `Word`, `PracticeSession`
- Uses default SwiftData storage location

### Risks Without Migration
- App crashes on launch if schema changes
- Data loss when adding/removing/modifying model properties
- No way to handle property type changes
- No rollback mechanism

## Migration Strategy

### 1. Schema Versioning
- Define schema versions (v1, v2, v3, etc.)
- Track current schema version in app metadata
- Use `ModelConfiguration` with explicit schema versions
- Store version information for migration tracking

### 2. Migration Types to Handle

#### Additive Changes (Safest)
- Adding new optional properties
- Adding new models
- Adding new relationships

#### Modifying Changes (Require Migration)
- Renaming properties
- Changing property types
- Making properties required/optional
- Removing properties (with data preservation)

#### Structural Changes (Complex)
- Changing relationships
- Splitting/merging models
- Changing unique constraints

### 3. Migration Implementation Approach

#### Option A: SwiftData Automatic Migration (Preferred)
- Use `ModelConfiguration` with migration options
- Leverage SwiftData's built-in migration for simple cases
- Handle complex migrations manually

#### Option B: Manual Migration
- Create migration service to transform data
- Read old schema, transform, write to new schema
- More control but more complex

### 4. Migration Service Architecture

Create a `MigrationService` that:
- Detects current schema version
- Compares with app's expected version
- Executes appropriate migration steps
- Validates migration success
- Handles migration failures gracefully

## Implementation Plan

### Phase 1: Infrastructure Setup
1. Create schema version tracking system
2. Create `MigrationService` class
3. Add version metadata to app
4. Update `ModelContainer` initialization to support versioning

### Phase 2: Migration Framework
1. Define migration protocol/interface
2. Create migration step system
3. Implement migration validation
4. Add error handling and rollback support

### Phase 3: Example Migrations
1. Create example v1 → v2 migration (add new property)
2. Document migration patterns
3. Create migration testing utilities

## Files to Create/Modify

1. **WordCraft/Services/MigrationService.swift** (NEW) - Core migration service
2. **WordCraft/App/WordCraftApp.swift** - Update ModelContainer initialization with versioning
3. **WordCraft/Models/SchemaVersion.swift** (NEW) - Schema version tracking model
4. **WordCraft/Utilities/MigrationHelpers.swift** (NEW) - Migration utility functions
5. **docs/MIGRATION_GUIDE.md** (NEW) - Documentation for future migrations

## Migration Scenarios to Support

### Scenario 1: Adding New Property
- Example: Add `difficulty` property to `SpellingTest`
- Strategy: Automatic migration (new optional property)

### Scenario 2: Renaming Property
- Example: Rename `lastPracticed` to `lastPracticeDate`
- Strategy: Manual migration with property mapping

### Scenario 3: Changing Property Type
- Example: Change `streak` from `Int` to `Int64`
- Strategy: Manual migration with type conversion

### Scenario 4: Removing Property
- Example: Remove deprecated `notes` property
- Strategy: Data loss acceptable, document in migration

### Scenario 5: Adding New Model
- Example: Add `TestCategory` model
- Strategy: Automatic (new model doesn't affect existing)

## Best Practices

1. **Always Test Migrations**
   - Test with real data structures
   - Test rollback scenarios
   - Test on different iOS versions

2. **Incremental Migrations**
   - Support multiple version jumps (v1 → v3)
   - Chain migrations if needed
   - Validate each step

3. **Data Preservation**
   - Never lose user data unnecessarily
   - Provide migration preview if possible
   - Log migration steps for debugging

4. **Error Handling**
   - Graceful degradation on migration failure
   - User notification for critical migrations
   - Fallback to data export/import if needed

5. **Documentation**
   - Document each schema version
   - Document migration steps
   - Maintain migration history

## Migration Testing Strategy

1. **Unit Tests**
   - Test migration logic in isolation
   - Test with sample data
   - Test error scenarios

2. **Integration Tests**
   - Test full migration flow
   - Test with production-like data
   - Test rollback mechanisms

3. **Manual Testing**
   - Test on device with existing data
   - Test multiple version jumps
   - Test edge cases

## Future Considerations

- CloudKit sync compatibility (if added later)
- Cross-device migration
- Data export/import for user-initiated migrations
- Migration performance optimization

## Implementation Todos

1. **schema-version-tracking** - Create SchemaVersion model and version tracking system to track current schema version in SwiftData
2. **migration-service** - Create MigrationService class with version detection, migration execution, and validation logic
3. **model-container-versioning** - Update WordCraftApp ModelContainer initialization to support schema versioning and migration
4. **migration-helpers** - Create MigrationHelpers utility functions for common migration patterns (property mapping, type conversion, etc.)
5. **example-migration** - Create example v1 → v2 migration (e.g., adding new optional property) to demonstrate migration pattern
6. **migration-documentation** - Create docs/MIGRATION_GUIDE.md with documentation on how to create new migrations, migration patterns, and best practices

