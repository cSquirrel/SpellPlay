import Foundation
import SwiftData
import SwiftUI

/// UI-facing practice session state only. No StreakService, AchievementService, or persistence.
/// Business logic lives in PracticeService. Named "State" to avoid conflict with SwiftData PracticeSession.
@MainActor
@Observable
final class PracticeSessionState {
    var currentWordIndex = 0
    var userAnswer = ""
    var words: [Word] = []
    var correctAnswers: [Bool] = []
    var isComplete = false
    var currentStreak = 0
    var availableCoins = 0
    var initialCoins = 0

    // Round tracking
    var currentRound = 1
    var wordsInCurrentRound: [Word] = []
    var roundResults: [UUID: Bool] = [:]
    var wordsMastered: Set<UUID> = []
    var allWordsMastered = false
    var isRoundComplete = false
    var errorMessage: String?

    // Gamification (display)
    var sessionPoints = 0
    var comboCount = 0
    var comboMultiplier = 1
    var starsEarned: [Int] = []
    var totalStarsEarned = 0
    var wordStartTime: Date?
    var roundStartTime: Date?
    var hadInitialMistakes = false
    var newlyUnlockedAchievements: [AchievementID] = []
    var performanceGrade: PerformanceGrade?
    var levelUpOccurred = false
    var newLevel: Int?

    // For summary display (set from PracticeService.CompleteResult)
    var currentLevel = 1
    var experiencePoints = 0

    var currentWord: Word? {
        guard currentWordIndex < wordsInCurrentRound.count else { return nil }
        return wordsInCurrentRound[currentWordIndex]
    }

    var progress: Double {
        guard !wordsInCurrentRound.isEmpty else { return 0 }
        return Double(currentWordIndex) / Double(wordsInCurrentRound.count)
    }

    var progressText: String {
        "Round \(currentRound): Word \(currentWordIndex + 1) of \(wordsInCurrentRound.count)"
    }

    var misspelledWords: [Word] {
        words.filter { !wordsMastered.contains($0.id) }
    }

    /// Apply setup result from PracticeService.setup(...)
    func apply(_ setup: PracticeService.SetupResult) {
        words = setup.words
        currentWordIndex = 0
        userAnswer = ""
        correctAnswers = []
        isComplete = false
        currentStreak = setup.currentStreak
        availableCoins = setup.initialCoins
        initialCoins = setup.initialCoins
        currentRound = 1
        wordsInCurrentRound = setup.words
        roundResults = [:]
        wordsMastered = []
        allWordsMastered = false
        isRoundComplete = false
        sessionPoints = 0
        comboCount = 0
        comboMultiplier = 1
        starsEarned = []
        totalStarsEarned = 0
        roundStartTime = Date()
        hadInitialMistakes = false
        newlyUnlockedAchievements = []
        performanceGrade = nil
        levelUpOccurred = false
        newLevel = nil
        wordStartTime = Date()
    }

    /// Apply submit result from PracticeService.submitAnswer(...). Caller passes updated hadInitialMistakes.
    func apply(
        _ result: PracticeService.SubmitResult,
        wordId: UUID,
        hadInitialMistakes: Bool
    ) {
        self.hadInitialMistakes = hadInitialMistakes
        correctAnswers.append(result.isCorrect)
        roundResults[wordId] = result.isCorrect
        if let pr = result.pointsResult {
            sessionPoints += pr.totalPoints
        }
        if result.isCorrect {
            comboCount += 1
            comboMultiplier = PointsService.getComboMultiplier(for: comboCount)
            if result.wordMastered {
                wordsMastered.insert(wordId)
            }
        } else {
            comboCount = 0
            comboMultiplier = 1
        }
        starsEarned.append(result.stars)
        totalStarsEarned += result.stars
        if let bonus = result.perfectRoundBonus {
            sessionPoints += bonus
        }
        userAnswer = ""
        wordStartTime = Date()
        currentWordIndex = result.nextWordIndex
        isRoundComplete = result.isRoundComplete
        allWordsMastered = result.allWordsMastered
    }

    /// Apply complete result from PracticeService.completePractice(...)
    func apply(_ result: PracticeService.CompleteResult) {
        isComplete = true
        currentStreak = result.currentStreak
        newlyUnlockedAchievements = result.newlyUnlockedAchievements
        performanceGrade = result.performanceGrade
        levelUpOccurred = result.levelUpOccurred
        newLevel = result.newLevel
        currentLevel = result.currentLevel
        experiencePoints = result.experiencePoints
    }

    func startNextRound() {
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
        var commonPrefixIndex = 0
        let targetChars = Array(targetWord)
        let inputChars = Array(currentInput)
        let maxIndex = min(targetChars.count, inputChars.count)
        while commonPrefixIndex < maxIndex {
            if
                String(targetChars[commonPrefixIndex]).lowercased() != String(inputChars[commonPrefixIndex])
                    .lowercased()
            {
                break
            }
            commonPrefixIndex += 1
        }
        if commonPrefixIndex < targetChars.count {
            let nextChar = targetChars[commonPrefixIndex]
            let prefix = String(targetChars.prefix(commonPrefixIndex))
            userAnswer = prefix + String(nextChar)
            availableCoins -= 1
        }
    }

    func reset() {
        currentWordIndex = 0
        userAnswer = ""
        correctAnswers = []
        isComplete = false
        currentRound = 1
        wordsInCurrentRound = words
        roundResults = [:]
        wordsMastered = []
        allWordsMastered = false
        isRoundComplete = false
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

/// Performance grade for practice summary
enum PerformanceGrade: String {
    case perfect = "Perfect!"
    case excellent = "Excellent!"
    case great = "Great Job!"
    case good = "Good Work!"
    case keepPracticing = "Keep Practicing!"

    var color: Color {
        switch self {
        case .perfect: Color(red: 1.0, green: 0.84, blue: 0.0)
        case .excellent: Color(red: 0.2, green: 0.8, blue: 0.3)
        case .great: Color(red: 0.2, green: 0.6, blue: 0.9)
        case .good: Color(red: 0.9, green: 0.5, blue: 0.2)
        case .keepPracticing: Color(red: 0.9, green: 0.2, blue: 0.2)
        }
    }

    static func calculate(accuracy: Double, allFirstTry: Bool) -> PerformanceGrade {
        if accuracy == 1.0, allFirstTry {
            .perfect
        } else if accuracy >= 0.9 {
            .excellent
        } else if accuracy >= 0.75 {
            .great
        } else if accuracy >= 0.6 {
            .good
        } else {
            .keepPracticing
        }
    }
}
