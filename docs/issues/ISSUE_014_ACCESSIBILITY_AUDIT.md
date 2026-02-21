# ISSUE_014 – Accessibility Audit (Completed)

**GitHub:** [#27](https://github.com/cSquirrel/SpellPlay/issues/27)  
**Branch:** `feature/issue-014-accessibility-audit`

## Naming scheme (documented in CLAUDE.md)

- **accessibilityIdentifier:** `ScreenOrFeature_Element` (e.g. `ParentHome_SettingsButton`, `WordInput_SubmitButton`). Stable IDs for UI tests; dynamic suffixes only when needed (e.g. `TestCard_Name_\(test.name)`).
- **accessibilityLabel:** Required for icon-only buttons; optional override when default (e.g. button title) is clear.
- **accessibilityHint:** Where the action is not obvious (e.g. "Double tap to open settings").
- **Decorative images:** `.accessibilityHidden(true)` when the image adds no information beyond adjacent text.

## Audit scope

| Flow / screen        | Elements audited                                                                 | Status |
|----------------------|-----------------------------------------------------------------------------------|--------|
| Role selection       | Parent / Child buttons (labels, hints, identifiers)                               | Done   |
| Onboarding           | Get Started (identifier); decorative icon                                         | Done   |
| Parent home          | Settings (icon), Create test (icon), Test card Edit/Delete (icons), Empty state   | Done   |
| Child home           | Settings (icon), Child test card (label, hint)                                    | Done   |
| Empty state          | Action button (label, hint, identifier); decorative icon (hidden)               | Done   |
| Create / Edit test   | Speaker and Remove word (icon-only) labels/hints                                  | Done   |
| Practice             | Play Normal/Slow (labels, hints, identifiers), Help coin, Round transition play   | Done   |
| Word input           | Submit (label, hint, identifier)                                                  | Done   |
| Practice summary     | Practice Again, Back to Tests (hints)                                             | Done   |
| Game result          | Play Again, Different Game, Done (hints)                                          | Done   |
| All five games       | Close, result actions (identifiers/labels already present; hints added where needed) | Audited |
| Sync status          | Label + hint                                                                      | Done   |
| Role switcher        | Done (identifier), Parent/Child (hints)                                           | Done   |
| Balloon pop          | Balloon (label, hint; identifier on parent in BalloonPopView)                     | Done   |

## Gaps addressed

- **Icon-only buttons:** Settings (Parent/Child home), Create test, Edit/Delete test card, speaker and remove word in Create/Edit test, round transition play word — all have `accessibilityLabel` and `accessibilityHint` where appropriate.
- **Empty state:** Action button has `accessibilityIdentifier("EmptyState_ActionButton")`, label, and hint; decorative icon has `accessibilityHidden(true)`.
- **Practice:** Normal/Slow play buttons and Help coin have labels and hints; round transition list speaker buttons have label and hint.
- **WordInputView:** Submit area has `accessibilityLabel("Submit answer")` and `accessibilityHint` on the tappable control with `WordInput_SubmitButton`.

## Dynamic Type

- Key screens use semantic fonts and scalable layouts per existing design. No blocking truncation observed at largest Dynamic Type in scope; recommend manual check on device for very long test names and word lists.

## VoiceOver testing

- **Recommended manual checks:** Practice flow (play word, submit, help coin, round transition), one game (e.g. Word Builder or Balloon Pop): start, close, result screen. Focus order is default SwiftUI order; no custom reordering required for the audited flows.

## Tests added

- **SpellPlayUITests/AccessibilityTests.swift:** Verifies role selection, onboarding, parent home icon buttons, empty state action button, and (when navigable) practice screen WordInput and Submit have expected accessibility identifiers and are hittable.

## Conventions (CLAUDE.md)

- Interactive elements must have `accessibilityLabel` where default is unclear; icon-only buttons must have an explicit label.
- Use `accessibilityIdentifier` for UI test targets with the `ScreenOrFeature_Element` naming scheme.
- Use `accessibilityHint` for non-obvious actions.
- Mark decorative images with `.accessibilityHidden(true)`.
