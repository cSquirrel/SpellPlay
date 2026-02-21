import Testing
@testable import WordCraft

@Suite("LevelService")
struct LevelServiceTests {
    @Test("Level 1 at 0 XP")
    func levelFromExperience_zero() {
        #expect(LevelService.levelFromExperience(0) == 1)
    }

    @Test("Level 2 at 100 XP (formula: 100 * (2-1)^1.5 = 100)")
    func levelFromExperience_level2() {
        let xpForLevel2 = LevelService.experienceForLevel(2)
        #expect(xpForLevel2 == 100)
        #expect(LevelService.levelFromExperience(99) == 1)
        #expect(LevelService.levelFromExperience(100) == 2)
        #expect(LevelService.levelFromExperience(249) == 2)
    }

    @Test("Level 3 at 282 XP (formula: 100 * (3-1)^1.5 = 282)")
    func levelFromExperience_level3() {
        let xpLevel2 = LevelService.experienceForLevel(2)
        let xpLevel3 = LevelService.experienceForLevel(3)
        #expect(xpLevel2 == 100)
        #expect(xpLevel3 == 282)
        #expect(LevelService.levelFromExperience(281) == 2)
        #expect(LevelService.levelFromExperience(282) == 3)
    }

    @Test("experienceForLevel(1) is 0")
    func experienceForLevel_one() {
        #expect(LevelService.experienceForLevel(1) == 0)
    }

    @Test("Static methods callable from non-MainActor context")
    func callFromBackgroundContext_compilesAndRuns() async {
        #expect(LevelService.levelFromExperience(0) == 1)
        #expect(LevelService.experienceForLevel(2) == 100)
        let progress = LevelService.progressToNextLevel(currentLevel: 1, currentExperience: 50)
        #expect(progress >= 0.0)
        #expect(progress <= 1.0)
    }
}
