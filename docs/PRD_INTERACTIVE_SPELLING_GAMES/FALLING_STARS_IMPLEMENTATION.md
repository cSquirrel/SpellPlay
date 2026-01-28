# Falling Stars — Implementation Plan

## Goal

Implement **Falling Stars**, where glowing star letters drift down the screen. Kids must tap the correct next letter (in spelling order) before stars fade. Correct taps add to a “constellation” that visually forms the word.

---

## Core Gameplay Loop

For each `Word`:

1. Show the target word at the top with progress (e.g., filled vs. pending letters).
2. Spawn falling star letters (correct + decoys) from random horizontal positions.
3. Stars fall and eventually fade if not tapped.
4. Kid taps stars:
   - Correct next letter → star is collected, added to the constellation.
   - Wrong letter/order → “miss” feedback, star fades.
5. When all letters are collected → award points + stars → constellation completes → move to next word.
6. After final word → show `GameResultView`.

---

## Step-by-Step Implementation

### Step 1: Create Feature Files

Create:

```text
SpellPlay/Features/Child/Games/FallingStars/
├── FallingStarsView.swift
└── StarView.swift
```

### Step 2: Define Star Model

In `FallingStarsView.swift`:

- `struct Star: Identifiable { id, letter, startX, startY, fallSpeed, spawnTime, lifetime }`

State to maintain:

- `words: [Word]`
- `currentWordIndex: Int`
- `nextExpectedIndex: Int`
- `activeStars: [Star]`
- `constellationPoints: [CGPoint]` (positions of correctly tapped stars)
- `score`, `comboCount`, `comboMultiplier`, `totalStars`
- `mistakesThisWord`, `totalMistakes`
- `wordStartTime: Date?`
- `phase: GamePhase`
- `difficulty: GameDifficulty`

### Step 3: Background & Twinkling Sky

Use:

- A gradient night-sky background (purple/blue).
- `Canvas` or `TimelineView` to render twinkling small background stars:
  - Random fixed positions.
  - Slight opacity oscillation for “twinkle”.

Keep the background light-weight and independent of gameplay objects.

### Step 4: `StarView` Rendering

`StarView` responsibilities:

- Render a glowing star shape:
  - A custom `StarShape` or overlay of polygons/circles.
- Centered letter in bold, high-contrast text.
- Glow/pulse animation via scale/opacity.
- Tap handler closure.

Accessibility:

- `accessibilityLabel("Star letter \(letter)")`
- `accessibilityIdentifier("FallingStars_Star_\(letter)_\(id)")`

### Step 5: Falling Animation Strategy

Use `TimelineView(.animation)`:

```swift
let elapsed = now.timeIntervalSince(star.spawnTime)
let y = startY + CGFloat(elapsed) * star.fallSpeed
let lifeProgress = elapsed / star.lifetime
let opacity = max(0, 1.0 - lifeProgress)
```

- Remove stars when:
  - They move past bottom edge + padding, or
  - `elapsed >= star.lifetime` (fully faded).

### Step 6: Star Spawning Logic

Per word:

1. Determine the next expected letter.
2. Periodically spawn stars:
   - Some stars with the expected letter.
   - Some decoy letters.
3. Positions:
   - `startX`: random along the width, within safe margins.
   - `startY`: slightly above the top of the visible area.

Difficulty knobs:

- **Easy**: slower fall, longer lifetime, more expected letters than decoys.
- **Medium**: moderate speed, balanced decoys.
- **Hard**: faster fall, shorter lifetime, many simultaneous stars and decoys.

### Step 7: Constellation Effect

When a correct star is tapped:

- Capture its current position in view-space.
- Append to `constellationPoints`.
- Render a `Path` or small `Canvas` overlay that connects points in order:
  - Lines between consecutive points.
  - Optional small glow at each point.

This visually “draws” the word as a constellation.

### Step 8: Tap Handling / Correctness

On star tap:

1. Remove the star from `activeStars`.
2. Determine `expectedLetter = targetWord[nextExpectedIndex]`.
3. Case-insensitive compare:
   - If match:
     - Increment `nextExpectedIndex`.
     - Add star’s position to `constellationPoints`.
     - Check for word completion.
   - Else:
     - Increment `mistakesThisWord` and `totalMistakes`.
     - Trigger a small “miss” animation:
       - E.g., hue-shift to red and fade quickly.

### Step 9: Word Completion + Scoring

When `nextExpectedIndex == targetWord.count`:

- Compute `timeTaken`.
- Combo:
  - If no mistakes this word: `comboCount += 1`.
  - Else: `comboCount = 0`.
- `comboMultiplier = PointsService.getComboMultiplier(for: comboCount)`.
- Use `PointsService.calculatePoints` to get points.
- Compute stars as per common rubric:
  - 3: fast + no mistakes.
  - 2: no mistakes.
  - 1: at least one mistake.
- Show `CelebrationView` with a star-themed message (e.g., “Star Collector!”).
- Advance to next word or finish with `GameResultView`.

Reset:

- `constellationPoints.removeAll()` for the next word.

### Step 10: Layout + Controls

Top area:

- `GameProgressView` (points, combo, round/word progress).
- Word display showing found vs. pending letters (e.g., filled vs. greyed letters).

Bottom area:

- A simple replay button for TTS:
  - `FallingStars_SpeakWordButton`.

No extra controls are needed for MVP.

### Step 11: Accessibility + UI Testing IDs

Add identifiers:

- Root: `FallingStars_Root`
- Word display: `FallingStars_WordDisplay`
- Score: `FallingStars_Score`
- Combo: `FallingStars_Combo`
- Progress: `FallingStars_ProgressText`

---

## Non-Goals (For MVP)

- Elaborate particle trails and meteor streaks (keep glow + simple motion).
- Physics-based collisions between stars.
- Dynamic star rebalancing based on performance (can be a later enhancement).

# Falling Stars — Implementation Plan

## Goal

Implement **Falling Stars**, where glowing star letters drift down the screen. The child taps the correct next letter (in order) before stars fade. Correct taps add to a “constellation” that visually forms the word.

---

## Core Gameplay Loop

For each `Word`:

1. Show target word at top (slots / progress)
2. Spawn falling star letters (correct + decoys)
3. Stars drift down and fade if not tapped in time
4. Child taps stars:
   - correct letter + correct order → add to constellation, connect lines
   - wrong letter/order → star fades with gentle “miss” effect
5. When word complete → award points + stars → celebration → next word
6. End → results

---

## Step-by-Step Implementation

### Step 1: Create Feature Files

```
SpellPlay/Features/Child/Games/FallingStars/
├── FallingStarsView.swift
└── StarView.swift
```

### Step 2: Define Star Model

In `FallingStarsView.swift` define:

- `struct Star: Identifiable { id, letter, startX, startY, fallSpeed, spawnedAt, lifetime }`

Maintain:

- `activeStars: [Star]`
- `nextExpectedIndex: Int`
- `constellationPoints: [CGPoint]` (positions of correctly tapped stars)
- `mistakesThisWord: Int`
- `wordStartTime: Date?`
- scoring: `score`, `comboCount`, `starsPerWord`

### Step 3: Background Rendering

Use:

- Gradient night sky background
- `Canvas` for twinkling background stars (random but stable across frames using a seed)

### Step 4: Star Rendering (`StarView`)

`StarView` responsibilities:

- glowing star sprite/shape
- letter overlay in bold
- subtle pulse animation for glow
- tap handler

Accessibility:

- `accessibilityLabel(\"Star letter \(letter)\")`
- `accessibilityIdentifier(\"FallingStars_Star_\(letter)_\(id)\")`

### Step 5: Falling Animation Strategy

Use `TimelineView(.animation)`:

- y = startY + (elapsed * fallSpeed)
- opacity decreases as `elapsed` approaches `lifetime`
- remove stars after they exceed lifetime or move offscreen

### Step 6: Constellation Effect

Maintain `constellationPoints` for correct taps and render connecting lines:

- Use a lightweight `Path` overlay connecting points in order
- Optionally animate line drawing when a new point is added

### Step 7: Spawning Logic

Per word:

- Spawn letters with more weight on the next expected letter, plus decoys
- Difficulty knobs:
  - `easy`: sequential letters appear more often, slower fall, longer lifetime
  - `medium`: randomized positions, moderate fall
  - `hard`: multiple stars at once, faster fall, shorter lifetime, more decoys

### Step 8: Tap Handling

On star tap:

- expectedLetter = targetWord[nextExpectedIndex]
- if matches:
  - `nextExpectedIndex += 1`
  - append star’s current position to `constellationPoints`
  - remove tapped star
- else:
  - `mistakesThisWord += 1`
  - fade tapped star quickly (“miss”)

### Step 9: Word Completion + Scoring

When `nextExpectedIndex == targetWord.count`:

- compute timeTaken
- award points once per word via `PointsService`
- stars rubric per common doc
- combo update per common doc
- short celebration, then next word

Reset `constellationPoints` per word.

### Step 10: Results Screen

After final word:

- show shared `GameResultView`

---

## Non-Goals (For MVP)

- Particle-heavy shooting star trails (optional later)
- Complex constellation animations beyond simple lines
- SpriteKit integration



