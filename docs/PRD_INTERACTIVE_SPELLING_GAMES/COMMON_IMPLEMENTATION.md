# Common Implementation (Shared Across All 5 Games)

This document describes the shared architecture and reusable pieces to implement once and reuse across all interactive spelling games:

- Balloon Pop
- Fish Catcher
- Word Builder
- Falling Stars
- Rocket Launch

The goal is consistent navigation, scoring, progress tracking, accessibility, and UX polish.

---

## Scope and Design Principles

- **SwiftUI MV (no ViewModels)**: Prefer `@State` for view-local state and `@Observable` only when a reusable state object is warranted.
- **Accessibility-first**: Every tappable/interactive element gets:
  - `accessibilityLabel`
  - `accessibilityIdentifier`
  - `accessibilityHint` (when non-obvious)
- **Consistent gamification**: Use existing services where possible:
  - Points and combo: `SpellPlay/Services/PointsService.swift`
  - TTS: `SpellPlay/Services/TTSService.swift`
  - Existing celebration patterns: `SpellPlay/Components/CelebrationView.swift`
- **Performance**: Prefer `TimelineView` for continuous animations and `Canvas` for particle/twinkle effects.

---

## Folder + File Structure (Recommended)

Create a single new feature root:

```
SpellPlay/Features/Child/Games/
├── GameSelectionView.swift
├── Common/
│   ├── GameModels.swift
│   ├── GameProgressView.swift
│   ├── GameResultView.swift
│   └── GameScoring.swift
├── BalloonPop/...
├── FishCatcher/...
├── WordBuilder/...
├── FallingStars/...
└── RocketLaunch/...
```

---

## Shared Models

### `GameDifficulty`

Define a shared difficulty model used by all games (even if the UI for it comes later):

- `easy`: fewer decoys, slower objects, longer timeouts
- `medium`: baseline
- `hard`: more decoys, faster objects, tighter timeouts, more simultaneous objects

### `GamePhase`

Shared lifecycle:

- `ready`: shown before first word begins
- `playing`: user is interacting
- `wordComplete`: short celebration + transition
- `gameComplete`: results screen

### `GameSessionState` (lightweight, reusable)

Track per-session state consistently:

- `words: [Word]`
- `currentWordIndex: Int`
- `score: Int`
- `comboCount: Int`
- `starsPerWord: [Int]`
- `mistakesPerWord: [Int]` (or aggregate `mistakeCount`)
- `wordStartTime: Date?`
- `sessionStartTime: Date?`

---

## Shared Scoring and Stars

### Points

Use `PointsService.calculatePoints(isCorrect:comboCount:timeTaken:isFirstTry:)` for each **word completion**, not per tap/drag.

Recommended mapping:

- **Word completed (correct)**: award points once per word.
- **Combo**: consecutive **words completed** without a mistake increases `comboCount`.
- **Time taken**: measure per-word time and feed into `PointsService` for speed bonus.

### Stars (1–3)

Apply a consistent rubric across games:

- **3 stars**: no mistakes + under speed threshold
- **2 stars**: no mistakes, slower than threshold
- **1 star**: completed with mistakes
- **0 stars**: word not completed (should rarely happen if you require completion before moving on)

---

## Shared Navigation Flow

### Entry Point

From `SpellPlay/Features/Child/WordReviewView.swift` add a new \"Play Games\" button that presents `GameSelectionView(test:)` (full screen).

### Selection

`GameSelectionView` displays a grid/list of game cards. It passes `test.words.sortedAsCreated()` to the game view, and receives a `GameResult` back (via closure or navigation state).

### Completion

All games end in `GameResultView`, which offers:

- Play again (same game, same word list)
- Choose different game (returns to `GameSelectionView`)
- Done (returns to `WordReviewView`)

---

## Shared UI Components

### `GameProgressView`

Display:

- Current word progress (e.g., `Word 3 of 12`)
- Word completion progress bar (optional)
- Combo multiplier badge (reuse `ComboIndicatorView` pattern if desired)

### `GameResultView`

Display:

- Total points earned
- Total stars earned
- Optional grade/performance summary (similar to practice)

Use consistent identifiers for UI testing, e.g.:

- `GameResult_TotalPoints`
- `GameResult_TotalStars`
- `GameResult_PlayAgainButton`
- `GameResult_DifferentGameButton`
- `GameResult_DoneButton`

---

## Shared Audio (TTS)

Use `TTSService.speak(word.text, rate:)`:

- On word start: auto-play once (short delay if needed for view appearance)
- Provide a replay speaker button
- Consider a slower replay option (like practice has) for accessibility

---

## Difficulty Scaling Knobs (Reusable)

Each game should use the same kinds of knobs, wired to `GameDifficulty`:

- **Spawn rate**: how often letters appear
- **Object speed**: balloons/fish/stars travel speed
- **Decoy count**: number of incorrect letters present
- **Simultaneous objects**: how many are on screen at once
- **Timeout**: how long before object disappears

---

## UI Testing Hooks (Shared Conventions)

Add consistent `accessibilityIdentifier`s for:

- Game root views: `BalloonPop_Root`, `FishCatcher_Root`, etc.
- Word progress label: `Game_ProgressText`
- Score display: `Game_Score`
- Replay speaker: `Game_SpeakWordButton`

Prefer deterministic behavior in UI tests by allowing:

- Fixed random seed for letter positions/spawns (in debug/test builds)
- Reduced animation durations for tests

---

## Achievements (Shared)

Game-specific achievements proposed by the PRD:

- Game Explorer: try all 5 spelling games
- Balloon Master: complete 10 words in Balloon Pop
- Fish Whisperer: complete 10 words in Fish Catcher
- Star Collector: complete 10 words in Falling Stars
- Word Architect: complete 10 words in Word Builder
- Mission Control: complete 10 words in Rocket Launch
- Perfect Launch: complete Rocket Launch with no mistakes

Implementation approach:

- Extend `SpellPlay/Models/Achievement.swift` with new `AchievementID` cases and definitions.
- Persist progress in `UserProgress` (or a new lightweight counter model) so achievements survive app restarts.
- Update `AchievementService` to check game session summaries (similar to practice) and unlock when thresholds are met.

---

## Open Questions to Resolve Before Coding (Applies to All Games)

1. **Word source**: use all test words, or only \"difficult\"/misspelled words?
2. **Difficulty selection**: user-selected, parent-controlled, or adaptive?
3. **Sound effects**: do we add non-TTS SFX for taps/pops/catches?


