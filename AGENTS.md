# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

WordCraft (Xcode project name: SpellPlay) is a native iOS spelling-practice app built with Swift 6 / SwiftUI / SwiftData. It has no third-party dependencies; everything uses Apple frameworks. See `CLAUDE.md` and `README.md` for full architecture details.

### Environment constraints (Linux Cloud VM)

This is an **iOS-only Xcode project**. The Cloud VM runs Linux (Ubuntu 24.04), so:

- **No Xcode / xcodebuild** — full project build and UI tests require macOS with Xcode 16.1+.
- **No iOS Simulator** — cannot run the app or UI tests on Linux.
- **SwiftUI / SwiftData / AVFoundation** files (71 of 81 `.swift` files) cannot be compiled on Linux because those frameworks are Apple-only.

### What works on Linux

| Tool | Command | Notes |
|---|---|---|
| **SwiftFormat lint** | `swiftformat SpellPlay SpellPlayUITests --config .swiftformat --lint` | Validates code style for all 81 Swift files |
| **Swift syntax parse** | `swiftc -parse <file>` | Works for Foundation-only files (10 files) |
| **Unit tests (Foundation-only)** | Create a temporary SPM package wrapping the pure-logic sources + tests, then `swift test` | `GameResultServiceTests` (8 tests) can run on Linux — see below |

### Running Foundation-only unit tests on Linux

The project has one test file (`SpellPlayTests/GameResultServiceTests.swift`) that tests pure Foundation logic (`GameResultService`, `PointsService`, `GameModels`). To run it:

1. Create a temp SPM package at `/tmp/SpellPlayTestPkg` with `Sources/WordCraft/` and `Tests/WordCraftTests/`.
2. Copy `SpellPlay/Services/PointsService.swift`, `SpellPlay/Features/Child/Games/Common/GameResultService.swift`, and `SpellPlay/Features/Child/Games/Common/GameModels.swift` into `Sources/WordCraft/`.
3. Copy `SpellPlayTests/GameResultServiceTests.swift` into `Tests/WordCraftTests/`.
4. Create a `Package.swift` with a `WordCraft` library target and `WordCraftTests` test target.
5. Run `swift test` in that directory.

### Lint / format commands

Refer to `Makefile` for standard commands (`make format`, `make lint`, `make format-check`). SwiftFormat binary is installed at `/usr/local/bin/swiftformat`.

### Key gotchas

- The README and `CLAUDE.md` reference a `SpellPlayPackage/` SPM package, but **no `Package.swift` exists in the repo**. All source lives directly in the Xcode project under `SpellPlay/`.
- The Xcode project's actual minimum deployment target is iOS 18.4 (set in pbxproj), even though xcconfig says iOS 17.0.
- SwiftFormat lint reports pre-existing issues (9 of 79 files); these are in the existing codebase.
- Swift toolchain is managed via `swiftly` — source `$HOME/.local/share/swiftly/env.sh` to get `swift` on PATH.
