import Testing
@testable import WordCraft

@Suite("PointsService")
struct PointsServiceTests {
    @Test("Correct first try with combo and speed bonus gives expected total and breakdown")
    func calculatePoints_correctFirstTry() {
        let result = PointsService.calculatePoints(
            isCorrect: true,
            comboCount: 2,
            timeTaken: 3.0,
            isFirstTry: true)
        #expect(result.basePoints == 10)
        #expect(result.comboMultiplier == 2)
        #expect(result.speedBonus == 5)
        #expect(result.totalPoints == (10 + 5) * 2)
        #expect(result.totalPoints == 30)
    }

    @Test("Incorrect answer returns zero points")
    func calculatePoints_incorrect() {
        let result = PointsService.calculatePoints(
            isCorrect: false,
            comboCount: 5,
            timeTaken: 2.0,
            isFirstTry: true)
        #expect(result.basePoints == 0)
        #expect(result.comboMultiplier == 1)
        #expect(result.speedBonus == 0)
        #expect(result.totalPoints == 0)
    }

    @Test("Combo multiplier 0 and 1 returns 1x")
    func getComboMultiplier_zeroAndOne() {
        #expect(PointsService.getComboMultiplier(for: 0) == 1)
        #expect(PointsService.getComboMultiplier(for: 1) == 1)
    }

    @Test("Combo multiplier 2–4 returns 2x")
    func getComboMultiplier_twoToFour() {
        #expect(PointsService.getComboMultiplier(for: 2) == 2)
        #expect(PointsService.getComboMultiplier(for: 4) == 2)
    }

    @Test("Combo multiplier 5–9 returns 3x")
    func getComboMultiplier_fiveToNine() {
        #expect(PointsService.getComboMultiplier(for: 5) == 3)
        #expect(PointsService.getComboMultiplier(for: 9) == 3)
    }

    @Test("Combo multiplier 10+ returns 4x")
    func getComboMultiplier_tenPlus() {
        #expect(PointsService.getComboMultiplier(for: 10) == 4)
        #expect(PointsService.getComboMultiplier(for: 100) == 4)
    }

    @Test("Static methods callable from non-MainActor context")
    func callFromBackgroundContext_compilesAndRuns() async {
        let result = PointsService.calculatePoints(
            isCorrect: true,
            comboCount: 0,
            timeTaken: nil,
            isFirstTry: true)
        #expect(result.totalPoints == 10)
        #expect(PointsService.getComboMultiplier(for: 3) == 2)
        #expect(PointsService.getPerfectRoundBonus() == 50)
    }
}
