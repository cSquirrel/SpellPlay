## Pending Issues

_Last updated: 2025-11-17_

1. **Practice answer grading uses stale text**
   - `PracticeView.submitAnswer()` waits before calling into `PracticeViewModel.submitAnswer()`, which re-reads `userAnswer`. Kids can edit the field during the delay, so the recorded score may not match what they originally submitted. Evaluate immediately or pass the captured answer through before any delay.  
   - Path: `SpellPlay/Features/Child/PracticeView.swift`, `SpellPlay/Features/Child/ViewModels/PracticeViewModel.swift`
   - Suggested fix: Capture `viewModel.userAnswer` in `submitAnswer()`, pass it down to the view model (or evaluate there immediately), disable the text field while feedback animates, and drive the delays via `Task.sleep` so grading always reflects the typed answer.

2. **Onboarding never appears after first role selection**
   - `showOnboarding` is only set inside `.onAppear`. On a fresh install, choosing a role later never flips the flag back to `true`, so the onboarding sheet is never presented. Observe role changes or move the logic into `AppState` setters so onboarding shows up as intended.  
   - Path: `SpellPlay/App/SpellPlayApp.swift`
   - Suggested fix: Watch `appState.selectedRole` via `.onChange` (or move onboarding logic into the setter) and toggle `showOnboarding` when a role becomes non-nil and `hasCompletedOnboarding(role)` is false. Add unit coverage to ensure onboarding appears for the first role selection.

3. **Word entry claims comma support but parser ignores commas**
   - The UI copy tells parents to enter words separated by commas or new lines, yet `String.splitIntoWords()` only splits on whitespace. Words like “cat, dog” end up stored with commas, breaking pronunciation and answer matching. Expand the parser (and add tests) to split on commas as well.  
   - Path: `SpellPlay/Utilities/Extensions/String+Extensions.swift`
   - Suggested fix: Update `splitIntoWords()` to split on commas and whitespace (e.g., use `CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ","))`), trim punctuation, and add Swift Testing coverage for comma/new-line combinations.

4. **Duplicate removal scrambles test word order**
   - `CreateTestView.addWords()` dedupes via `Array(Set(words))`, which randomizes the entire list because sets are unordered. Parents lose their curated ordering each time they add words. Use an order-preserving dedupe instead.  
   - Path: `SpellPlay/Features/Parent/CreateTestView.swift`
   - Suggested fix: Replace `Array(Set(words))` with an order-preserving approach (e.g., iterate and insert only when `seen` doesn’t contain the word) so first occurrences remain in the sequence parents defined; consider moving the logic into a helper tested with deterministic input.

5. **Single onboarding completion flag for both roles**
   - A single `hasCompletedOnboarding` key in `UserDefaults` covers both parent and child experiences. Once one role completes onboarding, the other role will never see its tailored guide. Persist completion per role so each flow can display its intro the first time.  
   - Path: `SpellPlay/App/AppState.swift`
   - Suggested fix: Track per-role completion keys (e.g., `hasCompletedOnboarding_parent`, `_child`) or store a dictionary keyed by `UserRole`, and update logic so each role’s onboarding runs once; provide migration defaults for existing installs.

6. **Direct DispatchQueue usage violates concurrency guidelines**
   - Multiple SwiftUI views (`PracticeView`, `PracticeSummaryView`, `CelebrationView`) use `DispatchQueue.main.asyncAfter` for delays. Project rules require using Swift Concurrency constructs (`Task`, `Task.sleep`, `.task(id:)`) so work cancels automatically with the view lifecycle. Refactor these timers accordingly.  
   - Paths: `SpellPlay/Features/Child/PracticeView.swift`, `SpellPlay/Features/Child/PracticeSummaryView.swift`, `SpellPlay/Components/CelebrationView.swift`
   - Suggested fix: Replace `DispatchQueue.main.asyncAfter` calls with `Task { try? await Task.sleep(...) }` scoped to the view’s lifecycle (e.g., via `.task(id:)` or `withAnimation` inside async contexts) so timers cancel when the view disappears and conform to the Swift Concurrency rules.
