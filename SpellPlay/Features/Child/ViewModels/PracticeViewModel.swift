//
//  PracticeViewModel.swift
//  WordCraft
//
//  Created on [Date]
//

import Foundation
import SwiftData

@MainActor
@Observable
class PracticeViewModel {
    private var modelContext: ModelContext?
    private var streakService: StreakService?
    
    var currentWordIndex = 0
    var userAnswer = ""
    var words: [Word] = []
    var correctAnswers: [Bool] = []
    var isComplete = false
    var currentStreak = 0
    
    // Round tracking properties
    var currentRound = 1
    var wordsInCurrentRound: [Word] = []
    var roundResults: [UUID: Bool] = [:]
    var wordsMastered: Set<UUID> = []
    var allWordsMastered = false
    var isRoundComplete = false
    var errorMessage: String?
    
    func setup(test: SpellingTest, modelContext: ModelContext) {
        self.modelContext = modelContext
        self.streakService = StreakService(modelContext: modelContext) { [weak self] errorMessage in
            self?.errorMessage = errorMessage
        }
        self.words = test.words
        self.currentWordIndex = 0
        self.userAnswer = ""
        self.correctAnswers = []
        self.isComplete = false
        self.currentStreak = streakService?.getCurrentStreak() ?? 0
        
        // Initialize round tracking
        self.currentRound = 1
        self.wordsInCurrentRound = test.words
        self.roundResults = [:]
        self.wordsMastered = []
        self.allWordsMastered = false
        self.isRoundComplete = false
    }
    
    var currentWord: Word? {
        guard currentWordIndex < wordsInCurrentRound.count else { return nil }
        return wordsInCurrentRound[currentWordIndex]
    }
    
    var progress: Double {
        guard !wordsInCurrentRound.isEmpty else { return 0 }
        return Double(currentWordIndex) / Double(wordsInCurrentRound.count)
    }
    
    var progressText: String {
        return "Round \(currentRound): Word \(currentWordIndex + 1) of \(wordsInCurrentRound.count)"
    }
    
    var misspelledWords: [Word] {
        return words.filter { !wordsMastered.contains($0.id) }
    }
    
    func submitAnswer(with answer: String? = nil) {
        guard let word = currentWord else { return }
        
        // Use provided answer if available, otherwise fall back to userAnswer
        let answerToEvaluate = answer ?? userAnswer
        let isCorrect = word.text.matches(answerToEvaluate)
        correctAnswers.append(isCorrect)
        roundResults[word.id] = isCorrect
        
        // If answer is correct, mark word as mastered
        if isCorrect {
            wordsMastered.insert(word.id)
        }
        
        userAnswer = ""
        
        // Check if we've completed the current round
        if currentWordIndex < wordsInCurrentRound.count - 1 {
            currentWordIndex += 1
        } else {
            // Round is complete
            isRoundComplete = true
            
            // Check if all words have been mastered
            if wordsMastered.count == words.count {
                allWordsMastered = true
                completePractice()
            }
            // If not all words mastered, prepare for next round
            // (The actual transition will be handled by the view)
        }
    }
    
    func startNextRound() {
        // Filter words that are NOT yet mastered
        wordsInCurrentRound = words.filter { !wordsMastered.contains($0.id) }
        currentWordIndex = 0
        roundResults = [:]
        currentRound += 1
        isRoundComplete = false
    }
    
    private func completePractice() {
        isComplete = true
        
        // Update streak - use total words attempted across all rounds
        if let test = words.first?.test,
           let streakService = streakService {
            // Calculate total words attempted (all rounds combined)
            let totalAttempts = correctAnswers.count
            let totalCorrect = wordsMastered.count
            
            currentStreak = streakService.updateStreak(
                for: test.id,
                wordsAttempted: totalAttempts,
                wordsCorrect: totalCorrect
            )
            
            // Update test's lastPracticed date
            test.lastPracticed = Date()
            
            do {
                try modelContext?.save()
            } catch {
                errorMessage = "Your progress was saved, but some information couldn't be recorded."
            }
        }
    }
    
    func reset() {
        currentWordIndex = 0
        userAnswer = ""
        correctAnswers = []
        isComplete = false
        
        // Reset round tracking
        currentRound = 1
        wordsInCurrentRound = words
        roundResults = [:]
        wordsMastered = []
        allWordsMastered = false
        isRoundComplete = false
    }
}

