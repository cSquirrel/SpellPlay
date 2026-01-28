# CloudKit Sync Debug Logging Guide

## Viewing App Logs

### Method 1: Console.app (macOS)

1. **Open Console.app** (Applications → Utilities → Console)
2. **Select your Mac** in the sidebar
3. **Filter by subsystem:**
   - In the search bar, enter: `subsystem == "com.wordcraft.app"`
   - Or filter by category: `category == "CloudSync"`

### Method 2: Xcode Console

1. **Run the app from Xcode** (⌘R)
2. **View logs in the Debug Area** (⌘⇧Y)
3. **Filter:** Type "CloudSync" or "CloudKit" in the filter box

### Method 3: Terminal (simulator)

```bash
# Stream logs for your app
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.wordcraft.app" AND category == "CloudSync"'

# Or view all CloudKit-related logs
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.apple.cloudkit"'
```

### Method 4: Device Console (physical device)

1. Connect device via USB
2. Open **Console.app**
3. Select your device in sidebar
4. Filter by `subsystem == "com.wordcraft.app"`

## Log Messages You'll See

### CloudSyncService Logs

| Emoji | Meaning | Example |
|-------|---------|---------|
| 🚀 | Service initialization | `CloudSyncService initialized` |
| 🔍 | Checking account status | `Checking iCloud account status...` |
| ✅ | Success | `iCloud account available - CloudKit sync enabled` |
| ⚠️ | Warning | `No iCloud account signed in` |
| ❌ | Error | `Error checking iCloud status` |
| 🔄 | Manual refresh | `Manual sync refresh triggered` |
| 👂 | Monitoring started | `Started monitoring iCloud account changes` |
| 📢 | Account change detected | `iCloud account changed notification received` |

## Enabling CloudKit Verbose Logging

For even more detailed CloudKit sync information, enable verbose logging:

### Option 1: Xcode Scheme Environment Variables

1. **Edit Scheme** (⌘<)
2. **Run → Arguments → Environment Variables**
3. **Add:**
   ```
   Name: CK_LOG_LEVEL
   Value: 3
   ```
   ```
   Name: CK_LOG_CATEGORY
   Value: all
   ```

### Option 2: Terminal (before launching)

```bash
export CK_LOG_LEVEL=3
export CK_LOG_CATEGORY=all
```

### Option 3: Simulator Launch Arguments

Add to Xcode scheme:
- **Run → Arguments → Arguments Passed On Launch:**
  ```
  -CKLogLevel 3
  ```

## SwiftData CloudKit Sync Events

SwiftData automatically logs CloudKit operations. Look for:

- `com.apple.cloudkit` subsystem logs
- Messages containing "CloudKit" or "sync"
- Database operation logs

## Common Log Patterns

### Successful Sync
```
✅ iCloud account available - CloudKit sync enabled
🚀 CloudSyncService initialized with container: iCloud.com.wordcraft.app
```

### No Account
```
⚠️ No iCloud account signed in - sync disabled
```

### Account Changed
```
📢 iCloud account changed notification received - rechecking status
🔍 Checking iCloud account status...
✅ iCloud account available - CloudKit sync enabled
```

## Debugging Tips

1. **Check account status first** - Look for the 🔍 emoji logs
2. **Monitor account changes** - Watch for 📢 notifications
3. **Verify container ID** - Should match `iCloud.com.wordcraft.app`
4. **Check for errors** - Look for ❌ emoji logs

## Filtering Logs in Console.app

**Subsystem filter:**
```
subsystem == "com.wordcraft.app"
```

**Category filter:**
```
category == "CloudSync"
```

**Combined filter:**
```
subsystem == "com.wordcraft.app" AND category == "CloudSync"
```

**CloudKit system logs:**
```
subsystem == "com.apple.cloudkit"
```

## Real-time Monitoring

To watch logs in real-time while testing:

```bash
# Terminal command for simulator
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.wordcraft.app" OR subsystem == "com.apple.cloudkit"' --style compact
```

This will show all CloudKit and app sync-related logs as they happen.

