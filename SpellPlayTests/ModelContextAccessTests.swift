import SpellPlay
import SwiftData
import Testing

@MainActor
struct ModelContextAccessTests {
    /// Validates that tests can create an in-memory ModelContainer and pass the resulting
    /// ModelContext to a service (AchievementService). Ensures no crash and that the
    /// service can perform a simple operation (getUserProgress).
    @Test
    func inMemoryContainer_canInjectForTests() throws {
        let schema = Schema(CurrentSchema.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let modelContext = container.mainContext

        let service = AchievementService(modelContext: modelContext)
        let progress = service.getUserProgress()

        #expect(progress.totalPoints == 0)
        #expect(progress.level == 1)
    }
}
