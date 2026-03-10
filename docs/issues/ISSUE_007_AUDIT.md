# ISSUE_007 – Task to .task Modifier – Full Audit

**Issue:** [#20](https://github.com/cSquirrel/SpellPlay/issues/20)  
**Branch:** feature/issue-007-task-modifier

## Full list of `Task { }` usages (before changes)

| File | Line | Context | Classification | Action |
|------|------|---------|----------------|--------|
| FishCatcherView.swift | 311 | resetAll() – await startWord() | View (reset) | Replace with .task(id: gameResetID) |
| FishCatcherView.swift | 471 | showCelebrationTransient – sleep + hide | View (celebration) | Replace with .task(id: celebrationDismissID) |
| RocketLaunchView.swift | 519 | triggerLaunch() – countdown + launch | Button action | Keep; add comment (button-triggered) |
| WordBuilderView.swift | 216 | Incorrect placement – wiggle reset after 600ms | View (gesture) | Replace with .task(id: wiggleSlotIndex) |
| WordBuilderView.swift | 383 | resetAll() – await startWord() | View (reset) | Replace with .task(id: gameResetID) |
| WordBuilderView.swift | 397 | showCelebrationTransient – sleep + hide | View (celebration) | Replace with .task(id: celebrationDismissID) |
| PracticeView.swift | 388 | Timer callback – TTS first word of round | View (Timer) | Replace with .task(id:) trigger |
| PracticeView.swift | 447 | Timer callback – continueToNext() | View (Timer) | Replace with .task(id:) trigger |
| PracticeView.swift | 492 | Timer callback – TTS next word | View (Timer) | Replace with .task(id:) trigger |
| TTSService.swift | 73 | AVSpeechSynthesizerDelegate didFinish | Delegate callback | Do not replace; add comment |
| TTSService.swift | 79 | AVSpeechSynthesizerDelegate didCancel | Delegate callback | Do not replace; add comment |
| CloudSyncService.swift | 73 | checkAccountStatus + startMonitoring | Service | Leave as-is (service, not view) |
| CloudSyncService.swift | 147 | for await notifications | Service | Leave as-is (service, not view) |
| SyncStatusView.swift | 89 | Button – refreshSync() | Button action | Keep; add one-line comment |
| LevelProgressView.swift | 124 | onAppear – delayed showConfetti | View onAppear | Replace with .task |
| AchievementBadgeView.swift | 85 | onAppear – delayed showConfetti | View onAppear | Replace with .task |

## Post-change: remaining Task in view code

- **RocketLaunchView** triggerLaunch(): Task kept by design (button-triggered multi-step async); comment added.
- **SyncStatusView** Button: Task kept (explicit user action); comment added.
- **TTSService** delegate callbacks: unchanged; comments added.

## Verification

- No `Task { @MainActor in }` in view bodies or onAppear for lifecycle work.
- TTSService delegate Tasks unchanged.
- Remaining Tasks in view code documented.
