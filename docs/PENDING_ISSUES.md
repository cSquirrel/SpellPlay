## Pending Issues

_Last updated: 2025-11-17_

**Validation Status:** All issues resolved ✅

### Resolved Issues

1. ✅ **Practice answer grading uses stale text** - Fixed in commit 7c92817
   - Fixed by capturing answer immediately before any delay, disabling input during feedback, and using Timer for delays.

2. ✅ **Onboarding never appears after first role selection** - Fixed in commit ee28b5c
   - Fixed by adding `.onChange(of: appState.selectedRole)` to watch for role changes and show onboarding when a role is selected.

3. ✅ **Duplicate removal scrambles test word order** - Fixed in commit ea4a5e1
   - Fixed by replacing `Array(Set(words))` with `removeDuplicatesPreservingOrder()` function that maintains insertion order.

4. ✅ **Single onboarding completion flag for both roles** - Fixed in commit eb474d4
   - Fixed by implementing per-role onboarding completion tracking using `hasCompletedOnboarding(for: role)` and `setOnboardingCompleted(for: role, completed: Bool)`.

5. ✅ **Direct DispatchQueue usage violates concurrency guidelines** - Fixed
   - Fixed by replacing `DispatchQueue.main.asyncAfter` with `.task` modifier using `Task.sleep` in `PracticeSummaryView.swift` and `CelebrationView.swift`. `PracticeView.swift` already uses `Timer` as requested.

---

**No pending issues remaining.**
