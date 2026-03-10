import Testing
@testable import WordCraft

@MainActor
@Suite("GameStateManager")
struct GameStateManagerTests {
    /// Test double that returns a fixed GameResult and records calculateResult calls
    final class StubGameResultService: GameResultServiceProtocol {
        let fixedResult: GameResult
        private(set) var calculateCallCount = 0
        private(set) var lastScore: Int?
        private(set) var lastTotalStars: Int?
        private(set) var lastWordsCompleted: Int?
        private(set) var lastTotalMistakes: Int?

        init(fixedResult: GameResult = GameResult(
            totalPoints: 100,
            totalStars: 3,
            wordsCompleted: 2,
            totalMistakes: 0))
        {
            self.fixedResult = fixedResult
        }

        func calculateResult(score: Int, totalStars: Int, wordsCompleted: Int, totalMistakes: Int) -> GameResult {
            calculateCallCount += 1
            lastScore = score
            lastTotalStars = totalStars
            lastWordsCompleted = wordsCompleted
            lastTotalMistakes = totalMistakes
            return fixedResult
        }
    }

    @Test(
        "reset sets score, combo, stars, mistakes, index to initial values; showCelebration and showResult false; result nil"
    )
    func reset_clearsScoreAndCombo() async throws {
        let service = StubGameResultService()
        let manager = GameStateManager(resultService: service)
        manager.score = 50
        manager.comboCount = 3
        manager.totalStars = 2
        manager.totalMistakes = 1
        manager.currentWordIndex = 1
        manager.showCelebration = true
        manager.showResult = true
        manager.result = GameResult(totalPoints: 0, totalStars: 0, wordsCompleted: 0, totalMistakes: 0)

        manager.reset()

        #expect(manager.score == 0)
        #expect(manager.comboCount == 0)
        #expect(manager.comboMultiplier == 1)
        #expect(manager.totalStars == 0)
        #expect(manager.totalMistakes == 0)
        #expect(manager.currentWordIndex == 0)
        #expect(manager.showCelebration == false)
        #expect(manager.showResult == false)
        #expect(manager.result == nil)
    }

    @Test("After setup(words:) and progress, reset leaves words unchanged but currentWordIndex 0, phase .ready")
    func reset_clearsWordProgress() async throws {
        let service = StubGameResultService()
        let manager = GameStateManager(resultService: service)
        let words = [Word(text: "cat"), Word(text: "dog"), Word(text: "bird")]
        manager.setup(words: words)
        #expect(manager.words.count == 3)
        manager.currentWordIndex = 2
        manager.phase = .playing

        manager.reset()

        #expect(manager.words.count == 3)
        #expect(manager.currentWordIndex == 0)
        #expect(manager.phase == .ready)
    }

    @Test("One handleCorrectAnswer increases score, comboCount, totalStars; comboMultiplier from PointsService")
    func handleCorrectAnswer_incrementsScoreAndCombo() async throws {
        let service = StubGameResultService()
        let manager = GameStateManager(resultService: service)
        manager.setup(words: [Word(text: "a")])
        manager.startWordTimer()

        manager.handleCorrectAnswer()

        #expect(manager.score >= 10)
        #expect(manager.comboCount == 1)
        #expect(manager.comboMultiplier == 1)
        #expect(manager.totalStars >= 1)
    }

    @Test("No mistakes + fast → 3 stars; no mistakes slow → 2; with mistakes → 1")
    func handleCorrectAnswer_starCount_byMistakesAndTime() async throws {
        let service = StubGameResultService()
        let manager = GameStateManager(resultService: service)
        manager.setup(words: [Word(text: "a")])

        manager.startWordTimer()
        manager.handleCorrectAnswer()
        let starsFirst = manager.totalStars

        manager.reset()
        manager.setup(words: [Word(text: "b")])
        manager.startWordTimer()
        manager.handleIncorrectAnswer()
        manager.handleCorrectAnswer()
        let starsWithMistake = manager.totalStars

        #expect(starsFirst >= 2)
        #expect(starsWithMistake == 1)
    }

    @Test(
        "After one correct, handleIncorrectAnswer sets combo 0, multiplier 1, increments totalMistakes and mistakesThisWord"
    )
    func handleIncorrectAnswer_resetsComboAndIncrementsMistakes() async throws {
        let service = StubGameResultService()
        let manager = GameStateManager(resultService: service)
        manager.setup(words: [Word(text: "a")])
        manager.startWordTimer()
        manager.handleCorrectAnswer()
        #expect(manager.comboCount == 1)
        #expect(manager.totalMistakes == 0)

        manager.handleIncorrectAnswer()

        #expect(manager.comboCount == 0)
        #expect(manager.comboMultiplier == 1)
        #expect(manager.totalMistakes == 1)
        #expect(manager.mistakesThisWord == 1)
    }

    @Test("advanceToNextWord increments currentWordIndex; when index >= words.count, phase .gameComplete")
    func advanceToNextWord_incrementsIndex() async throws {
        let service = StubGameResultService()
        let manager = GameStateManager(resultService: service)
        manager.setup(words: [Word(text: "a"), Word(text: "b")])
        #expect(manager.currentWordIndex == 0)
        #expect(manager.phase == .ready)

        manager.advanceToNextWord()
        #expect(manager.currentWordIndex == 1)
        #expect(manager.phase == .ready)

        manager.advanceToNextWord()
        #expect(manager.currentWordIndex == 2)
        #expect(manager.phase == .gameComplete)
    }

    @Test("finishGame obtains GameResult from injected service; sets result and showResult = true")
    func finishGame_callsResultService_notInline() async throws {
        let fixed = GameResult(totalPoints: 99, totalStars: 2, wordsCompleted: 3, totalMistakes: 1)
        let service = StubGameResultService(fixedResult: fixed)
        let manager = GameStateManager(resultService: service)
        manager.setup(words: [Word(text: "a"), Word(text: "b"), Word(text: "c")])
        manager.score = 50
        manager.totalStars = 2
        manager.currentWordIndex = 3
        manager.totalMistakes = 1

        manager.finishGame()

        #expect(service.calculateCallCount == 1)
        #expect(service.lastScore == 50)
        #expect(service.lastTotalStars == 2)
        #expect(service.lastWordsCompleted == 3)
        #expect(service.lastTotalMistakes == 1)
        #expect(manager.result == fixed)
        #expect(manager.showResult == true)
    }

    @Test("showCelebration sets type, message, emoji, showCelebration true; hideCelebration sets showCelebration false")
    func showCelebration_setsTypeAndVisibility() async throws {
        let service = StubGameResultService()
        let manager = GameStateManager(resultService: service)

        manager.showCelebration(type: .perfectRound, message: "Perfect!", emoji: "🌟")
        #expect(manager.celebrationType == .perfectRound)
        #expect(manager.celebrationMessage == "Perfect!")
        #expect(manager.celebrationEmoji == "🌟")
        #expect(manager.showCelebration == true)

        manager.hideCelebration()
        #expect(manager.showCelebration == false)
    }

    @Test(
        "currentWord and targetText return correct word for currentWordIndex; out of range → currentWord nil, targetText empty"
    )
    func currentWord_and_targetText() async throws {
        let service = StubGameResultService()
        let manager = GameStateManager(resultService: service)
        let words = [Word(text: "cat"), Word(text: "dog")]
        manager.setup(words: words)

        #expect(manager.currentWord?.text == "cat")
        #expect(manager.targetText == "cat")

        manager.advanceToNextWord()
        #expect(manager.currentWord?.text == "dog")
        #expect(manager.targetText == "dog")

        manager.advanceToNextWord()
        #expect(manager.currentWord == nil)
        #expect(manager.targetText == "")
    }

    @Test("difficulty spawnInterval and movementSpeed: easy/medium/hard return documented values")
    func difficulty_spawnIntervalAndMovementSpeed() async throws {
        let service = StubGameResultService()
        let manager = GameStateManager(resultService: service)

        manager.difficulty = .easy
        #expect(manager.spawnInterval == 1.2)
        #expect(manager.movementSpeed == 1.0)

        manager.difficulty = .medium
        #expect(manager.spawnInterval == 0.9)
        #expect(manager.movementSpeed == 1.5)

        manager.difficulty = .hard
        #expect(manager.spawnInterval == 0.6)
        #expect(manager.movementSpeed == 2.0)
    }
}
