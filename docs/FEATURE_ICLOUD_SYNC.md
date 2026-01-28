# iCloud Data Synchronization - Implementation Plan

## Overview

Implement iCloud CloudKit synchronization to sync spelling tests, statistics, game progress, and future model extensions across all devices signed in to the same iCloud account.

## Recommended Approach: SwiftData + CloudKit

Since the app already uses **SwiftData**, the most futureproof approach is to use its built-in CloudKit integration. This provides:

- Automatic sync with minimal code changes
- Apple-managed conflict resolution (last-writer-wins)
- No third-party dependencies
- Works across all Apple devices (iPhone, iPad, Mac)

---

## Phase 1: Enable iCloud Capabilities

### Files to Modify

- `Config/WordCraft.entitlements` - Add CloudKit entitlements

### Apple Developer Portal Setup

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to Certificates, Identifiers & Profiles
3. Select your App ID (`com.wordcraft.app`)
4. Enable iCloud capability
5. Create CloudKit container `iCloud.com.wordcraft.app`

### Entitlements to Add

```xml
<!-- iCloud CloudKit for data synchronization -->
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.wordcraft.app</string>
</array>

<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>

<!-- App group for sharing data between extensions (future-proofing) -->
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.wordcraft.app</string>
</array>
```

---

## Phase 2: Configure ModelContainer for CloudKit

### File to Modify

- `SpellPlay/App/WordCraftApp.swift`

### Implementation

Update `ModelConfiguration` to use CloudKit:

```swift
var modelContainer: ModelContainer = {
    let migrationPlan = WordCraftMigrationPlan.self
    let schema = Schema(CurrentSchema.models)
    
    // Configure for CloudKit sync
    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        cloudKitDatabase: .private("iCloud.com.wordcraft.app")
    )
    
    do {
        return try ModelContainer(
            for: schema,
            migrationPlan: migrationPlan,
            configurations: [modelConfiguration]
        )
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
```

**Note:** This is the core change - SwiftData handles sync automatically after this!

---

## Phase 3: Create CloudSyncService (Optional but Recommended)

### New File

- `SpellPlay/Services/CloudSyncService.swift`

### Purpose

- Monitor iCloud account status
- Track sync state (idle, syncing, synced, error)
- Provide UI feedback to users
- Handle account changes gracefully

### Key Components

```swift
/// Represents the current synchronization state
enum SyncStatus: Equatable, Sendable {
    case idle
    case syncing
    case synced
    case error(String)
    case noAccount
    case restricted
    case disabled
}

@MainActor
@Observable
final class CloudSyncService {
    private(set) var syncStatus: SyncStatus = .idle
    private(set) var lastSyncDate: Date?
    private(set) var isCloudAvailable: Bool = false
    
    // Check CKContainer.accountStatus()
    // Listen for CKAccountChanged notifications
    // Provide helper for ModelConfiguration
}
```

### Features

- `checkAccountStatus()` - Verify iCloud availability
- `refreshSync()` - Manual sync trigger
- Account change monitoring via `NotificationCenter`
- Static helper for creating CloudKit-enabled `ModelConfiguration`

---

## Phase 4: Add Sync Status UI

### New File

- `SpellPlay/Components/SyncStatusView.swift`

### Purpose

Visual indicator showing current sync status to users.

### UI States

| State | Icon | Color | Message |
|-------|------|-------|---------|
| Synced | `checkmark.icloud` | Green | All data synced |
| Syncing | `arrow.triangle.2.circlepath.icloud` | Blue | Syncing... |
| No Account | `person.crop.circle.badge.xmark` | Orange | Sign in to iCloud |
| Error | `exclamationmark.icloud` | Red | Sync error |
| Restricted | `xmark.icloud` | Orange | iCloud restricted |

### Components

1. **SyncStatusView** - Compact toolbar indicator (tappable)
2. **SyncStatusDetailView** - Sheet with full status info and refresh button

### Integration Points

- `ParentHomeView` - Add to navigation bar leading items
- `ChildHomeView` - Add to navigation bar

---

## Phase 5: Model Compatibility Verification

### Current Models - Already Compatible ✅

| Model | CloudKit Ready | Notes |
|-------|---------------|-------|
| `SpellingTest` | ✅ | Has inverse relationship with Word |
| `Word` | ✅ | Has inverse relationship with SpellingTest |
| `PracticeSession` | ✅ | All Codable properties |
| `UserProgress` | ✅ | All Codable properties |

### CloudKit Model Requirements

For future model additions, follow these rules:

1. **Relationships must have inverses**
   ```swift
   // Parent model
   @Relationship(deleteRule: .cascade)
   var children: [Child] = []
   
   // Child model
   @Relationship(deleteRule: .nullify, inverse: \Parent.children)
   var parent: Parent?
   ```

2. **New properties should be optional or have defaults**
   ```swift
   // Good - optional
   var newFeature: String?
   
   // Good - default value
   var newCounter: Int = 0
   ```

3. **Use only Codable types**
   - Primitives: `String`, `Int`, `Double`, `Bool`, `Date`, `UUID`, `Data`
   - Collections: `Array`, `Dictionary` (with Codable elements)
   - Custom types: Must conform to `Codable`

4. **Unique constraints are advisory**
   - CloudKit treats `@Attribute(.unique)` as advisory
   - Duplicates may temporarily exist during sync
   - App should handle gracefully

---

## Phase 6: Testing Strategy

### Simulator Testing

1. Sign in to iCloud in Simulator Settings
2. Use two simulators with same Apple ID
3. Create test on Simulator A
4. Verify appearance on Simulator B

### Device Testing

1. Install on two physical devices
2. Sign in to same iCloud account on both
3. Create spelling test on Device A
4. Verify sync to Device B (may take 15-30 seconds)

### CloudKit Dashboard

Monitor sync at [CloudKit Dashboard](https://icloud.developer.apple.com):
- View records in private database
- Check schema deployment
- Debug sync issues

---

## Implementation Effort Estimate

| Phase | Effort | Files Changed |
|-------|--------|---------------|
| 1. Entitlements | 5 min | 1 file |
| 2. ModelContainer | 5 min | 1 file |
| 3. CloudSyncService | 30 min | 1 new file |
| 4. Sync UI | 20 min | 3 files |
| 5. Model verification | 5 min | Already done |
| 6. Testing | 30 min | N/A |

**Total: ~1.5-2 hours**

---

## Data That Will Sync

Once implemented, the following data syncs automatically:

| Data Type | Model | Syncs |
|-----------|-------|-------|
| Spelling Tests | `SpellingTest` | ✅ |
| Words in Tests | `Word` | ✅ |
| Practice History | `PracticeSession` | ✅ |
| Points & Level | `UserProgress` | ✅ |
| Achievements | `UserProgress.unlockedAchievements` | ✅ |
| Streaks | `PracticeSession` (derived) | ✅ |

---

## Future Extensions

### Already Supported by This Architecture

- **Statistics sync** - Works automatically with `UserProgress`
- **Practice session history** - Works automatically with `PracticeSession`
- **New models** - Just add to schema, CloudKit syncs automatically
- **Game progress** - Add new model, follows same patterns

### Potential Future Enhancements

1. **Family Sharing** - Use `cloudKitDatabase: .shared` for shared spelling tests between family members

2. **Push Notifications** - CloudKit can notify of remote changes for instant sync

3. **Offline Indicator** - Show when device is offline, queue changes

4. **Conflict Resolution UI** - For advanced cases, show merge options to users

5. **Selective Sync** - Allow users to choose what syncs

---

## Troubleshooting Guide

### Data Not Syncing

1. Check iCloud account status in device Settings
2. Verify CloudKit container exists in Developer Portal
3. Check network connectivity
4. Review device Console for CloudKit errors
5. Ensure both devices use same Apple ID

### Duplicate Records

- Normal during sync conflicts
- SwiftData resolves automatically
- If persistent, check unique constraint handling

### Schema Mismatch Errors

When updating models after initial release:
1. Add new schema version to `SchemaVersions.swift`
2. Use lightweight migration
3. Make new properties optional with defaults

### "iCloud Not Available" on Simulator

1. Open Simulator → Settings → Sign in to Apple ID
2. Enable iCloud Drive
3. Restart the app

---

## Security Considerations

- All data encrypted in transit (TLS)
- Data encrypted at rest on iCloud servers
- User controls via iCloud settings
- No cross-account access possible
- Private database = user-specific data only

