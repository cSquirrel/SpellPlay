## Pending Issues

1. **Practice answer grading uses stale text**
   - `PracticeView.submitAnswer()` waits before calling into `PracticeViewModel.submitAnswer()`, which re-reads `userAnswer`. Kids can edit the field during the delay, so the recorded score may not match what they originally submitted. Evaluate immediately or pass the captured answer through before any delay.  
   - Path: `SpellPlay/Features/Child/PracticeView.swift`, `SpellPlay/Features/Child/ViewModels/PracticeViewModel.swift`

2. **Onboarding never appears after first role selection**
   - `showOnboarding` is only set inside `.onAppear`. On a fresh install, choosing a role later never flips the flag back to `true`, so the onboarding sheet is never presented. Observe role changes or move the logic into `AppState` setters so onboarding shows up as intended.  
   - Path: `SpellPlay/App/SpellPlayApp.swift`

3. **Word entry claims comma support but parser ignores commas**
   - The UI copy tells parents to enter words separated by commas or new lines, yet `String.splitIntoWords()` only splits on whitespace. Words like “cat, dog” end up stored with commas, breaking pronunciation and answer matching. Expand the parser (and add tests) to split on commas as well.  
   - Path: `SpellPlay/Utilities/Extensions/String+Extensions.swift`

4. **Duplicate removal scrambles test word order**
   - `CreateTestView.addWords()` dedupes via `Array(Set(words))`, which randomizes the entire list because sets are unordered. Parents lose their curated ordering each time they add words. Use an order-preserving dedupe instead.  
   - Path: `SpellPlay/Features/Parent/CreateTestView.swift`

5. **Single onboarding completion flag for both roles**
   - A single `hasCompletedOnboarding` key in `UserDefaults` covers both parent and child experiences. Once one role completes onboarding, the other role will never see its tailored guide. Persist completion per role so each flow can display its intro the first time.  
   - Path: `SpellPlay/App/AppState.swift`

6. **Direct DispatchQueue usage violates concurrency guidelines**
   - Multiple SwiftUI views (`PracticeView`, `PracticeSummaryView`, `CelebrationView`) use `DispatchQueue.main.asyncAfter` for delays. Project rules require using Swift Concurrency constructs (`Task`, `Task.sleep`, `.task(id:)`) so work cancels automatically with the view lifecycle. Refactor these timers accordingly.  
   - Paths: `SpellPlay/Features/Child/PracticeView.swift`, `SpellPlay/Features/Child/PracticeSummaryView.swift`, `SpellPlay/Components/CelebrationView.swift`
