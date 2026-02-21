# ISSUE_013 – Model Context Access – Validation

**GitHub:** [#26](https://github.com/cSquirrel/SpellPlay/issues/26)  
**Branch:** feature/issue-013-model-context-access

## Acceptance criteria mapping

| Criterion | Validation |
|-----------|------------|
| Chosen ModelContext access pattern is documented, including exception (e.g. PracticeSessionState) | **docs/ARCHITECTURE.md** – section "ModelContext Access" documents pattern, call sites, and PracticeSessionState as exception |
| One documented pattern and list of conforming call sites (or documented exceptions) | ARCHITECTURE.md lists AchievementService, StreakService, PracticeSessionState and call sites |
| Views (or app root) clearly own and pass ModelContext where needed; ModelContext main-actor only | Documented in ARCHITECTURE.md; views use @Environment(\.modelContext) and pass into services |
| Tests can inject or mock context (e.g. in-memory ModelContainer) | Unit test `inMemoryContainer_canInjectForTests` in SpellPlayTests validates in-memory container + context passed to service |
| No new Swift 6 / Sendable / concurrency warnings from context passing changes | Build with strict concurrency; documentation-only + optional test – no service refactor in this PR |
| Build and tests pass; data persistence behavior unchanged | QA: run build and full test suite; manual smoke (create test, practice, complete; achievements/streaks) |

## Required unit tests (Swift Testing)

| Test | Validates | Location |
|------|-----------|----------|
| `inMemoryContainer_canInjectForTests` | In-memory ModelContainer and context passed to service; no crash | SpellPlayTests/ModelContextAccessTests.swift |
| `serviceReceivesContext_fromCaller` | Optional: service method receives context and succeeds with in-memory context | Same file if refactor done |

**Note:** SpellPlayTests target builds with the project. To run unit tests: in Xcode select the SpellPlayTests target and run tests (⌘U), or run the SpellPlayTests bundle from command line. The SpellPlay scheme’s test action uses a test plan that currently references SpellPlayUITests only.

## QA checklist

- [ ] Build succeeds (simulator).
- [ ] All unit tests pass (SpellPlayTests).
- [ ] All UI tests pass (SpellPlayUITests) if run.
- [ ] docs/ARCHITECTURE.md is clear and matches code (views pass context; PracticeSessionState exception).
- [ ] No new concurrency/Sendable warnings.
- [ ] Manual: create test, run practice, complete session; confirm data saved and achievements/streaks update if applicable.
