# Feature: Help Coins

## Overview
Allow children to "buy" a hint (reveal next letter) during spelling practice using a limited supply of "Help Coins" configured by the parent.

## User Stories

### Parent
- As a parent, I want to configure the number of help coins available for a test so that I can control how much assistance my child gets.
- Default number of coins should be 3.

### Child
- As a child, I want to see how many help coins I have left during a practice session.
- As a child, I want to click a button to use a coin and have the next correct letter revealed to me.

## Implementation Plan

### 1. Data Model Changes
**File:** `SpellPlay/Models/SpellingTest.swift`
- Add `helpCoins` property to `SpellingTest`.
- Default value: `3`.
- Migration: SwiftData should handle this lightweight migration automatically (adding a property with default).

### 2. Parent UI Updates
**File:** `SpellPlay/Features/Parent/CreateTestView.swift`
- Add `Stepper` for `helpCoins` (Range: 0-10).

**File:** `SpellPlay/Features/Parent/EditTestView.swift`
- Add `Stepper` for `helpCoins`.

### 3. Practice Logic
**File:** `SpellPlay/Features/Child/ViewModels/PracticeViewModel.swift`
- Add state `availableCoins`.
- Initialize `availableCoins` from `test.helpCoins`.
- Implement `useHelpCoin()` method:
    - Check if coins > 0.
    - Determine current input state.
    - Append next correct character from target word.
    - Decrement `availableCoins`.

### 4. Practice UI Updates
**File:** `SpellPlay/Features/Child/PracticeView.swift`
- Add "Help Coin" button to the UI (likely near the input field).
- Show remaining count.
- Disable if count is 0 or word is fully revealed.

## Technical Notes
- **Coin Logic Detail**:
    - The "reveal" feature will ensure the user gets back on track.
    - Logic:
        1. Identify the correct prefix of the target word that matches the user's current input.
        2. If the user's input has errors (doesn't match prefix), correct them up to the current length.
        3. Append the next correct letter.

