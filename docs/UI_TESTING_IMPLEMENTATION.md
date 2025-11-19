# UI Testing Implementation Plan

## Overview
Implement comprehensive UI tests for WordCraft app using XCTest and XCUIApplication following the **Page Object Model (POM)** architecture pattern. Tests will cover critical user flows, edge cases, error scenarios, and data persistence across both Parent and Child roles.

## Page Object Model (POM) Architecture

### What is Page Object Model?
The Page Object Model is a design pattern that:
- **Encapsulates UI elements and actions** for each screen in a dedicated class
- **Separates test logic from UI interaction details**
- **Improves test maintainability** - when UI changes, only the Page Object needs updating
- **Enhances test readability** - tests read like user stories
- **Makes tests more resilient** - centralized element identification

### Key Principles
1. **One Page Object per Screen**: Each screen/view has a corresponding Page Object class
2. **Encapsulation**: Page Objects contain element queries, actions, and verification methods
3. **No Direct UI Access**: Tests interact only with Page Objects, never directly with XCUIApplication
4. **Fluent Interface**: Page Objects return other Page Objects for navigation (method chaining)
5. **Reusability**: Common functionality is shared through a base class

### Benefits for WordCraft
- **Maintainability**: When UI elements change (e.g., button labels, accessibility IDs), update only the Page Object
- **Readability**: Tests read naturally: `parentHomePage.tapCreateTest().enterTestName("My Test").tapSave()`
- **Consistency**: All tests use the same interaction patterns
- **Debugging**: Easier to identify which screen has issues

## Test Structure

### File Organization

**Page Objects** (located in `WordCraftUITests/PageObjects/`):
- `BasePage.swift` - Base class with common functionality for all page objects
- `RoleSelectionPage.swift` - Role selection screen
- `OnboardingPage.swift` - Onboarding screen
- `ParentHomePage.swift` - Parent dashboard
- `CreateTestPage.swift` - Test creation form
- `EditTestPage.swift` - Test editing form
- `ChildHomePage.swift` - Child dashboard
- `PracticePage.swift` - Practice session screen
- `RoundTransitionPage.swift` - Round transition screen
- `PracticeSummaryPage.swift` - Practice completion summary
- `RoleSwitcherPage.swift` - Role switching modal

**Test Files** (located in `WordCraftUITests/`):
- `RoleSelectionTests.swift` - Role selection and onboarding flows
- `ParentFlowTests.swift` - Parent test management (create, edit, delete)
- `ChildFlowTests.swift` - Child practice flows and iterative rounds
- `EdgeCaseTests.swift` - Empty states, error handling, data persistence

**Helpers** (located in `WordCraftUITests/Helpers/`):
- `TestHelpers.swift` - Reusable test utilities and setup helpers

## Page Object Implementation Details

### Base Page Object
**File**: `WordCraftUITests/PageObjects/BasePage.swift`

All page objects inherit from `BasePage`, which provides common functionality:

```swift
class BasePage {
    let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    // Wait for element to appear
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5.0) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    // Wait for element to disappear
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5.0) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
    
    // Safely tap element if it exists
    func tapIfExists(_ element: XCUIElement) {
        if element.waitForExistence(timeout: 2.0) {
            element.tap()
        }
    }
    
    // Check if element is visible
    func isElementVisible(_ element: XCUIElement) -> Bool {
        return element.exists && element.isHittable
    }
    
    // Scroll to element if needed
    func scrollToElement(_ element: XCUIElement) {
        if !element.isHittable {
            app.swipeUp()
        }
    }
}
```

### Page Object Structure

Each page object follows this consistent structure:

1. **Properties**: XCUIElement queries for UI elements (computed properties)
2. **Initializer**: Takes `XCUIApplication` instance, calls `super.init(app:)`
3. **Action Methods**: Perform user interactions, return Page Objects for navigation (fluent interface)
4. **Verification Methods**: Check UI state, return Bool
5. **Query Methods**: Get data from UI, return values (String, Int, etc.)

**Example Page Object**:
```swift
class ParentHomePage: BasePage {
    // MARK: - Properties (UI Element Queries)
    var createTestButton: XCUIElement {
        app.buttons["Create New Test"]
    }
    
    var testCards: XCUIElementQuery {
        app.otherElements.matching(identifier: "TestCard")
    }
    
    var emptyStateText: XCUIElement {
        app.staticTexts["No Tests Available"]
    }
    
    var settingsButton: XCUIElement {
        app.buttons["Settings"]
    }
    
    // MARK: - Initializer
    override init(app: XCUIApplication) {
        super.init(app: app)
    }
    
    // MARK: - Action Methods (Return Page Objects)
    func tapCreateTest() -> CreateTestPage {
        createTestButton.tap()
        return CreateTestPage(app: app)
    }
    
    func tapTestCard(named name: String) -> EditTestPage {
        testCards.containing(.staticText, identifier: name).firstMatch.tap()
        return EditTestPage(app: app)
    }
    
    func tapSettings() -> RoleSwitcherPage {
        settingsButton.tap()
        return RoleSwitcherPage(app: app)
    }
    
    // MARK: - Verification Methods
    func verifyTestExists(named name: String) -> Bool {
        return testCards.containing(.staticText, identifier: name).firstMatch.exists
    }
    
    func verifyEmptyState() -> Bool {
        return waitForElement(emptyStateText)
    }
    
    // MARK: - Query Methods
    func getTestCount() -> Int {
        return testCards.count
    }
}
```

## Detailed Page Object Specifications

### 1. RoleSelectionPage
**File**: `WordCraftUITests/PageObjects/RoleSelectionPage.swift`

**Properties**:
- `parentButton: XCUIElement` - "I am a Parent" button
- `childButton: XCUIElement` - "I am a Kid" button
- `welcomeText: XCUIElement` - "Welcome to WordCraft!" text

**Methods**:
- `tapParentButton() -> OnboardingPage` - Tap parent button, return onboarding page
- `tapChildButton() -> OnboardingPage` - Tap child button, return onboarding page
- `verifyWelcomeText() -> Bool` - Verify welcome message is displayed

### 2. OnboardingPage
**File**: `WordCraftUITests/PageObjects/OnboardingPage.swift`

**Properties**:
- `dismissButton: XCUIElement` - Dismiss/close button
- `onboardingText: XCUIElement` - Onboarding content text

**Methods**:
- `dismiss() -> ParentHomePage` or `ChildHomePage` - Dismiss onboarding, return appropriate home page
- `verifyOnboardingContent(for role: UserRole) -> Bool` - Verify role-specific content is displayed

### 3. ParentHomePage
**File**: `WordCraftUITests/PageObjects/ParentHomePage.swift`

**Properties**:
- `createTestButton: XCUIElement` - "Create New Test" button
- `testCards: XCUIElementQuery` - Query for all test cards
- `emptyStateText: XCUIElement` - Empty state message
- `settingsButton: XCUIElement` - Settings/gear button

**Methods**:
- `tapCreateTest() -> CreateTestPage` - Navigate to test creation
- `tapTestCard(named: String) -> EditTestPage` - Open test for editing
- `deleteTest(named: String) -> Self` - Delete a test (swipe or button)
- `verifyTestExists(named: String) -> Bool` - Check if test is in list
- `verifyEmptyState() -> Bool` - Check if empty state is shown
- `tapSettings() -> RoleSwitcherPage` - Open role switcher
- `getTestCount() -> Int` - Get number of tests displayed

### 4. CreateTestPage
**File**: `WordCraftUITests/PageObjects/CreateTestPage.swift`

**Properties**:
- `testNameField: XCUIElement` - Test name text field
- `wordTextEditor: XCUIElement` - Word entry text editor
- `addWordsButton: XCUIElement` - "Add Words" button
- `saveButton: XCUIElement` - Save button in toolbar
- `cancelButton: XCUIElement` - Cancel button in toolbar
- `wordList: XCUIElementQuery` - List of added words

**Methods**:
- `enterTestName(_ name: String) -> Self` - Enter test name (fluent interface)
- `enterWords(_ words: String) -> Self` - Enter words in text editor
- `tapAddWords() -> Self` - Tap "Add Words" button
- `tapTTSButton(for word: String) -> Self` - Tap speaker button for specific word
- `removeWord(_ word: String) -> Self` - Remove word from list
- `tapSave() -> ParentHomePage` - Save test and return to home
- `tapCancel() -> ParentHomePage` - Cancel and return to home
- `verifyWordExists(_ word: String) -> Bool` - Check if word is in list
- `verifyAddWordsButtonEnabled() -> Bool` - Check if "Add Words" is enabled

### 5. EditTestPage
**File**: `WordCraftUITests/PageObjects/EditTestPage.swift`

**Properties**:
- `testNameField: XCUIElement` - Test name text field
- `wordList: XCUIElementQuery` - List of words
- `addWordsButton: XCUIElement` - "Add Words" button
- `saveButton: XCUIElement` - Save button
- `cancelButton: XCUIElement` - Cancel button

**Methods**:
- `updateTestName(_ name: String) -> Self` - Update test name
- `addWords(_ words: String) -> Self` - Add new words to test
- `removeWord(_ word: String) -> Self` - Remove word from test
- `tapTTSButton(for word: String) -> Self` - Preview word pronunciation
- `tapSave() -> ParentHomePage` - Save changes
- `tapCancel() -> ParentHomePage` - Cancel changes
- `verifyTestName(_ name: String) -> Bool` - Verify test name matches
- `verifyWordExists(_ word: String) -> Bool` - Verify word is in list

### 6. ChildHomePage
**File**: `WordCraftUITests/PageObjects/ChildHomePage.swift`

**Properties**:
- `testCards: XCUIElementQuery` - Query for all test cards
- `emptyStateText: XCUIElement` - Empty state message
- `streakIndicator: XCUIElement` - Streak display component
- `settingsButton: XCUIElement` - Settings button

**Methods**:
- `tapTestCard(named: String) -> PracticePage` - Start practice for a test
- `verifyTestExists(named: String) -> Bool` - Check if test is available
- `verifyEmptyState() -> Bool` - Check if empty state is shown
- `verifyStreakDisplayed(_ streak: Int) -> Bool` - Verify streak value
- `tapSettings() -> RoleSwitcherPage` - Open role switcher

### 7. PracticePage
**File**: `WordCraftUITests/PageObjects/PracticePage.swift`

**Properties**:
- `currentWordText: XCUIElement` - Displayed word text
- `wordInputField: XCUIElement` - Answer input field
- `submitButton: XCUIElement` - Submit button
- `speakerButton: XCUIElement` - TTS playback button
- `progressText: XCUIElement` - Progress indicator text
- `feedbackMessage: XCUIElement` - Correct/incorrect feedback
- `roundIndicator: XCUIElement` - Round number display

**Methods**:
- `enterAnswer(_ answer: String) -> Self` - Type answer in input field
- `tapSubmit() -> Self` - Submit answer
- `tapSpeaker() -> Self` - Play word audio
- `verifyCurrentWord(_ word: String) -> Bool` - Verify displayed word
- `verifyProgress(_ expected: String) -> Bool` - Verify progress text
- `verifyCorrectFeedback() -> Bool` - Verify positive feedback shown
- `verifyIncorrectFeedback() -> Bool` - Verify negative feedback shown
- `waitForRoundTransition() -> RoundTransitionPage` - Wait for round transition screen
- `waitForSummary() -> PracticeSummaryPage` - Wait for practice summary
- `isInputEnabled() -> Bool` - Check if input field is enabled

### 8. RoundTransitionPage
**File**: `WordCraftUITests/PageObjects/RoundTransitionPage.swift`

**Properties**:
- `roundTitle: XCUIElement` - Round number/title text
- `misspelledWordsList: XCUIElementQuery` - List of misspelled words
- `startRoundButton: XCUIElement` - "Start Round" button

**Methods**:
- `verifyRoundNumber(_ round: Int) -> Bool` - Verify round number displayed
- `verifyMisspelledWordExists(_ word: String) -> Bool` - Check if word is in list
- `getMisspelledWordsCount() -> Int` - Get count of misspelled words
- `tapStartRound() -> PracticePage` - Start next round

### 9. PracticeSummaryPage
**File**: `WordCraftUITests/PageObjects/PracticeSummaryPage.swift`

**Properties**:
- `roundsCompletedText: XCUIElement` - Rounds completed display
- `streakText: XCUIElement` - Streak value display
- `practiceAgainButton: XCUIElement` - "Practice Again" button
- `backToTestsButton: XCUIElement` - "Back to Tests" button

**Methods**:
- `verifyRoundsCompleted(_ rounds: Int) -> Bool` - Verify rounds count
- `verifyStreak(_ streak: Int) -> Bool` - Verify streak value
- `tapPracticeAgain() -> PracticePage` - Start new practice session
- `tapBackToTests() -> ChildHomePage` - Return to test list

### 10. RoleSwitcherPage
**File**: `WordCraftUITests/PageObjects/RoleSwitcherPage.swift`

**Properties**:
- `parentButton: XCUIElement` - Switch to parent button
- `childButton: XCUIElement` - Switch to child button
- `dismissButton: XCUIElement` - Dismiss button

**Methods**:
- `switchToParent() -> ParentHomePage` - Switch to parent role
- `switchToChild() -> ChildHomePage` - Switch to child role
- `dismiss() -> ParentHomePage` or `ChildHomePage` - Dismiss without switching

## Test Implementation Details

### 1. Role Selection and Onboarding Tests
**File**: `WordCraftUITests/RoleSelectionTests.swift`

**Test Cases**:
- `testRoleSelection_ParentFlow` - Verify parent button selection shows onboarding
- `testRoleSelection_ChildFlow` - Verify child button selection shows onboarding
- `testOnboarding_ParentDismissal` - Verify parent onboarding can be dismissed and doesn't show again
- `testOnboarding_ChildDismissal` - Verify child onboarding can be dismissed and doesn't show again
- `testRoleSwitching` - Verify role switcher allows switching between parent and child roles

**Example Test**:
```swift
func testRoleSelection_ParentFlow() {
    let app = XCUIApplication()
    app.launch()
    
    let roleSelectionPage = RoleSelectionPage(app: app)
    XCTAssertTrue(roleSelectionPage.verifyWelcomeText())
    
    let onboardingPage = roleSelectionPage.tapParentButton()
    XCTAssertTrue(onboardingPage.verifyOnboardingContent(for: .parent))
    
    let parentHomePage = onboardingPage.dismiss()
    XCTAssertTrue(parentHomePage.verifyEmptyState())
}
```

**Key Assertions**:
- Role selection buttons are visible and tappable
- Onboarding appears after first role selection
- Onboarding doesn't reappear after completion
- Parent home view appears after parent onboarding
- Child home view appears after child onboarding

### 2. Parent Flow Tests
**File**: `WordCraftUITests/ParentFlowTests.swift`

**Test Cases**:
- `testCreateTest_EmptyState` - Verify empty state message when no tests exist
- `testCreateTest_ValidInput` - Create test with name and words, verify it appears in list
- `testCreateTest_WordParsing` - Test comma-separated and newline-separated word input
- `testCreateTest_TTSPreview` - Verify TTS speaker button works for word preview
- `testCreateTest_RemoveWord` - Add words then remove one, verify removal
- `testEditTest_UpdateName` - Edit existing test name, verify change persists
- `testEditTest_AddWords` - Add words to existing test, verify they appear
- `testEditTest_DeleteWord` - Remove word from existing test, verify removal
- `testDeleteTest` - Delete test, verify it's removed from list
- `testTestList_Sorting` - Verify tests are sorted by creation date (newest first)

**Example Test**:
```swift
func testCreateTest_ValidInput() {
    let app = XCUIApplication()
    app.launch()
    
    // Navigate to parent home (assuming role already selected)
    let parentHomePage = ParentHomePage(app: app)
    let createTestPage = parentHomePage.tapCreateTest()
    
    createTestPage
        .enterTestName("My Test")
        .enterWords("cat, dog, bird")
        .tapAddWords()
        .tapSave()
    
    XCTAssertTrue(parentHomePage.verifyTestExists(named: "My Test"))
}
```

**Key Assertions**:
- Test creation form fields are accessible
- "Add Words" button is disabled when word text is empty
- Created tests appear in list with correct name and word count
- Edit form pre-populates with existing test data
- Deleted tests no longer appear in list
- Navigation works correctly (back buttons, dismiss)

### 3. Child Flow Tests
**File**: `WordCraftUITests/ChildFlowTests.swift`

**Test Cases**:
- `testChildHome_EmptyState` - Verify empty state when no tests available
- `testChildHome_TestList` - Verify test cards display correctly with name and word count
- `testChildHome_StreakDisplay` - Verify streak indicator appears when streak > 0
- `testPracticeFlow_FirstRound` - Complete first round with all words, verify progress
- `testPracticeFlow_CorrectAnswer` - Submit correct answer, verify feedback and progression
- `testPracticeFlow_IncorrectAnswer` - Submit incorrect answer, verify feedback and word appears in next round
- `testPracticeFlow_RoundTransition` - Misspell words, verify round transition screen appears with misspelled words list
- `testPracticeFlow_StartNextRound` - Complete round transition, verify next round starts with only misspelled words
- `testPracticeFlow_IterativeRounds` - Complete multiple rounds until all words mastered
- `testPracticeFlow_TTSPlayback` - Verify speaker button plays word audio
- `testPracticeFlow_InputDisabledDuringFeedback` - Verify input is disabled during feedback display
- `testPracticeSummary_Display` - Verify summary shows rounds completed and streak
- `testPracticeSummary_PracticeAgain` - Verify "Practice Again" button resets practice
- `testPracticeSummary_BackToTests` - Verify "Back to Tests" button dismisses practice view

**Example Test**:
```swift
func testPracticeFlow_IterativeRounds() {
    let app = XCUIApplication()
    app.launch()
    
    // Setup: Create test with words (using helper or page objects)
    let parentHomePage = ParentHomePage(app: app)
    // ... create test ...
    
    // Switch to child role
    let childHomePage = ChildHomePage(app: app)
    let practicePage = childHomePage.tapTestCard(named: "My Test")
    
    // Round 1: Misspell some words
    practicePage
        .enterAnswer("incorrect")
        .tapSubmit()
    
    let roundTransitionPage = practicePage.waitForRoundTransition()
    XCTAssertTrue(roundTransitionPage.verifyMisspelledWordExists("cat"))
    
    practicePage = roundTransitionPage.tapStartRound()
    
    // Round 2: Spell correctly
    practicePage
        .enterAnswer("cat")
        .tapSubmit()
        .waitForSummary()
    
    let summaryPage = PracticeSummaryPage(app: app)
    XCTAssertTrue(summaryPage.verifyRoundsCompleted(2))
}
```

**Key Assertions**:
- Practice view displays current word and progress
- Submit button is disabled when input is empty
- Correct answers show positive feedback
- Incorrect answers show negative feedback
- Round transitions display misspelled words list
- Practice continues until all words are mastered
- Summary view displays correct information

### 4. Edge Cases and Error Scenarios
**File**: `WordCraftUITests/EdgeCaseTests.swift`

**Test Cases**:
- `testEmptyTestName_Validation` - Attempt to create test with empty name
- `testEmptyWordsList_Validation` - Attempt to create test with no words
- `testDuplicateWords_Handling` - Add duplicate words, verify deduplication
- `testWordInput_WhitespaceHandling` - Test words with leading/trailing whitespace
- `testPractice_AllCorrectFirstRound` - Complete practice with all words correct in first round
- `testPractice_AllIncorrectFirstRound` - All words incorrect, verify all appear in round 2
- `testDataPersistence_AppRestart` - Create test, restart app, verify test persists
- `testDataPersistence_PracticeProgress` - Complete practice, restart app, verify streak persists
- `testErrorHandling_SaveFailure` - Simulate save failure, verify error alert appears
- `testErrorHandling_LoadFailure` - Simulate load failure, verify error message
- `testRoleSwitching_DataPersistence` - Switch roles, verify data persists for both roles

**Key Assertions**:
- Validation prevents invalid input
- Duplicate words are handled correctly
- Data persists across app restarts
- Error alerts are displayed appropriately
- App handles edge cases gracefully

## Test Helpers

### TestHelpers
**File**: `WordCraftUITests/Helpers/TestHelpers.swift`

**Helper Functions**:
- `launchAppWithRole(_ role: UserRole) -> ParentHomePage | ChildHomePage` - Launch app and select role, return appropriate page
- `createTestViaUI(name: String, words: [String]) -> ParentHomePage` - Helper to create a test via UI using page objects
- `clearAllTests()` - Helper to clean up test data
- `resetOnboardingFlags()` - Reset UserDefaults onboarding flags for clean test state
- `waitForAppToBeReady(_ app: XCUIApplication)` - Wait for app to finish initializing

## Test Configuration

### Setup and Teardown
- Each test should start with a clean app state (use `XCUIApplication().launch()` with fresh state)
- Clear SwiftData store between test runs if needed
- Reset UserDefaults for onboarding flags between tests
- Use `setUp()` and `tearDown()` methods for common setup/cleanup

### Test Data Management
- Use predictable test data (e.g., "Test 1", "Test 2", words: ["cat", "dog", "bird"])
- Clean up test data after each test to avoid interference
- Consider using in-memory SwiftData store for faster tests
- Use helper methods to create test data consistently

### Accessibility Identifiers
Add accessibility identifiers to key UI elements for reliable test targeting:

**Files to Modify**:
- `WordCraft/Components/RoleSelectionView.swift` - Add identifiers to role buttons
- `WordCraft/Features/Parent/ParentHomeView.swift` - Add identifiers to test cards, buttons
- `WordCraft/Features/Child/ChildHomeView.swift` - Add identifiers to test cards
- `WordCraft/Features/Child/PracticeView.swift` - Add identifiers to practice elements
- `WordCraft/Features/Parent/CreateTestView.swift` - Add identifiers to form fields
- `WordCraft/Features/Parent/EditTestView.swift` - Add identifiers to form fields

**Example**:
```swift
Button("I am a Parent") {
    appState.selectedRole = .parent
}
.accessibilityIdentifier("RoleSelection_ParentButton")
```

## Implementation Order

1. **Setup test infrastructure** - Create BasePage and TestHelpers
2. **Add accessibility identifiers** - Update UI views with identifiers
3. **Create page objects** - Implement all page object classes
4. **Role selection tests** - Test basic app entry and role selection
5. **Parent flow tests** - Test test creation and management
6. **Child flow tests** - Test practice flows and iterative rounds
7. **Edge case tests** - Test error scenarios and edge cases

## Testing Considerations

### Challenges
- **TTS Testing**: Cannot verify audio playback directly, but can verify button taps and state changes
- **Timer-based UI**: Round transitions and feedback delays require proper waiting strategies
- **SwiftData Persistence**: May need in-memory store for faster, isolated tests
- **State Management**: Ensure tests don't interfere with each other

### Best Practices
- Use `waitForExistence(timeout:)` for async UI updates
- Avoid hard-coded delays; use element waiting instead
- Test both happy paths and error scenarios
- Keep tests independent and isolated
- Use descriptive test names that explain what is being tested
- Follow Page Object Model principles strictly - no direct XCUIApplication access in tests

## Files to Create

### Page Objects
1. `WordCraftUITests/PageObjects/BasePage.swift`
2. `WordCraftUITests/PageObjects/RoleSelectionPage.swift`
3. `WordCraftUITests/PageObjects/OnboardingPage.swift`
4. `WordCraftUITests/PageObjects/ParentHomePage.swift`
5. `WordCraftUITests/PageObjects/CreateTestPage.swift`
6. `WordCraftUITests/PageObjects/EditTestPage.swift`
7. `WordCraftUITests/PageObjects/ChildHomePage.swift`
8. `WordCraftUITests/PageObjects/PracticePage.swift`
9. `WordCraftUITests/PageObjects/RoundTransitionPage.swift`
10. `WordCraftUITests/PageObjects/PracticeSummaryPage.swift`
11. `WordCraftUITests/PageObjects/RoleSwitcherPage.swift`

### Test Files
12. `WordCraftUITests/RoleSelectionTests.swift`
13. `WordCraftUITests/ParentFlowTests.swift`
14. `WordCraftUITests/ChildFlowTests.swift`
15. `WordCraftUITests/EdgeCaseTests.swift`

### Helpers
16. `WordCraftUITests/Helpers/TestHelpers.swift`

## Implementation Todos

1. **base-page-object** - Create BasePage.swift with common functionality (waitForElement, tapIfExists, isElementVisible, etc.)
2. **accessibility-identifiers** - Add accessibility identifiers to key UI elements in RoleSelectionView, ParentHomeView, ChildHomeView, PracticeView, CreateTestView, and EditTestView
3. **page-objects-role-selection** - Implement RoleSelectionPage and OnboardingPage page objects
4. **page-objects-parent** - Implement ParentHomePage, CreateTestPage, and EditTestPage page objects
5. **page-objects-child** - Implement ChildHomePage, PracticePage, RoundTransitionPage, and PracticeSummaryPage page objects
6. **page-objects-role-switcher** - Implement RoleSwitcherPage page object
7. **test-helpers** - Create TestHelpers.swift with reusable test utilities (launchAppWithRole, createTestViaUI, clearAllTests, resetOnboardingFlags)
8. **role-selection-tests** - Implement RoleSelectionTests.swift using page objects
9. **parent-flow-tests** - Implement ParentFlowTests.swift using page objects
10. **child-flow-tests** - Implement ChildFlowTests.swift using page objects
11. **edge-case-tests** - Implement EdgeCaseTests.swift using page objects

