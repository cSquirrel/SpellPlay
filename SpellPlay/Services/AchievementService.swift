import Foundation
import SwiftData

@MainActor
class AchievementService {
    private let modelContext: ModelContext
    var onError: ((String) -> Void)?
    var onAchievementUnlocked: ((AchievementID) -> Void)?

    init(modelContext: ModelContext, onError: ((String) -> Void)? = nil) {
        self.modelContext = modelContext
        self.onError = onError
    }

    /// Get or create user progress
    func getUserProgress() -> UserProgress {
        let descriptor = FetchDescriptor<UserProgress>()

        if let progress = try? modelContext.fetch(descriptor).first {
            return progress
        } else {
            // Create new user progress
            let progress = UserProgress()
            modelContext.insert(progress)
            do {
                try modelContext.save()
            } catch {
                onError?("Unable to initialize progress tracking.")
            }
            return progress
        }
    }

    /// Check and unlock achievements based on session results
    func checkAchievements(
        sessionResults: SessionResults,
        userProgress: UserProgress
    )
    -> [AchievementID] {
        var newlyUnlocked: [AchievementID] = []

        // First Steps - first session
        if sessionResults.isFirstSession, !userProgress.hasAchievement(.firstSteps) {
            unlockAchievement(.firstSteps, for: userProgress)
            newlyUnlocked.append(.firstSteps)
        }

        // Perfect Round - all words correct in one round
        if sessionResults.hasPerfectRound, !userProgress.hasAchievement(.perfectRound) {
            unlockAchievement(.perfectRound, for: userProgress)
            newlyUnlocked.append(.perfectRound)
        }

        // Speed Demon - round completed in under 2 minutes
        if sessionResults.roundTimeSeconds < 120, !userProgress.hasAchievement(.speedDemon) {
            unlockAchievement(.speedDemon, for: userProgress)
            newlyUnlocked.append(.speedDemon)
        }

        // Streak Master - 7 day streak
        if sessionResults.currentStreak >= 7, !userProgress.hasAchievement(.streakMaster) {
            unlockAchievement(.streakMaster, for: userProgress)
            newlyUnlocked.append(.streakMaster)
        }

        // Word Wizard - 50 words mastered total
        if userProgress.totalWordsMastered >= 50, !userProgress.hasAchievement(.wordWizard) {
            unlockAchievement(.wordWizard, for: userProgress)
            newlyUnlocked.append(.wordWizard)
        }

        // No Help Needed - completed without using help coins
        if
            sessionResults.helpCoinsUsed == 0, sessionResults.wordsAttempted > 0,
            !userProgress.hasAchievement(.noHelpNeeded)
        {
            unlockAchievement(.noHelpNeeded, for: userProgress)
            newlyUnlocked.append(.noHelpNeeded)
        }

        // Comeback Kid - mastered all words after initial mistakes
        if
            sessionResults.hadInitialMistakes, sessionResults.allWordsMastered,
            !userProgress.hasAchievement(.comebackKid)
        {
            unlockAchievement(.comebackKid, for: userProgress)
            newlyUnlocked.append(.comebackKid)
        }

        return newlyUnlocked
    }

    private func unlockAchievement(_ achievementId: AchievementID, for progress: UserProgress) {
        progress.unlockAchievement(achievementId)
        do {
            try modelContext.save()
            onAchievementUnlocked?(achievementId)
        } catch {
            onError?("Unable to save achievement unlock.")
        }
    }

    struct SessionResults {
        let isFirstSession: Bool
        let hasPerfectRound: Bool
        let roundTimeSeconds: TimeInterval
        let currentStreak: Int
        let helpCoinsUsed: Int
        let wordsAttempted: Int
        let allWordsMastered: Bool
        let hadInitialMistakes: Bool
    }
}
