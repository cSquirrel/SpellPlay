import Testing

@testable import WordCraft

@Suite("GameResultService")
struct GameResultServiceTests {

    @Test("calculate returns result with given inputs")
    func calculateReturnsResultWithGivenInputs() {
        let result = GameResultService.calculate(
            totalPoints: 100,
            totalStars: 6,
            wordsCompleted: 3,
            totalMistakes: 1)
        #expect(result.totalPoints == 100)
        #expect(result.totalStars == 6)
        #expect(result.wordsCompleted == 3)
        #expect(result.totalMistakes == 1)
    }

    @Test("zero score and zero stars")
    func zeroScoreAndZeroStars() {
        let result = GameResultService.calculate(
            totalPoints: 0,
            totalStars: 0,
            wordsCompleted: 0,
            totalMistakes: 0)
        #expect(result.totalPoints == 0)
        #expect(result.totalStars == 0)
        #expect(result.wordsCompleted == 0)
        #expect(result.totalMistakes == 0)
    }

    @Test("star boundaries match existing behavior - three stars when fast and no mistakes")
    func starBoundariesThreeStars() {
        #expect(GameResultService.starsForWord(timeTaken: 2.0, mistakesThisWord: 0) == 3)
        #expect(GameResultService.starsForWord(timeTaken: 5.0, mistakesThisWord: 0) == 3)
    }

    @Test("star boundaries - two stars when no mistakes but slow")
    func starBoundariesTwoStars() {
        #expect(GameResultService.starsForWord(timeTaken: 6.0, mistakesThisWord: 0) == 2)
        #expect(GameResultService.starsForWord(timeTaken: nil, mistakesThisWord: 0) == 2)
    }

    @Test("star boundaries - one star when mistakes")
    func starBoundariesOneStar() {
        #expect(GameResultService.starsForWord(timeTaken: 2.0, mistakesThisWord: 1) == 1)
        #expect(GameResultService.starsForWord(timeTaken: nil, mistakesThisWord: 1) == 1)
    }

    @Test("max stars and points")
    func maxStarsAndPoints() {
        let result = GameResultService.calculate(
            totalPoints: 9999,
            totalStars: 99,
            wordsCompleted: 33,
            totalMistakes: 0)
        #expect(result.totalPoints == 9999)
        #expect(result.totalStars == 99)
        #expect(result.wordsCompleted == 33)
        #expect(result.totalMistakes == 0)
    }

    @Test("stateless - same inputs same output")
    func statelessSameInputsSameOutput() {
        let a = GameResultService.calculate(totalPoints: 50, totalStars: 2, wordsCompleted: 1, totalMistakes: 0)
        let b = GameResultService.calculate(totalPoints: 50, totalStars: 2, wordsCompleted: 1, totalMistakes: 0)
        #expect(a == b)
    }

    @Test("formatSummary contains all result fields")
    func formatSummaryContainsAllFields() {
        let result = GameResultService.calculate(
            totalPoints: 10,
            totalStars: 2,
            wordsCompleted: 1,
            totalMistakes: 0)
        let summary = GameResultService.formatSummary(result)
        #expect(summary.contains("10"))
        #expect(summary.contains("2"))
        #expect(summary.contains("points"))
        #expect(summary.contains("stars"))
    }
}
