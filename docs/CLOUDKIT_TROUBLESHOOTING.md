# CloudKit Troubleshooting Guide

## Common Errors and Solutions

### Error: "Unable to initialize without an iCloud account (CKAccountStatusNoAccount)"

**Cause:** The simulator or device is not signed in to iCloud.

**Solution:**

#### For Simulator:
1. Open **Simulator** → **Settings** → **Sign in to your [Device]**
2. Sign in with your Apple ID
3. Enable **iCloud Drive** in Settings → [Your Name] → iCloud
4. Restart the app

#### For Physical Device:
1. Open **Settings** → **Sign in to your iPhone/iPad**
2. Sign in with your Apple ID
3. Enable **iCloud Drive** in Settings → [Your Name] → iCloud
4. Restart the app

**Verification:**
- Check the sync status indicator in the app (should show ✅ when signed in)
- Look for log message: `✅ iCloud account available - CloudKit sync enabled`

---

### Warning: "INVALID_PERSONA; It is undefined behavior to look up a container with a persona other than personal"

**Cause:** Simulator-specific warning about CloudKit personas. This is a known simulator quirk.

**Impact:** None - CloudKit will assume "personal" persona automatically.

**Solution:** This warning can be safely ignored. It doesn't affect functionality.

---

### Warning: "CloudKit push notifications require the 'remote-notification' background mode"

**Cause:** Background mode not configured in Info.plist.

**Impact:** CloudKit push notifications won't work (but sync will still work via polling).

**Solution:** Already fixed in `Config/Shared.xcconfig`:
```
INFOPLIST_KEY_UIBackgroundModes = remote-notification
```

**Note:** This is optional - sync works without push notifications, but they enable instant sync when data changes on other devices.

---

### Error: "Failed to stat path" / "Failed to create file" (CoreData errors)

**Cause:** App Group container path issues or permissions.

**Solution:**

1. **Verify App Group is configured:**
   - Check `Config/WordCraft.entitlements` has:
     ```xml
     <key>com.apple.security.application-groups</key>
     <array>
         <string>group.com.wordcraft.app</string>
     </array>
     ```

2. **Verify App Group exists in Developer Portal:**
   - Go to [Apple Developer Portal](https://developer.apple.com)
   - Certificates, Identifiers & Profiles → App Groups
   - Ensure `group.com.wordcraft.app` exists and is enabled for your App ID

3. **Clean build:**
   ```bash
   # In Xcode: Product → Clean Build Folder (⇧⌘K)
   # Or terminal:
   xcodebuild clean -workspace SpellPlay.xcworkspace -scheme SpellPlay
   ```

4. **Delete app and reinstall:**
   - Remove app from simulator/device
   - Rebuild and reinstall

---

### Error: "CloudKit integration failed" during setup

**Possible Causes:**

1. **No iCloud account** (most common)
   - See solution above

2. **CloudKit container not created**
   - Verify container `iCloud.com.wordcraft.app` exists in Developer Portal
   - Check CloudKit Dashboard shows the container

3. **Entitlements mismatch**
   - Verify `Config/WordCraft.entitlements` matches Developer Portal configuration
   - Ensure App ID has iCloud capability enabled

4. **Network issues**
   - Check internet connection
   - Verify simulator/device can reach iCloud servers

---

## Debugging Steps

### 1. Check iCloud Account Status

**In App:**
- Look for sync status indicator in UI
- Tap to see detailed status

**In Logs:**
```bash
# Filter for CloudSync logs
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.wordcraft.app" AND category == "CloudSync"'
```

Look for:
- `✅ iCloud account available` = Good
- `⚠️ No iCloud account signed in` = Need to sign in
- `❌ Error checking iCloud status` = Problem

### 2. Verify CloudKit Container

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com)
2. Select container `iCloud.com.wordcraft.app`
3. Check "Development" environment is accessible
4. Verify schema shows your models

### 3. Check Entitlements

**Verify entitlements file:**
```bash
cat Config/WordCraft.entitlements
```

Should contain:
- `com.apple.developer.icloud-container-identifiers`
- `com.apple.developer.icloud-services` with `CloudKit`
- `com.apple.security.application-groups`

**Verify in Xcode:**
1. Select project → Target → Signing & Capabilities
2. Check iCloud capability is enabled
3. Verify container identifier matches

### 4. Test Sync

**On Simulator:**
1. Sign in to iCloud on Simulator A
2. Create a spelling test
3. Sign in to same account on Simulator B
4. Wait 15-30 seconds
5. Test should appear on Simulator B

**On Device:**
1. Install on Device A and Device B
2. Sign in to same iCloud account on both
3. Create test on Device A
4. Wait 15-30 seconds
5. Test should appear on Device B

---

## Log Analysis

### Successful Sync Setup
```
🚀 CloudSyncService initialized with container: iCloud.com.wordcraft.app
🔍 Checking iCloud account status...
✅ iCloud account available - CloudKit sync enabled
👂 Started monitoring iCloud account changes
```

### No Account
```
🔍 Checking iCloud account status...
⚠️ No iCloud account signed in - sync disabled
```

### Account Changed
```
📢 iCloud account changed notification received - rechecking status
🔍 Checking iCloud account status...
✅ iCloud account available - CloudKit sync enabled
```

---

## Still Having Issues?

1. **Check CloudKit Dashboard** for errors
2. **Review device Console** for detailed CloudKit logs
3. **Verify network connectivity**
4. **Try signing out and back into iCloud**
5. **Clean and rebuild** the project
6. **Delete app data** and reinstall

For more details, see `docs/FEATURE_ICLOUD_SYNC.md` and `docs/CLOUDKIT_DEBUG_LOGGING.md`.

