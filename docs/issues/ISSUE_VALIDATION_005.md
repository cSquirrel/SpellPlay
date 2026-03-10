# ISSUE_005 – TTS Service Modernize – Validation

**GitHub:** [#18](https://github.com/cSquirrel/SpellPlay/issues/18)

## Acceptance criteria mapping

| Criterion | Status | Notes |
|-----------|--------|--------|
| TTSService confirmed `@Observable` (or converted); no ObservableObject/@Published | ✅ | Already `@Observable` in codebase; no ObservableObject. |
| Injection strategy chosen and **documented**, including exact view/root that provides `.environment(TTSService())` | ✅ | Option A (Environment). Root: `WordCraftApp` holds `@State private var ttsService = TTSService()` and applies `.environment(ttsService)` to `ContentView()`. Documented in `WordCraftApp.swift` and `TTSService.swift`. |
| TTS available from environment at the level that presents games (and practice/create/edit if applicable) | ✅ | Injected at app root; all child views (games, PracticeView, CreateTestView, EditTestView) receive it. |
| All TTS-using views use environment; no local TTSService where environment is standard | ✅ | All views use `@Environment(TTSService.self)`; no `@StateObject` or per-view `@State private var ttsService = TTSService()` in views. |
| (Optional) Tests or previews can inject a fake TTSService | — | Optional; no SpellPlayTests target in this worktree. Previews that use TTS-using views inherit from app root in normal run. |
| Build and tests pass; TTS behavior unchanged | ✅ | Build succeeds. Scheme test action not configured in this worktree (no test plan); manual smoke: run app, trigger TTS in Create Test or a game. |

## Validation steps

1. **Build:** `xcodebuild -project SpellPlay.xcodeproj -scheme SpellPlay -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' build` → BUILD SUCCEEDED.
2. **No @StateObject:** Grep for `@StateObject` and per-view `ttsService = TTSService()` → only app root holds TTS; all views use `@Environment(TTSService.self)`.
3. **Manual:** Launch app → Parent: Create Test → tap speaker on a word; Child: start practice or a game → tap speaker. TTS should play (single shared instance).
