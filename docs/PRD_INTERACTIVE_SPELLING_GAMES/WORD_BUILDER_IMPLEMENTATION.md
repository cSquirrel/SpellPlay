# Word Builder (Drag-and-Drop) — Implementation Plan

## Goal

Implement **Word Builder**, where a child drags scrambled letter tiles into slots to form the word. The word is spoken via TTS at the start and via a replay button.

This is intended to be the **first game implemented** (simplest mechanics; establishes shared patterns).

---

## Core Gameplay Loop

For each `Word` in the provided list:

1. Speak the word (TTS)
2. Render empty slots (word length)
3. Render scrambled letter tiles (plus optional decoys on harder difficulty)
4. Child drags tiles into slots
5. Correct placement locks and glows
6. Incorrect placement bounces back + gentle feedback
7. When all slots correct → award points + stars → celebrate → advance to next word
8. After final word → show result screen

---

## Step-by-Step Implementation

### Step 1: Create Feature Files

Create:

```
SpellPlay/Features/Child/Games/WordBuilder/
├── WordBuilderView.swift
└── LetterTileView.swift
```

### Step 2: Define Game State in `WordBuilderView`

Use local SwiftUI state (no ViewModel):

- `words: [Word]` (input)
- `currentWordIndex: Int`
- `currentTarget: String`
- `scrambledLetters: [LetterTile]`
- `placedLetters: [Character?]` (slots)
- `lockedSlotIndices: Set<Int>`
- `mistakesThisWord: Int`
- `wordStartTime: Date?`
- scoring: `score`, `comboCount`, `starsPerWord`

Notes:

- Use `Word.text` for the authoritative target string.
- Use `sortedAsCreated()` prior to passing in, to preserve entry order.

### Step 3: Implement Tile + Slot Models

In `WordBuilderView.swift` define small local structs:

- `struct LetterTile: Identifiable { id, letter, isPlaced }`
- `struct SlotTarget { index, expectedLetter, currentLetter }` (or compute from arrays)

### Step 4: Implement UI Layout

- **Top**: `GameProgressView` + current word slots
- **Middle**: optional hint UI + speaker replay button
- **Bottom**: a “tray” area with draggable tiles

Use large touch targets (min 44pt) and kid-friendly typography.

### Step 5: Implement Drag-and-Drop

Recommended approach (SwiftUI-native):

- Each tile uses `.draggable(...)`
- Each slot uses `.dropDestination(for: ...)`

Rules:

- If slot already locked, ignore drops
- If dropped letter matches the slot’s expected letter:
  - lock slot
  - mark tile as placed
  - animate slot glow
- Else:
  - increment `mistakesThisWord`
  - animate wiggle/bounce

### Step 6: Implement Word Completion Detection

After each correct placement:

- If all slots are locked → complete word:
  - compute `timeTaken = Date() - wordStartTime`
  - compute points using `PointsService` (award once per word)
  - compute stars (see `docs/PRD_INTERACTIVE_SPELLING_GAMES/COMMON_IMPLEMENTATION.md`)
  - show brief celebration
  - advance to next word

Combo logic:

- If `mistakesThisWord == 0`: `comboCount += 1`
- Else: `comboCount = 0`

### Step 7: TTS Integration

Use `TTSService`:

- Auto-speak at the start of each word
- Speaker button to replay
- Optional slow replay (mirrors existing practice UX)

### Step 8: Difficulty Scaling Hooks

Wire to shared `GameDifficulty`:

- `easy`: no decoys, optionally reveal first letter locked
- `medium`: no decoys, no locked hints
- `hard`: add decoy tiles (extra letters), potentially randomize tray placement more aggressively

### Step 9: Results Screen

After last word:

- Navigate/present `GameResultView` with:
  - total points
  - total stars
  - words completed
  - mistakes

### Step 10: Accessibility + UI Testing IDs

Add identifiers:

- Root: `WordBuilder_Root`
- Slots: `WordBuilder_Slot_0`, `WordBuilder_Slot_1`, ...
- Tiles: `WordBuilder_Tile_<letter>_<n>`
- Speaker: `WordBuilder_SpeakWordButton`
- Score: `WordBuilder_Score`

---

## Non-Goals (For MVP)

- Physics-based dragging
- Advanced hint system beyond optional first-letter reveal
- Persisting per-letter performance telemetry


