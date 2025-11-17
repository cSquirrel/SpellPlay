# User-Facing Error Messages Implementation

## Overview
Replace silent error handling (print statements) with user-friendly error messages using SwiftUI alerts and toast notifications. Ensure users are informed when operations fail and can take appropriate action.

## Current Error Handling Issues

### Silent Errors (Only print to console)
1. **CreateTestView** - Test save failures
2. **EditTestView** - Test save failures  
3. **PracticeViewModel** - Practice session save failures
4. **StreakService** - Streak save failures
5. **TestListViewModel** - Has `errorMessage` property but never displays it

### Error Scenarios to Handle
- Test creation/editing save failures
- Test deletion failures
- Practice session save failures
- Streak calculation/save failures
- Test loading failures (already has errorMessage but not displayed)
- TTS errors (will be handled in TTS improvements)

## Implementation Approach

### 1. Create Reusable Error Alert Component
- Create `ErrorAlert` view modifier or component
- Support both SwiftUI `.alert()` and optional toast-style notifications
- Provide user-friendly error messages with actionable buttons

### 2. Update Error Handling in Views
- Replace `print()` statements with error state management
- Add `@State` error properties in views
- Display alerts when errors occur
- Provide retry options where appropriate

### 3. Standardize Error Messages
- Create user-friendly error messages (avoid technical jargon)
- Provide context-specific guidance
- Use consistent error presentation across the app

## Files to Modify

1. **SpellPlay/Components/ErrorAlert.swift** (NEW) - Reusable error alert component
2. **SpellPlay/Features/Parent/CreateTestView.swift** - Add error alert for save failures
3. **SpellPlay/Features/Parent/EditTestView.swift** - Add error alert for save failures
4. **SpellPlay/Features/Parent/ParentHomeView.swift** - Display TestListViewModel errorMessage
5. **SpellPlay/Features/Child/ViewModels/PracticeViewModel.swift** - Add error state and expose to view
6. **SpellPlay/Features/Child/PracticeView.swift** - Display practice session save errors
7. **SpellPlay/Services/StreakService.swift** - Return errors instead of printing (or use callback)

## Implementation Details

### Error Alert Component
- Use SwiftUI `.alert()` modifier
- Support dismissible alerts with optional retry action
- Show clear, actionable error messages
- Consider toast-style for non-critical errors

### Error Message Standards
- **Save failures**: "Unable to save. Please try again."
- **Delete failures**: "Unable to delete. Please try again."
- **Load failures**: "Unable to load data. Please restart the app."
- **Practice save failures**: "Your progress was saved, but some information couldn't be recorded."

## Error Handling Strategy

1. **Critical errors** (data loss risk): Show alert with retry option
2. **Non-critical errors** (progress tracking): Show toast or subtle notification
3. **Recoverable errors**: Provide retry button
4. **Non-recoverable errors**: Show message with guidance

## Implementation Todos

1. **error-alert-component** - Create reusable ErrorAlert component/view modifier for displaying user-friendly error messages with optional retry actions
2. **create-test-errors** - Update CreateTestView to show error alert when test save fails, replace print() with error state
3. **edit-test-errors** - Update EditTestView to show error alert when test save fails, replace print() with error state
4. **test-list-errors** - Update ParentHomeView to display TestListViewModel errorMessage using alert
5. **practice-session-errors** - Add error state to PracticeViewModel and display errors in PracticeView when practice session save fails
6. **streak-service-errors** - Update StreakService to handle errors gracefully and expose error state, or use callback pattern for error reporting

