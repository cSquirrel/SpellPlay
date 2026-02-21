# SpellPlay Architecture

This document captures key architecture decisions and patterns for the SpellPlay iOS app.

## ModelContext Access

**Decision:** Views own `ModelContext` and pass it into services that need it. Services that perform SwiftData operations receive context via initializer (current implementation) or via method parameters (preferred for new code). `ModelContext` is main-actor only; tests use an in-memory `ModelContainer` and pass the resulting context.

### Standard Pattern

1. **Views** obtain `ModelContext` from the environment:
   ```swift
   @Environment(\.modelContext) private var modelContext
   ```
2. **Call sites** pass `modelContext` when creating or calling services that need persistence:
   - **StatsView, ChildHomeView, StatsCardView:** Create `AchievementService(modelContext:)` or `StreakService(modelContext:)` with `@Environment(\.modelContext)` and use them in that view.
   - **PracticeSessionState (exception):** Receives `modelContext` in `setup(test:modelContext:)` and creates `AchievementService` and `StreakService` with that context. The session state holds the context and services for the lifetime of the practice session.

### Current Conforming Types

| Type                  | How it receives context | Call sites |
|-----------------------|-------------------------|------------|
| AchievementService    | `init(modelContext:)`   | StatsView, StatsCardView, PracticeSessionState.setup |
| StreakService        | `init(modelContext:)`   | ChildHomeView, StatsView, PracticeSessionState.setup |
| PracticeSessionState | `setup(test:modelContext:)` | PracticeView (passes `@Environment(\.modelContext)` into `setup`) |

### Exception: PracticeSessionState

**PracticeSessionState** is the allowed exception: it stores `modelContext` and creates `AchievementService` and `StreakService` in `setup(test:modelContext:)`. The view (`PracticeView`) does not hold the context; it passes it once at session start. This keeps the practice flow simple while still having a single place where context enters the session. Future refactors may move to “view passes context into each service method” and remove stored context from `PracticeSessionState`; see coordination with issue #22 (Remove Practice View Model).

### Testing

- **Unit tests** that need persistence must create an in-memory `ModelContainer` (same schema as the app), obtain a `ModelContext` from it, and pass that context into service initializers or methods.
- **Main-actor isolation:** `ModelContext` is main-actor only; tests that use it should run on the main actor (e.g. `@MainActor` or `@Test` with main-actor context).
- No production code should assume a process-wide or environment-injected `ModelContext`; the explicit pass-from-view (or from session setup) pattern keeps dependencies clear and testable.

### Alternatives Considered

- **A – View passes context:** Views get `@Environment(\.modelContext)` and pass to service methods. Services are stateless or do not hold context. *(Recommended for new code.)*
- **B – Service holds context:** Services created with context in the view (e.g. `@State` or factory). Current pattern for `AchievementService` and `StreakService`.
- **C – Protocol + injection:** A `ModelContextProviding` or `DataService` protocol with dependency injection for testing. Use when stronger testability or swapping implementations is required.

The project standard is **A** where practical; existing services use **B** and are documented here. **PracticeSessionState** is documented as the exception that holds context and creates services in `setup`.
