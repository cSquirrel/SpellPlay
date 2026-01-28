# Fish Catcher — Implementation Plan

## Goal

Implement **Fish Catcher**, where fish swim across the screen carrying letters. Kids tap the correct next fish (in spelling order) to catch letters and complete the word.

This game shares core patterns with Balloon Pop but uses **horizontal motion** and a **bucket/net** metaphor.

---

## Core Gameplay Loop

For each `Word`:

1. Show the target word at the top (with progress indication).
2. Spawn fish carrying letters (correct + decoys) at different depths and speeds.
3. Fish swim left-to-right across the screen.
4. Kid taps fish:
   - Correct letter **and** correct order → fish “jumps” into the bucket; progress advances.
   - Wrong letter or wrong order → gentle splash feedback; fish escapes.
5. When all letters are caught → award points + stars → show short celebration → move to next word.
6. After the final word → show `GameResultView`.

---

## Step-by-Step Implementation

### Step 1: Create Feature Files

Create:

```text
SpellPlay/Features/Child/Games/FishCatcher/
├── FishCatcherView.swift
└── FishView.swift
```

### Step 2: Define Fish Model

In `FishCatcherView.swift`:

- `struct Fish: Identifiable { id, letter, depth, speed, startTime, color }`

State to maintain:

- `words: [Word]` (input)
- `currentWordIndex: Int`
- `nextExpectedIndex: Int`
- `activeFish: [Fish]`
- `score`, `comboCount`, `comboMultiplier`, `totalStars`
- `mistakesThisWord`, `totalMistakes`
- `wordStartTime: Date?`
- `phase: GamePhase`
- `difficulty: GameDifficulty`

### Step 3: Animation Strategy (Swimming)

Use `TimelineView(.animation)` exactly like Balloon Pop but for horizontal movement:

```swift
let elapsed = now.timeIntervalSince(fish.startTime)
let x = startX + CGFloat(elapsed) * fish.speed
```

- Remove fish when `x` moves past the right edge + some padding.
- Depth is a fixed `y` position per fish (random within a band).

### Step 4: `FishView` Rendering

`FishView` responsibilities:

- Render a simple, cute fish body:
  - Ellipse body + triangular tail (or a custom `FishShape`).
- Overlay the letter in bold, high-contrast text.
- Subtle tail wiggle animation using a small rotation or 3D flip.
- Tap handler closure for the game logic.

Accessibility:

- `accessibilityLabel("Fish letter \(letter)")`
- `accessibilityIdentifier("FishCatcher_Fish_\(letter)_\(id)")`

### Step 5: Spawning Logic

Per word:

1. Determine the **next expected letter**.
2. Spawn a mix of:
   - Correct-letter fish.
   - Decoy fish with other letters.
3. Depth:
   - Random `y` between top and bottom bands (avoid UI and bucket regions).
4. Speed:
   - Varies per fish and per difficulty.

Difficulty knobs:

- **Easy**: fewer decoys, slow fish, letters appear in near-correct order.
- **Medium**: mixed order, moderate speed, more decoys.
- **Hard**: multiple fish at once, faster speeds, more decoys.

### Step 6: Bucket / Net UI

At the bottom:

- A bucket/net view that:
  - Shows caught letters as small fish or text labels.
  - Bounces slightly when a fish is caught (scale animation).

Identifiers:

- `FishCatcher_Bucket`
- `FishCatcher_CaughtLetters`

### Step 7: Tap Handling / Correctness

On fish tap:

1. Remove the tapped fish from `activeFish`.
2. Determine expected letter: `expectedLetter = targetWord[nextExpectedIndex]`.
3. Compare (case-insensitive) with fish.letter:
   - If correct:
     - Increment `nextExpectedIndex`.
     - Animate fish jumping downwards into the bucket location.
     - Check for word completion.
   - If wrong:
     - Increment `mistakesThisWord` and `totalMistakes`.
     - Animate fish “splash” (short scale or opacity effect) and possibly speed up off-screen.

### Step 8: Word Completion + Scoring

When `nextExpectedIndex == targetWord.count`:

- Compute `timeTaken = Date() - wordStartTime`.
- Combo:
  - If `mistakesThisWord == 0`: `comboCount += 1`.
  - Else: `comboCount = 0`.
- `comboMultiplier = PointsService.getComboMultiplier(for: comboCount)`.
- Get `PointsService.calculatePoints(isCorrect: true, comboCount: comboCount, timeTaken: timeTaken, isFirstTry: mistakesThisWord == 0)`.
- Add to session `score`.

Stars:

- 3: no mistakes + fast.
- 2: no mistakes.
- 1: at least one mistake.

Then:

- Show `CelebrationView` with a short “wave” or “splash” themed emoji.
- Advance to next word, or finish and show `GameResultView`.

### Step 9: Background + Visual Design

MVP visuals:

- Water/pond gradient background (blue/green).
- Subtle wave animation (e.g., a moving overlay shape or gradient).
- Occasional bubbles (small circles rising using `TimelineView` or `Canvas`).

Keep it simple and performant; any particle effects should use `Canvas`.

### Step 10: Accessibility + UI Testing IDs

Add identifiers for UI tests:

- Root: `FishCatcher_Root`
- Word display: `FishCatcher_WordDisplay`
- Score: `FishCatcher_Score`
- Combo: `FishCatcher_Combo`
- Progress: `FishCatcher_ProgressText`

---

## Non-Goals (For MVP)

- Physics-based water simulation.
- Dragging a net/hook with the finger.
- Complex fish schooling behaviors.

# Fish Catcher — Implementation Plan

## Goal

Implement **Fish Catcher**, where fish swim left-to-right carrying letters. The child taps the correct next fish (in order) to spell the word, and correct fish “jump” into a bucket/net.

---

## Core Gameplay Loop

For each `Word`:

1. Show target word slots at top
2. Spawn fish with letters (correct + decoys)
3. Fish swim across at different depths and speeds
4. Child taps fish:
   - correct letter + correct order → fish “caught”, jumps into bucket with splash
   - wrong letter/order → fish escapes with splash feedback
5. When word complete → award points + stars → celebrate → next word
6. End → result screen

---

## Step-by-Step Implementation

### Step 1: Create Feature Files

```
SpellPlay/Features/Child/Games/FishCatcher/
├── FishCatcherView.swift
└── FishView.swift
```

### Step 2: Define Fish Model

In `FishCatcherView.swift` define:

- `struct Fish: Identifiable { id, letter, yDepth, speed, color, spawnedAt }`

Maintain:

- `activeFish: [Fish]`
- `caughtLetters: [Character]` (or just `nextExpectedIndex`)
- `nextExpectedIndex: Int`
- `mistakesThisWord: Int`
- `wordStartTime: Date?`
- scoring: `score`, `comboCount`, `starsPerWord`

### Step 3: Swim Animation Strategy

Use `TimelineView(.animation)` to compute x-position from spawn time:

- x = startX + (elapsed * speed)
- remove fish when x > right edge

This avoids per-fish timers and gives smooth deterministic motion.

### Step 4: Fish Rendering (`FishView`)

`FishView` responsibilities:

- Draw a simple fish shape (ellipse body + tail) or stylized path
- Render the letter on the fish side
- Optional tail wiggle animation
- Tap handler

Accessibility:

- `accessibilityLabel(\"Fish letter \(letter)\")`
- `accessibilityIdentifier(\"FishCatcher_Fish_\(letter)_\(id)\")`

### Step 5: Spawning Logic

On each word start:

1. Determine letters to spawn:
   - include required target letters (with duplicates)
   - add decoy letters based on difficulty
2. Spawn cadence:
   - `easy`: slower fish, fewer decoys, letters appear closer to correct order
   - `medium`: mixed
   - `hard`: faster fish, more decoys, multiple fish simultaneously

Depth:

- random yDepth within safe swimming band (leave room for top word UI and bottom bucket)

### Step 6: Bucket / Net UI

At bottom:

- bucket/net container
- show caught letters (or small fish icons) as progress feedback
- animate bounce on successful catch

Add identifiers:

- `FishCatcher_Bucket`
- `FishCatcher_CaughtLetters`

### Step 7: Tap Handling / Correctness

On fish tap:

- expectedLetter = targetWord[nextExpectedIndex]
- if matches:
  - `nextExpectedIndex += 1`
  - animate fish jump into bucket + splash
  - remove fish from `activeFish`
- else:
  - `mistakesThisWord += 1`
  - animate splash + fish accelerates briefly (or fade out)

### Step 8: Word Completion + Scoring

When `nextExpectedIndex == targetWord.count`:

- compute timeTaken
- award points once per word via `PointsService`
- stars rubric per common doc
- combo update per common doc
- celebration → advance

### Step 9: Background + Visual Polish

MVP visuals:

- water/pond gradient background
- subtle wave overlay (animated offset) if desired
- bubble particles (optional, Canvas)

### Step 10: Result Screen

After final word:

- show shared `GameResultView`

---

## Non-Goals (For MVP)

- Physics-based fishing hook mechanics
- Multi-touch net dragging
- Complex fish schooling AI



