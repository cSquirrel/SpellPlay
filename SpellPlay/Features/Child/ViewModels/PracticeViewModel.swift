//
//  PracticeViewModel.swift
//  WordCraft
//
//  Created on [Date]
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class PracticeViewModel {
    private var modelContext: ModelContext?
    private var streakService: StreakService?
    private var achievementService: AchievementService?
    var userProgress: UserProgress?
    
    var currentWordIndex = 0
    var userAnswer = ""
    var words: [Word] = []
    var correctAnswers: [Bool] = []
    var isComplete = false
    var currentStreak = 0
    var availableCoins = 0
    var initialCoins = 0
    
    // Round tracking properties
    var currentRound = 1
    var wordsInCurrentRound: [Word] = []
    var roundResults: [UUID: Bool] = [:]
    var wordsMastered: Set<UUID> = []
    var allWordsMastered = false
    var isRoundComplete = false
    var errorMessage: String?
    
    // Gamification properties
    var sessionPoints = 0
    var comboCount = 0
    var comboMultiplier = 1
    var starsEarned: [Int] = [] // Stars per word
    var totalStarsEarned = 0
    var wordStartTime: Date?
    var roundStartTime: Date?
    var hadInitialMistakes = false
    var newlyUnlockedAchievements: [AchievementID] = []
    var performanceGrade: PerformanceGrade?
    var levelUpOccurred = false
    var newLevel: Int?
    
    func setup(test: SpellingTest, modelContext: ModelContext) {
        self.modelContext = modelContext
        self.streakService = StreakService(modelContext: modelContext) { [weak self] errorMessage in
            self?.errorMessage = errorMessage
        }
        self.achievementService = AchievementService(modelContext: modelContext) { [weak self] errorMessage in
            self?.errorMessage = errorMessage
        }
        self.userProgress = achievementService?.getUserProgress()
        
        // Sort words by displayOrder to preserve entry order
        self.words = (test.words ?? []).sortedAsCreated()
        self.currentWordIndex = 0
        self.userAnswer = ""
        self.correctAnswers = []
        self.isComplete = false
        self.currentStreak = streakService?.getCurrentStreak() ?? 0
        self.availableCoins = test.helpCoins
        self.initialCoins = test.helpCoins
        
        // Initialize round tracking
        self.currentRound = 1
        // Use sorted words for the round
        self.wordsInCurrentRound = self.words
        self.roundResults = [:]
        self.wordsMastered = []
        self.allWordsMastered = false
        self.isRoundComplete = false
        
        // Initialize gamification
        self.sessionPoints = 0
        self.comboCount = 0
        self.comboMultiplier = 1
        self.starsEarned = []
        self.totalStarsEarned = 0
        self.roundStartTime = Date()
        self.hadInitialMistakes = false
        self.newlyUnlockedAchievements = []
        self.performanceGrade = nil
        self.levelUpOccurred = false
        self.newLevel = nil
        
        // Start timing for first word
        self.wordStartTime = Date()
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
    
    func submitAnswer(with answer: String? = nil) -> PointsResult? {
        guard let word = currentWord else { return nil }
        
        // Use provided answer if available, otherwise fall back to userAnswer
        let answerToEvaluate = answer ?? userAnswer
        let isCorrect = word.text.matches(answerToEvaluate)
        let isFirstTry = !roundResults.keys.contains(word.id) || roundResults[word.id] == nil
        
        // Track if there were initial mistakes
        if !isCorrect && !hadInitialMistakes {
            hadInitialMistakes = true
        }
        
        correctAnswers.append(isCorrect)
        roundResults[word.id] = isCorrect
        
        // Calculate time taken
        let timeTaken = wordStartTime.map { Date().timeIntervalSince($0) }
        
        // Calculate points and stars
        var pointsResult: PointsResult?
        var stars = 0
        
        if isCorrect {
            // Increment combo for correct answers
            comboCount += 1
            comboMultiplier = PointsService.getComboMultiplier(for: comboCount)
            
            // Calculate points
            pointsResult = PointsService.calculatePoints(
                isCorrect: true,
                comboCount: comboCount,
                timeTaken: timeTaken,
                isFirstTry: isFirstTry
            )
            
            // Add points to session
            sessionPoints += pointsResult!.totalPoints
            
            // Calculate stars (1-3 based on performance)
            if let time = timeTaken, time <= PointsService.speedBonusThreshold && isFirstTry {
                stars = 3
            } else if isFirstTry {
                stars = 2
            } else {
                stars = 1
            }
            
            totalStarsEarned += stars
            wordsMastered.insert(word.id)
        } else {
            // Reset combo on incorrect answer
            comboCount = 0
            comboMultiplier = 1
            stars = 0
        }
        
        starsEarned.append(stars)
        userAnswer = ""
        
        // Reset word timing for next word
        wordStartTime = Date()
        
        // Check if we've completed the current round
        if currentWordIndex < wordsInCurrentRound.count - 1 {
            currentWordIndex += 1
        } else {
            // Round is complete - check for perfect round bonus
            if isRoundPerfect() {
                let bonus = PointsService.getPerfectRoundBonus()
                sessionPoints += bonus
            }
            
            isRoundComplete = true
            
            // Check if all words have been mastered
            if wordsMastered.count == words.count {
                allWordsMastered = true
                completePractice()
            }
            // If not all words mastered, prepare for next round
            // (The actual transition will be handled by the view)
        }
        
        return pointsResult
    }
    
    private func isRoundPerfect() -> Bool {
        return roundResults.values.allSatisfy { $0 }
    }
    
    func startNextRound() {
        // Filter words that are NOT yet mastered
        wordsInCurrentRound = words.filter { !wordsMastered.contains($0.id) }
        currentWordIndex = 0
        roundResults = [:]
        currentRound += 1
        isRoundComplete = false
        roundStartTime = Date()
        wordStartTime = Date()
    }
    
    func useHelpCoin() {
        guard availableCoins > 0, let word = currentWord else { return }
        
        let targetWord = word.text
        let currentInput = userAnswer
        
        // Find common prefix
        var commonPrefixIndex = 0
        let targetChars = Array(targetWord)
        let inputChars = Array(currentInput)
        
        let maxIndex = min(targetChars.count, inputChars.count)
        
        // While characters match (case insensitive)
        while commonPrefixIndex < maxIndex {
             if String(targetChars[commonPrefixIndex]).lowercased() != String(inputChars[commonPrefixIndex]).lowercased() {
                 break
             }
             commonPrefixIndex += 1
        }
        
        // If we haven't revealed the whole word
        if commonPrefixIndex < targetChars.count {
            // Reveal up to the common prefix + 1 character
            let nextChar = targetChars[commonPrefixIndex]
            let prefix = String(targetChars.prefix(commonPrefixIndex))
            
            // Update the answer: keep correct prefix and add next correct character
            // This effectively corrects any errors after the prefix and adds the next letter
            userAnswer = prefix + String(nextChar)
            
            availableCoins -= 1
        }
    }
    
    private func completePractice() {
        isComplete = true
        
        // Calculate round time
        let roundTime = roundStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
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
            
            // Update user progress with points and stars
            if let progress = userProgress {
                progress.addPoints(sessionPoints)
                progress.addStars(totalStarsEarned)
                
                // Update words mastered count
                let newWordsMastered = wordsMastered.count
                let previousWordsMastered = progress.totalWordsMastered
                if newWordsMastered > previousWordsMastered {
                    for _ in previousWordsMastered..<newWordsMastered {
                        progress.incrementWordsMastered()
                    }
                }
                
                progress.incrementSessionsCompleted()
                
                // Check for level up
                let oldLevel = progress.level
                progress.level = LevelService.levelFromExperience(progress.experiencePoints)
                if progress.level > oldLevel {
                    levelUpOccurred = true
                    newLevel = progress.level
                }
            }
            
            // Check achievements
            if let achievementService = achievementService,
               let progress = userProgress {
                let sessionResults = AchievementService.SessionResults(
                    isFirstSession: progress.totalSessionsCompleted == 1,
                    hasPerfectRound: isRoundPerfect(),
                    roundTimeSeconds: roundTime,
                    currentStreak: currentStreak,
                    helpCoinsUsed: initialCoins - availableCoins,
                    wordsAttempted: totalAttempts,
                    allWordsMastered: allWordsMastered,
                    hadInitialMistakes: hadInitialMistakes
                )
                
                newlyUnlockedAchievements = achievementService.checkAchievements(
                    sessionResults: sessionResults,
                    userProgress: progress
                )
            }
            
            // Calculate performance grade
            let accuracy = words.count > 0 ? Double(wordsMastered.count) / Double(words.count) : 0.0
            let allFirstTry = roundResults.values.allSatisfy { $0 } && correctAnswers.count == words.count
            performanceGrade = PerformanceGrade.calculate(accuracy: accuracy, allFirstTry: allFirstTry)
            
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
        
        // Reset gamification
        sessionPoints = 0
        comboCount = 0
        comboMultiplier = 1
        starsEarned = []
        totalStarsEarned = 0
        hadInitialMistakes = false
        newlyUnlockedAchievements = []
        performanceGrade = nil
        levelUpOccurred = false
        newLevel = nil
    }
}

// Performance grade enum
enum PerformanceGrade: String {
    case perfect = "Perfect!"
    case excellent = "Excellent!"
    case great = "Great Job!"
    case good = "Good Work!"
    case keepPracticing = "Keep Practicing!"
    
    var color: Color {
        switch self {
        case .perfect: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case .excellent: return Color(red: 0.2, green: 0.8, blue: 0.3) // Green
        case .great: return Color(red: 0.2, green: 0.6, blue: 0.9) // Blue
        case .good: return Color(red: 0.9, green: 0.5, blue: 0.2) // Orange
        case .keepPracticing: return Color(red: 0.9, green: 0.2, blue: 0.2) // Red
        }
    }
    
    static func calculate(accuracy: Double, allFirstTry: Bool) -> PerformanceGrade {
        if accuracy == 1.0 && allFirstTry {
            return .perfect
        } else if accuracy >= 0.9 {
            return .excellent
        } else if accuracy >= 0.75 {
            return .great
        } else if accuracy >= 0.6 {
            return .good
        } else {
            return .keepPracticing
        }
    }
}

// Points result type alias
typealias PointsResult = PointsService.PointsResult

