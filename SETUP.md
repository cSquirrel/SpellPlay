# SpellPlay Setup Instructions

## Quick Start

1. **Create New Xcode Project**
   - Open Xcode
   - File → New → Project
   - Choose "iOS" → "App"
   - Product Name: `SpellPlay`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData** (important!)
   - Minimum Deployment: **iOS 17.0**

2. **Replace Default Files**
   - Delete the default `ContentView.swift` and `SpellPlayApp.swift` (if they exist)
   - Copy all files from the `SpellPlay/` directory into your Xcode project
   - Maintain the folder structure:
     ```
     SpellPlay/
     ├── App/
     ├── Models/
     ├── Features/
     │   ├── Parent/
     │   └── Child/
     ├── Services/
     ├── Components/
     └── Utilities/
     ```

3. **Add Files to Target**
   - Select all Swift files in the Project Navigator
   - In File Inspector (right panel), ensure "SpellPlay" target is checked
   - All files should be included in the target

4. **Configure Build Settings**
   - Select the project in Project Navigator
   - Select "SpellPlay" target
   - General tab → Deployment Info → iOS 17.0
   - Build Settings → Swift Language Version → Swift 5.9

5. **Build and Run**
   - Product → Build (⌘B)
   - Product → Run (⌘R)

## Important Notes

- **SwiftData**: The project uses SwiftData for persistence. Ensure you selected "SwiftData" when creating the project, or manually add SwiftData framework.
- **iOS 17.0+**: Required for SwiftData support
- **No Dependencies**: All features use native iOS frameworks only

## Troubleshooting

### "Cannot find type X in scope" errors
- These are expected if files aren't in an Xcode project yet
- Once all files are added to the Xcode project target, these will resolve automatically
- Ensure all files are in the same target

### SwiftData not found
- Ensure you created the project with SwiftData enabled
- Or manually add SwiftData framework in Build Phases → Link Binary With Libraries

### Build errors
- Clean build folder: Product → Clean Build Folder (⇧⌘K)
- Delete derived data if needed
- Ensure minimum deployment is iOS 17.0

## Project Structure Verification

After setup, verify you have:
- ✅ All model files (UserRole, Word, SpellingTest, PracticeSession)
- ✅ App entry point (SpellPlayApp.swift)
- ✅ All feature views (Parent and Child)
- ✅ Services (TTS, Streak)
- ✅ UI Components
- ✅ Utilities (Constants, Extensions)

## Testing the App

1. **First Launch**: Should show role selection screen
2. **Parent Mode**: Create a test with words
3. **Child Mode**: Select test and practice
4. **Verify**: 
   - TTS pronunciation works
   - Streak tracking works
   - Data persists after app restart

