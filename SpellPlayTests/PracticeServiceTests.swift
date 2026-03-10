import Foundation
import SwiftData
import Testing
@testable import WordCraft

@MainActor
struct PracticeServiceTests {

    @Test func PracticeService_validateAnswer_correct() async throws {
        let service = PracticeService()
        let (_, word) = try makeTestAndWord(text: "hello")
        #expect(service.validateAnswer(word: word, answer: "hello") == true)
        #expect(service.validateAnswer(word: word, answer: "  HELLO  ") == true)
    }

    @Test func PracticeService_validateAnswer_incorrect() async throws {
        let service = PracticeService()
        let (_, word) = try makeTestAndWord(text: "hello")
        #expect(service.validateAnswer(word: word, answer: "helo") == false)
        #expect(service.validateAnswer(word: word, answer: "goodbye") == false)
    }

    @Test func PracticeService_calculateScoreOrProgress() async throws {
        let service = PracticeService()
        let (_, word) = try makeTestAndWord(text: "cat")
        var hadInitialMistakes = false
        let result = service.submitAnswer(
            word: word,
            answer: "cat",
            currentWordIndex: 0,
            wordsInCurrentRound: [word],
            roundResults: [:],
            wordsMastered: [],
            comboCount: 0,
            wordStartTime: Date(),
            hadInitialMistakes: &hadInitialMistakes)
        #expect(result.isCorrect == true)
        #expect(result.pointsResult != nil)
        #expect(result.stars >= 1)
        #expect(result.wordMastered == true)
    }

    @Test func PracticeService_saveProgress_modelContext() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema = Schema(CurrentSchema.models)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        let service = PracticeService()
        try service.saveProgress(modelContext: context)
    }

    @Test func PracticeSessionState_reset() async throws {
        let state = PracticeSessionState()
        state.currentWordIndex = 5
        state.userAnswer = "test"
        state.sessionPoints = 100
        state.reset()
        #expect(state.currentWordIndex == 0)
        #expect(state.userAnswer == "")
        #expect(state.sessionPoints == 0)
    }

    private func makeTestAndWord(text: String) throws -> (SpellingTest, Word) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema = Schema(CurrentSchema.models)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        let test = SpellingTest(name: "Test", helpCoins: 3)
        context.insert(test)
        let word = Word(text: text, displayOrder: 0)
        context.insert(word)
        word.test = test
        try context.save()
        return (test, word)
    }
}
