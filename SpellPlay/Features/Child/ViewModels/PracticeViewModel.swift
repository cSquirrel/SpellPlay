//
//  PracticeViewModel.swift
//  SpellPlay
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
    var score: (correct: Int, total: Int) = (0, 0)
    var currentStreak = 0
    
    func setup(test: SpellingTest, modelContext: ModelContext) {
        self.modelContext = modelContext
        self.streakService = StreakService(modelContext: modelContext)
        self.words = test.words
        self.currentWordIndex = 0
        self.userAnswer = ""
        self.correctAnswers = []
        self.isComplete = false
        self.score = (0, 0)
        self.currentStreak = streakService?.getCurrentStreak() ?? 0
    }
    
    var currentWord: Word? {
        guard currentWordIndex < words.count else { return nil }
        return words[currentWordIndex]
    }
    
    var progress: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentWordIndex) / Double(words.count)
    }
    
    var progressText: String {
        return "\(currentWordIndex + 1) of \(words.count)"
    }
    
    func submitAnswer() {
        guard let word = currentWord else { return }
        
        let isCorrect = word.text.matches(userAnswer)
        correctAnswers.append(isCorrect)
        
        if isCorrect {
            score.correct += 1
        }
        score.total += 1
        
        userAnswer = ""
        
        if currentWordIndex < words.count - 1 {
            currentWordIndex += 1
        } else {
            completePractice()
        }
    }
    
    private func completePractice() {
        isComplete = true
        
        // Update streak
        if let test = words.first?.test,
           let streakService = streakService {
            currentStreak = streakService.updateStreak(
                for: test.id,
                wordsAttempted: words.count,
                wordsCorrect: score.correct
            )
            
            // Update test's lastPracticed date
            test.lastPracticed = Date()
            
            do {
                try modelContext?.save()
            } catch {
                print("Error saving practice session: \(error)")
            }
        }
    }
    
    func reset() {
        currentWordIndex = 0
        userAnswer = ""
        correctAnswers = []
        isComplete = false
        score = (0, 0)
    }
}

