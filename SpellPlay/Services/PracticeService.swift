import Foundation
import SwiftData

/// Business logic for practice flow: validation, scoring, persistence.
/// PracticeSessionState holds UI-facing state only; this service performs
/// validation, streak/achievement updates, and saving.
@MainActor
final class PracticeService {
    /// Validate user answer against word (case-insensitive, trimmed).
    func validateAnswer(word: Word, answer: String) -> Bool {
        word.text.matches(answer)
    }

    /// Setup result to apply to PracticeSessionState.
    struct SetupResult {
        let words: [Word]
        let initialCoins: Int
        let currentStreak: Int
    }

    /// Load words and initial streak/coins for a test.
    func setup(test: SpellingTest, modelContext: ModelContext) -> SetupResult {
        let streakService = StreakService(modelContext: modelContext)
        let words = (test.words ?? []).sortedAsCreated()
        let currentStreak = streakService.getCurrentStreak()
        return SetupResult(
            words: words,
            initialCoins: test.helpCoins,
            currentStreak: currentStreak)
    }

    /// Result of submitting one answer: points, stars, and whether to advance.
    struct SubmitResult {
        let isCorrect: Bool
        let pointsResult: PointsService.PointsResult?
        let stars: Int
        let nextWordIndex: Int
        let isRoundComplete: Bool
        let allWordsMastered: Bool
        let wordMastered: Bool
        /// Non-nil when round just completed and was perfect (all correct).
        let perfectRoundBonus: Int?
    }

    /// Process one submitted answer. Caller updates session state from this result.
    func submitAnswer(
        word: Word,
        answer: String,
        currentWordIndex: Int,
        wordsInCurrentRound: [Word],
        roundResults: [UUID: Bool],
        wordsMastered: Set<UUID>,
        comboCount: Int,
        wordStartTime: Date?,
        hadInitialMistakes: inout Bool
    )
    -> SubmitResult {
        let isCorrect = word.text.matches(answer)
        let isFirstTry = !roundResults.keys.contains(word.id) || roundResults[word.id] == nil

        if !isCorrect, !hadInitialMistakes {
            hadInitialMistakes = true
        }

        var newCombo = comboCount
        var multiplier = 1
        var pointsResult: PointsService.PointsResult?
        var stars = 0

        if isCorrect {
            newCombo += 1
            multiplier = PointsService.getComboMultiplier(for: newCombo)
            let timeTaken = wordStartTime.map { Date().timeIntervalSince($0) }
            pointsResult = PointsService.calculatePoints(
                isCorrect: true,
                comboCount: newCombo,
                timeTaken: timeTaken,
                isFirstTry: isFirstTry)
            if let time = timeTaken, time <= PointsService.speedBonusThreshold, isFirstTry {
                stars = 3
            } else if isFirstTry {
                stars = 2
            } else {
                stars = 1
            }
        }

        var newIndex = currentWordIndex
        var roundComplete = false
        var allMastered = false
        let wordMastered = isCorrect

        var perfectRoundBonus: Int?
        if currentWordIndex < wordsInCurrentRound.count - 1 {
            newIndex = currentWordIndex + 1
        } else {
            roundComplete = true
            let totalWords = wordsInCurrentRound.count
            let masteredCount = wordsMastered.count + (isCorrect ? 1 : 0)
            allMastered = (masteredCount == totalWords)
            if isCorrect, roundResults.values.allSatisfy(\.self) {
                perfectRoundBonus = PointsService.getPerfectRoundBonus()
            }
        }

        return SubmitResult(
            isCorrect: isCorrect,
            pointsResult: pointsResult,
            stars: stars,
            nextWordIndex: newIndex,
            isRoundComplete: roundComplete,
            allWordsMastered: allMastered,
            wordMastered: wordMastered,
            perfectRoundBonus: perfectRoundBonus)
    }

    /// Perfect round bonus points.
    func getPerfectRoundBonus() -> Int {
        PointsService.getPerfectRoundBonus()
    }

    /// Complete practice: update streak, achievements, user progress, save. Returns display values.
    struct CompleteResult {
        let currentStreak: Int
        let newlyUnlockedAchievements: [AchievementID]
        let performanceGrade: PerformanceGrade?
        let levelUpOccurred: Bool
        let newLevel: Int?
        let currentLevel: Int
        let experiencePoints: Int
    }

    func completePractice(
        words: [Word],
        wordsMastered: Set<UUID>,
        correctAnswers: [Bool],
        roundResults: [UUID: Bool],
        sessionPoints: Int,
        totalStarsEarned: Int,
        initialCoins: Int,
        availableCoins: Int,
        hadInitialMistakes: Bool,
        roundStartTime: Date?,
        modelContext: ModelContext,
        onError: @escaping (String) -> Void
    )
    -> CompleteResult {
        let roundTime = roundStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let totalAttempts = correctAnswers.count
        let totalCorrect = wordsMastered.count

        guard let test = words.first?.test else {
            return CompleteResult(
                currentStreak: 0,
                newlyUnlockedAchievements: [],
                performanceGrade: nil,
                levelUpOccurred: false,
                newLevel: nil,
                currentLevel: 1,
                experiencePoints: 0)
        }

        let streakService = StreakService(modelContext: modelContext) { msg in onError(msg) }
        let currentStreak = streakService.updateStreak(
            for: test.id,
            wordsAttempted: totalAttempts,
            wordsCorrect: totalCorrect)

        test.lastPracticed = Date()

        let achievementService = AchievementService(modelContext: modelContext) { msg in onError(msg) }
        let userProgress = achievementService.getUserProgress()

        userProgress.addPoints(sessionPoints)
        userProgress.addStars(totalStarsEarned)
        let previousWordsMastered = userProgress.totalWordsMastered
        let newWordsMastered = wordsMastered.count
        if newWordsMastered > previousWordsMastered {
            for _ in previousWordsMastered ..< newWordsMastered {
                userProgress.incrementWordsMastered()
            }
        }
        let isFirstSession = userProgress.totalSessionsCompleted == 0
        userProgress.incrementSessionsCompleted()

        var levelUpOccurred = false
        var newLevel: Int?
        let oldLevel = userProgress.level
        userProgress.level = LevelService.levelFromExperience(userProgress.experiencePoints)
        if userProgress.level > oldLevel {
            levelUpOccurred = true
            newLevel = userProgress.level
        }

        let sessionResults = AchievementService.SessionResults(
            isFirstSession: isFirstSession,
            hasPerfectRound: roundResults.values.allSatisfy(\.self),
            roundTimeSeconds: roundTime,
            currentStreak: currentStreak,
            helpCoinsUsed: initialCoins - availableCoins,
            wordsAttempted: totalAttempts,
            allWordsMastered: true,
            hadInitialMistakes: hadInitialMistakes)

        let newlyUnlockedAchievements = achievementService.checkAchievements(
            sessionResults: sessionResults,
            userProgress: userProgress)

        let accuracy = words.isEmpty ? 0 : Double(wordsMastered.count) / Double(words.count)
        let allFirstTry = roundResults.values.allSatisfy(\.self) && correctAnswers.count == words.count
        let performanceGrade = PerformanceGrade.calculate(accuracy: accuracy, allFirstTry: allFirstTry)

        do {
            try modelContext.save()
        } catch {
            onError("Your progress was saved, but some information couldn't be recorded.")
        }

        return CompleteResult(
            currentStreak: currentStreak,
            newlyUnlockedAchievements: newlyUnlockedAchievements,
            performanceGrade: performanceGrade,
            levelUpOccurred: levelUpOccurred,
            newLevel: newLevel,
            currentLevel: userProgress.level,
            experiencePoints: userProgress.experiencePoints)
    }

    /// Save progress (e.g. for tests). No-op if no changes; can be used to verify modelContext.
    func saveProgress(modelContext: ModelContext) throws {
        try modelContext.save()
    }
}
