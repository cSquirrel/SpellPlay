# Comprehensive Gamification System for WordCraft

## Overview
Transform the spelling practice experience with a multi-layered gamification system that provides immediate feedback, tracks progress, and rewards achievements. Designed specifically for 8-10 year olds with visual rewards, clear progress indicators, and achievable goals.

## Core Features

### 1. Points & Scoring System
- **Base Points**: 10 points per correct answer
- **Combo Multipliers**: Consecutive correct answers increase multiplier (2x, 3x, 4x max)
- **Perfect Round Bonus**: +50 points for completing a round with 100% accuracy
- **Speed Bonus**: Bonus points for quick answers (optional, time-based)
- **Session Total**: Display running total during practice

### 2. Combo System
- Visual combo counter that builds with consecutive correct answers
- Combo breaks on incorrect answer
- Animated combo indicator showing multiplier
- Bonus points scale with combo level

### 3. Star Collection
- Earn 1-3 stars per word based on performance:
  - 1 star: Correct answer
  - 2 stars: Correct on first try
  - 3 stars: Correct on first try + speed bonus
- Display total stars earned in session
- Cumulative star count across all sessions

### 4. Achievement Badges
Unlockable achievements with visual badges:
- **First Steps**: Complete first practice session
- **Perfect Round**: Get all words correct in one round
- **Speed Demon**: Complete a round in under 2 minutes
- **Streak Master**: Maintain 7-day streak
- **Word Wizard**: Master 50 words total
- **No Help Needed**: Complete a session without using help coins
- **Comeback Kid**: Master all words after initial mistakes

### 5. Performance Grades
Session completion grades based on accuracy:
- **Perfect!** (100% accuracy, first try on all words)
- **Excellent!** (90-99% accuracy)
- **Great Job!** (75-89% accuracy)
- **Good Work!** (60-74% accuracy)
- **Keep Practicing!** (<60% accuracy)

### 6. Leveling System
- Level up based on total points earned
- Visual level indicator with progress bar
- Unlock visual themes/colors at certain levels
- Display current level prominently

### 7. Enhanced Celebrations
Different celebration types based on achievement:
- **Word Correct**: Simple checkmark with points popup
- **Combo Breakthrough**: Special animation when reaching new combo level
- **Perfect Round**: Enhanced confetti with "Perfect Round!" message
- **Achievement Unlock**: Badge reveal animation
- **Level Up**: Special level-up celebration
- **Session Complete**: Grade-based celebration with summary

## Implementation Plan

### Phase 1: Data Models & Services

**File: `SpellPlay/Models/UserProgress.swift`** (new)
- Track total points, stars, level, experience points
- Store unlocked achievements
- Track lifetime statistics

**File: `SpellPlay/Models/Achievement.swift`** (new)
- Achievement definitions with IDs, names, descriptions, icons
- Unlock conditions and thresholds

**File: `SpellPlay/Services/PointsService.swift`** (new)
- Calculate points based on correctness, combos, bonuses
- Track session points and lifetime totals
- Handle point persistence

**File: `SpellPlay/Services/AchievementService.swift`** (new)
- Check achievement unlock conditions
- Manage achievement state
- Trigger achievement unlock notifications

**File: `SpellPlay/Services/LevelService.swift`** (new)
- Calculate level from total points/experience
- Determine experience needed for next level
- Handle level-up events

### Phase 2: ViewModel Enhancements

**File: `SpellPlay/Features/Child/ViewModels/PracticeViewModel.swift`**
- Add `currentPoints`, `sessionPoints`, `comboCount`, `comboMultiplier`
- Add `starsEarned`, `totalStars`
- Track timing for speed bonuses
- Integrate with PointsService, AchievementService, LevelService
- Calculate performance grade on completion

### Phase 3: UI Components

**File: `SpellPlay/Components/PointsDisplayView.swift`** (new)
- Animated points counter showing current session total
- Points popup animation when earning points

**File: `SpellPlay/Components/ComboIndicatorView.swift`** (new)
- Visual combo counter with multiplier display
- Animated when combo increases
- Pulsing effect during active combo

**File: `SpellPlay/Components/StarCollectionView.swift`** (new)
- Display stars earned per word
- Session star total
- Animated star collection effect

**File: `SpellPlay/Components/AchievementBadgeView.swift`** (new)
- Badge display with icon and name
- Unlock animation
- Achievement gallery view

**File: `SpellPlay/Components/LevelProgressView.swift`** (new)
- Current level display
- Progress bar to next level
- Experience points indicator

**File: `SpellPlay/Components/CelebrationView.swift`** (enhance)
- Support different celebration types (word correct, combo, perfect round, achievement, level up)
- Parameterized celebration content
- Enhanced animations for each type

**File: `SpellPlay/Components/PerformanceGradeView.swift`** (new)
- Display performance grade with appropriate styling
- Grade-based color scheme and messaging

### Phase 4: Practice View Updates

**File: `SpellPlay/Features/Child/PracticeView.swift`**
- Add points display at top
- Show combo indicator when active
- Display stars earned per word
- Enhanced feedback with points popup
- Integrate achievement unlock notifications

### Phase 5: Summary View Enhancements

**File: `SpellPlay/Features/Child/PracticeSummaryView.swift`**
- Display session points earned
- Show performance grade prominently
- Display stars collected
- Show any achievements unlocked
- Level progress indicator
- Enhanced celebration based on grade

### Phase 6: Progress Tracking View (Optional)

**File: `SpellPlay/Features/Child/ProgressView.swift`** (new)
- Achievement gallery
- Level and experience display
- Lifetime statistics
- Star collection showcase

## Technical Considerations

### Data Persistence
- Use SwiftData to persist UserProgress model
- Store achievements as array of achievement IDs
- Migration strategy for existing users (initialize with level 1, 0 points)

### Performance
- Lightweight point calculations
- Efficient achievement checking (only on relevant events)
- Smooth animations without blocking UI

### User Experience
- All rewards should be immediate and visible
- Clear visual feedback for every action
- Achievable goals to maintain motivation
- Positive reinforcement even for partial success

## File Structure Summary

**New Files:**
- `SpellPlay/Models/UserProgress.swift`
- `SpellPlay/Models/Achievement.swift`
- `SpellPlay/Services/PointsService.swift`
- `SpellPlay/Services/AchievementService.swift`
- `SpellPlay/Services/LevelService.swift`
- `SpellPlay/Components/PointsDisplayView.swift`
- `SpellPlay/Components/ComboIndicatorView.swift`
- `SpellPlay/Components/StarCollectionView.swift`
- `SpellPlay/Components/AchievementBadgeView.swift`
- `SpellPlay/Components/LevelProgressView.swift`
- `SpellPlay/Components/PerformanceGradeView.swift`
- `SpellPlay/Features/Child/ProgressView.swift` (optional)

**Modified Files:**
- `SpellPlay/Features/Child/ViewModels/PracticeViewModel.swift`
- `SpellPlay/Features/Child/PracticeView.swift`
- `SpellPlay/Features/Child/PracticeSummaryView.swift`
- `SpellPlay/Components/CelebrationView.swift`
- `SpellPlay/Models/SchemaVersions.swift` (for data migration)

