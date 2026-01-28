# Balloon Pop — Implementation Plan

## Goal

Implement **Balloon Pop**, where letter balloons float upward and the child taps the correct next letter (in order) to spell the word.

---

## Core Gameplay Loop

For each `Word`:

1. Show the target word as blanks with revealed letters filled as the child succeeds (e.g., `B _ L L _ _ N`)
2. Spawn balloons containing letters (correct + decoys)
3. Balloons float upward and can time out (leave the screen)
4. Child taps balloons:
   - correct letter **and** correct order → pop + fill next slot
   - wrong letter or wrong order → gentle feedback (shake), balloon still pops harmlessly
5. When word completed → award points + stars → celebrate → next word
6. End of list → results screen

---

## Step-by-Step Implementation

### Step 1: Create Feature Files

```
SpellPlay/Features/Child/Games/BalloonPop/
├── BalloonPopView.swift
└── BalloonView.swift
```

### Step 2: Define Balloon Model

In `BalloonPopView.swift` define:

- `struct Balloon: Identifiable { id, letter, x, yStart, speed, color, spawnedAt }`

Maintain:

- `activeBalloons: [Balloon]`
- `nextExpectedIndex: Int`
- `mistakesThisWord: Int`
- `wordStartTime: Date?`
- scoring: `score`, `comboCount`, `starsPerWord`

### Step 3: Animation Strategy

Use `TimelineView(.animation)` to update balloon positions based on elapsed time since spawn:

- compute y = yStart - (elapsed * speed)
- remove balloons when y < offscreen threshold

This avoids per-balloon timers and keeps animation smooth.

### Step 4: Balloon Rendering (`BalloonView`)

`BalloonView` responsibilities:

- Draw balloon shape (ellipse + small knot + string)
- Render the letter in bold, high contrast
- Provide tap handler
- Optional wobble animation (subtle)

Accessibility:

- `accessibilityLabel(\"Balloon letter \(letter)\")`
- `accessibilityIdentifier(\"BalloonPop_Balloon_\(letter)_\(id)\")`

### Step 5: Spawning Logic

On each word start:

1. Determine the set of letters to spawn:
   - always include required target letters (with duplicates)
   - add decoys (based on difficulty)
2. Start a repeating spawn cadence:
   - `easy`: slow, fewer balloons, fewer decoys
   - `medium`: baseline
   - `hard`: faster, more decoys, multiple balloons for same needed letter

Spawn positions:

- random X within safe bounds
- random initial y slightly below bottom edge

### Step 6: Tap Handling / Correctness

On balloon tap:

- expectedLetter = targetWord[targetWord.index(targetWord.startIndex, offsetBy: nextExpectedIndex)]
- if balloon.letter matches expectedLetter:
  - `nextExpectedIndex += 1`
  - show success animation (sparkle/confetti using `CelebrationView` style)
- else:
  - `mistakesThisWord += 1`
  - show gentle shake / “try again” feedback

Always remove the tapped balloon (pop).

### Step 7: Word Completion

When `nextExpectedIndex == targetWord.count`:

- compute timeTaken from `wordStartTime`
- award points **once per word** via `PointsService`
- compute stars:
  - 3: no mistakes + fast
  - 2: no mistakes
  - 1: mistakes
- combo:
  - if no mistakes: `comboCount += 1`
  - else: `comboCount = 0`
- brief celebration, then advance to next word

### Step 8: Background + Visual Polish

MVP visuals:

- gradient sky background + simple cloud shapes
- balloon colors from a fixed palette

Optional:

- small particle sparkles on correct tap (Canvas)

### Step 9: Results Screen

After final word:

- show `GameResultView` with totals and replay options

### Step 10: Accessibility + UI Testing IDs

- Root: `BalloonPop_Root`
- Word display: `BalloonPop_WordDisplay`
- Score: `BalloonPop_Score`
- Combo: `BalloonPop_Combo`

---

## Non-Goals (For MVP)

- Physics collisions (SpriteKit)
- Shooting mechanic (tap is sufficient)
- Per-letter audio hints (beyond TTS word playback)


