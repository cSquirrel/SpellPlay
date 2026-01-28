# Rocket Launch — Implementation Plan

## Goal

Implement **Rocket Launch**, where kids type the correct letters in sequence to fuel a rocket and launch it. Each correct letter increases fuel and rumble; completing the word triggers a launch animation.

This game emphasizes **keyboard input** and reinforces auditory-to-motor spelling.

---

## Core Gameplay Loop

For each `Word`:

1. Show a **mission objective** with the word (briefly or as blanks/greyed letters).
2. Kid types letters in order (via on-screen keyboard for kids).
3. Each correct letter:
   - Increases fuel gauge.
   - Increases rocket rumble/intensity.
4. Wrong letter:
   - Shows a gentle “try again” feedback (shake / red flash).
   - Does **not** advance the position.
5. When the full word is correctly typed:
   - Start a short countdown (3-2-1).
   - Launch the rocket with an upward animation and celebration.
6. After all words:
   - Show `GameResultView`.

---

## Step-by-Step Implementation

### Step 1: Create Feature Files

Create:

```text
SpellPlay/Features/Child/Games/RocketLaunch/
├── RocketLaunchView.swift
└── RocketView.swift
```

### Step 2: Define Game State in `RocketLaunchView`

In `RocketLaunchView.swift`:

- `words: [Word]`
- `currentWordIndex: Int`
- `typedText: String` (what the kid has entered so far)
- `fuelLevel: Double` (0.0–1.0)
- `isLaunching: Bool`
- `rocketOffset: CGFloat` (for launch animation)
- `mistakesThisWord: Int`, `totalMistakes: Int`
- `score`, `comboCount`, `comboMultiplier`, `totalStars`
- `wordStartTime: Date?`
- `phase: GamePhase`
- `difficulty: GameDifficulty`

### Step 3: `RocketView` Rendering

`RocketView` responsibilities:

- Draw rocket body:
  - Simple capsule + fins + nose cone.
- Show animated flame:
  - Flame size/intensity based on `fuelLevel` or `isLaunching`.
- Slight horizontal rumble when fueled.

Inputs:

- `fuelLevel: Double`
- `isLaunching: Bool`
- `verticalOffset: CGFloat`

Layout:

- On top of a launch-pad background (ground + sky).

### Step 4: Fuel Gauge & Mission UI

Next to or under the rocket:

- **Fuel gauge**:
  - Vertical or horizontal bar filled proportionally to `fuelLevel`.
  - Optional labels (Empty → Full).
- **Mission objective**:
  - Title: “Mission Word” / “Objective”.
  - Word display:
    - Show letters typed vs. pending:
      - Typed letters: dark/primary.
      - Pending letters: greyed-out.

### Step 5: Input Handling (On-Screen Keyboard)

Use a custom on-screen keyboard for consistency and controllability:

- Layout a simple QWERTY or alphabet grid:
  - Large, kid-friendly buttons.
  - Possibly only show letters present in the current word on easy mode.

When a key is tapped:

1. Determine expected letter:
   - `expectedLetter = targetWord[typedText.count]`, if within bounds.
2. Compare (case-insensitive) with tapped letter:
   - **Correct**:
     - Append to `typedText`.
     - Update `fuelLevel = Double(typedText.count) / Double(targetWord.count)`.
     - If word is complete → trigger launch.
   - **Incorrect**:
     - Increment `mistakesThisWord` and `totalMistakes`.
     - Trigger shake/flash on the rocket or keyboard row.

### Step 6: Launch Sequence

When the word is fully typed:

1. Optionally show a countdown:
   - “3… 2… 1…” overlay.
2. Start launch animation:
   - Set `isLaunching = true`.
   - Animate `rocketOffset` upwards (e.g., `-UIScreen.main.bounds.height - padding`) with `withAnimation(.easeIn(duration: X))`.
3. When animation completes:
   - Reset `rocketOffset` to initial for next word.
   - Advance to next word or end the game.

During launch:

- Optionally show a trail of smoke/flame using simple shapes or `Canvas`.

### Step 7: Difficulty Scaling

Tie into `GameDifficulty`:

- **Easy**:
  - Show full word always (greyed where not typed).
  - Allow backspacing / correction.
  - No time pressure.
- **Medium**:
  - Show word briefly, then hide or show only blanks/greyed letters.
  - Mild visual indication for slow typing (e.g., pulsing timer).
- **Hard**:
  - Word shown only at start (audio + text), then hidden.
  - Optional time component:
    - Faster completion → extra points/stars via `PointsService` `timeTaken`.

### Step 8: Scoring & Stars

On each word completion:

1. Compute `timeTaken = Date() - wordStartTime`.
2. Combo:
   - If `mistakesThisWord == 0`: `comboCount += 1`.
   - Else: `comboCount = 0`.
3. `comboMultiplier = PointsService.getComboMultiplier(for: comboCount)`.
4. Use `PointsService.calculatePoints(isCorrect: true, comboCount: comboCount, timeTaken: timeTaken, isFirstTry: mistakesThisWord == 0)`.
5. Stars:
   - 3: fast + no mistakes.
   - 2: no mistakes.
   - 1: at least one mistake.

Total session stats:

- Accumulate `score`, `totalStars`, `totalMistakes`.
- At the end, pass them into `GameResultView`.

### Step 9: TTS Integration

Use `TTSService`:

- Speak the word at the beginning of each round.
- Provide a “Hear Word” button (normal + slow options if desired).

Accessibility:

- `RocketLaunch_SpeakWordButton`.

### Step 10: Layout & Controls Summary

Vertical layout:

- **Top**:
  - `GameProgressView` (points, combo, progress).
  - Mission objective word display.
- **Middle**:
  - `RocketView` + fuel gauge + maybe a small “altitude/orbit” indicator.
- **Bottom**:
  - On-screen keyboard grid.

Keep controls large and well spaced; avoid cluttering the central rocket area.

### Step 11: Accessibility + UI Testing IDs

Add identifiers:

- Root: `RocketLaunch_Root`
- Mission word display: `RocketLaunch_WordDisplay`
- Fuel gauge: `RocketLaunch_FuelGauge`
- Score: `RocketLaunch_Score`
- Combo: `RocketLaunch_Combo`
- Keyboard keys: `RocketLaunch_Key_<letter>`

---

## Non-Goals (For MVP)

- Complex orbital mechanics or multi-stage rockets.
- Physical keyboard handling (focus on on-screen keyboard for kids).
- Progression system tied to rocket height/orbit beyond visual feedback.


