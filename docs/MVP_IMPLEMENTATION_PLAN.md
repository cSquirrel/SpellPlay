# SpellPlay iOS MVP Implementation Plan

## Project Structure

Create a new iOS Xcode project with the following architecture:
- **Platform**: iOS 17.0+ (for SwiftData support)
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Architecture**: MVVM pattern
- **Data Persistence**: SwiftData (local storage)
- **TTS**: AVSpeechSynthesizer (native iOS)

## Core Data Models

**Location**: `Models/`

1. **SpellingTest.swift** - Main test model
   - Properties: id, name, words (array), createdAt, lastPracticed
   - SwiftData @Model

2. **Word.swift** - Individual word model
   - Properties: id, text, createdAt
   - SwiftData @Model with relationship to SpellingTest

3. **PracticeSession.swift** - Track practice attempts
   - Properties: id, testId, date, wordsAttempted, wordsCorrect, streak
   - SwiftData @Model

4. **UserRole.swift** - Enum for Parent/Kid role selection
   - Cases: parent, child

## App Architecture

**Location**: `App/`

1. **SpellPlayApp.swift** - Main app entry point
   - Initialize SwiftData model container
   - Handle first-launch role selection
   - Navigation structure

2. **AppState.swift** - Global app state
   - Current user role (Parent/Child)
   - Selected test
   - Streak tracking

## Parent Features

**Location**: `Features/Parent/`

1. **ParentHomeView.swift** - Parent dashboard
   - List of all spelling tests
   - "Create New Test" button
   - Edit/delete test options
   - Simple completion stats

2. **CreateTestView.swift** - Test creation form
   - Test name input
   - Word entry (multi-line text field or individual inputs)
   - "Add Word" functionality
   - TTS preview button for each word
   - Save/Cancel actions

3. **EditTestView.swift** - Edit existing test
   - Pre-populated form
   - Add/remove words
   - Update test name

4. **TestListViewModel.swift** - ViewModel for test management
   - CRUD operations for tests
   - SwiftData queries

## Child Features

**Location**: `Features/Child/`

1. **ChildHomeView.swift** - Child dashboard
   - List of available tests
   - Current streak display (visual indicator)
   - "Start Practice" buttons
   - Kid-friendly UI (large buttons, colors, icons)

2. **PracticeView.swift** - Main practice interface
   - Word display
   - Audio play button (prominent, large)
   - Text input field
   - Submit button
   - Progress indicator (word X of Y)
   - Instant feedback (correct/incorrect animations)

3. **PracticeSummaryView.swift** - Session completion screen
   - Score display (X/Y correct)
   - Streak update
   - Celebration animation
   - "Practice Again" / "Back to Tests" buttons

4. **PracticeViewModel.swift** - ViewModel for practice flow
   - Word sequence management
   - Answer validation
   - Score calculation
   - Streak tracking logic
   - TTS integration

## Services

**Location**: `Services/`

1. **TTSService.swift** - Text-to-Speech wrapper
   - AVSpeechSynthesizer integration
   - Play word pronunciation
   - Handle offline/error states
   - Configurable voice settings (child-friendly)

2. **StreakService.swift** - Streak calculation
   - Track daily practice
   - Calculate current streak
   - Reset logic for missed days

## UI Components

**Location**: `Components/`

1. **RoleSelectionView.swift** - First launch screen
   - "I am a Parent" button
   - "I am a Kid" button
   - Simple onboarding text

2. **OnboardingView.swift** - Role-specific onboarding
   - Parent: How to create tests
   - Child: How to practice

3. **WordInputView.swift** - Reusable word entry component
   - Text field with validation
   - Submit button

4. **StreakIndicatorView.swift** - Visual streak display
   - Fire/flame icon with count
   - Animated updates

5. **CelebrationView.swift** - Success animations
   - Confetti effect
   - Success message
   - Emoji celebrations

## Utilities

**Location**: `Utilities/`

1. **Extensions/View+Extensions.swift** - SwiftUI helpers
2. **Extensions/String+Extensions.swift** - String utilities (trim, normalize)
3. **Constants.swift** - App-wide constants (colors, sizes, strings)

## Key Implementation Details

### TTS Integration
- Use AVSpeechSynthesizer with child-friendly voice
- Pre-configure voice settings (rate, pitch, volume)
- Handle audio session interruptions
- Fallback UI if TTS unavailable

### Data Persistence
- SwiftData models with @Query for reactive updates
- ModelContainer initialization in app
- Migration handling for future updates

### Streak Logic
- Track last practice date
- Increment if practiced today
- Reset if gap > 1 day
- Store in PracticeSession model

### UI/UX Requirements
- High contrast colors
- Minimum 44pt touch targets
- Large, readable fonts
- Minimal text for child views
- Clear visual feedback
- Smooth animations

## File Structure

```
SpellPlay/
├── App/
│   ├── SpellPlayApp.swift
│   └── AppState.swift
├── Models/
│   ├── SpellingTest.swift
│   ├── Word.swift
│   ├── PracticeSession.swift
│   └── UserRole.swift
├── Features/
│   ├── Parent/
│   │   ├── ParentHomeView.swift
│   │   ├── CreateTestView.swift
│   │   ├── EditTestView.swift
│   │   └── ViewModels/
│   │       └── TestListViewModel.swift
│   └── Child/
│       ├── ChildHomeView.swift
│       ├── PracticeView.swift
│       ├── PracticeSummaryView.swift
│       └── ViewModels/
│           └── PracticeViewModel.swift
├── Services/
│   ├── TTSService.swift
│   └── StreakService.swift
├── Components/
│   ├── RoleSelectionView.swift
│   ├── OnboardingView.swift
│   ├── WordInputView.swift
│   ├── StreakIndicatorView.swift
│   └── CelebrationView.swift
└── Utilities/
    ├── Extensions/
    │   ├── View+Extensions.swift
    │   └── String+Extensions.swift
    └── Constants.swift
```

## Implementation Order

1. **Phase 1: Foundation** (Days 1-2)
   - Project setup and Xcode configuration
   - Data models (SwiftData)
   - Basic app structure and navigation
   - Role selection flow

2. **Phase 2: Parent Features** (Days 3-5)
   - Test creation UI and logic
   - Test list view
   - Edit/delete functionality
   - Basic stats display

3. **Phase 3: Child Features** (Days 6-8)
   - Practice flow UI
   - TTS integration
   - Answer validation
   - Progress tracking

4. **Phase 4: Gamification** (Days 9-10)
   - Streak calculation and display
   - Celebration animations
   - Practice summary screen

5. **Phase 5: Polish** (Days 11-14)
   - UI/UX refinements
   - Error handling
   - Edge cases (no tests, offline TTS)
   - Testing and bug fixes

## Dependencies

- iOS 17.0+ SDK
- SwiftData framework
- AVFoundation (for TTS)
- SwiftUI framework

## Testing Considerations

- Test with empty state (no tests created)
- Test TTS with various word lengths
- Test streak calculation edge cases
- Test offline scenarios
- Verify data persistence across app launches

## Implementation Todos

1. **setup-project** - Create Xcode project with iOS 17+ target, configure SwiftData, set up basic app structure and navigation
2. **data-models** - Implement SwiftData models: SpellingTest, Word, PracticeSession, UserRole enum
3. **role-selection** - Build RoleSelectionView and onboarding flow for first-time users
4. **parent-home** - Create ParentHomeView with test list, create/edit/delete functionality, and basic stats
5. **create-test** - Build CreateTestView with word entry, TTS preview, and save functionality
6. **tts-service** - Implement TTSService using AVSpeechSynthesizer with child-friendly voice configuration
7. **child-home** - Create ChildHomeView with test selection, streak indicator, and kid-friendly UI
8. **practice-flow** - Build PracticeView with word display, audio playback, text input, validation, and progress tracking
9. **streak-system** - Implement StreakService for daily practice tracking and streak calculation logic
10. **practice-summary** - Create PracticeSummaryView with score display, streak updates, and celebration animations
11. **ui-components** - Build reusable components: CelebrationView, StreakIndicatorView, WordInputView with animations
12. **edge-cases** - Handle edge cases: empty state (no tests), offline TTS fallback, error handling, data persistence verification
13. **polish-testing** - UI/UX refinements, accessibility improvements, testing across devices, bug fixes

