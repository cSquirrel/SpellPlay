import Foundation

/// Level calculation service - pure static functions for level progression
/// Note: No @MainActor needed since these are pure calculations with no UI state
enum LevelService {
    /// Experience points needed per level (exponential growth)
    /// Level 1: 0 XP, Level 2: 100 XP, Level 3: 250 XP, etc.
    static func experienceForLevel(_ level: Int) -> Int {
        if level <= 1 {
            return 0
        }
        // Exponential formula: 100 * (level - 1)^1.5
        let base = Double(level - 1)
        return Int(100 * pow(base, 1.5))
    }

    /// Calculate level from total experience points
    static func levelFromExperience(_ experience: Int) -> Int {
        var level = 1
        while experience >= experienceForLevel(level + 1) {
            level += 1
        }
        return level
    }

    /// Calculate experience needed for next level
    static func experienceNeededForNextLevel(currentLevel: Int) -> Int {
        let nextLevel = currentLevel + 1
        let currentXP = experienceForLevel(currentLevel)
        let nextXP = experienceForLevel(nextLevel)
        return nextXP - currentXP
    }

    /// Calculate progress to next level (0.0 to 1.0)
    static func progressToNextLevel(currentLevel: Int, currentExperience: Int) -> Double {
        let currentLevelXP = experienceForLevel(currentLevel)
        let nextLevelXP = experienceForLevel(currentLevel + 1)
        let experienceInCurrentLevel = currentExperience - currentLevelXP
        let experienceNeeded = nextLevelXP - currentLevelXP

        guard experienceNeeded > 0 else { return 1.0 }

        return min(1.0, Double(experienceInCurrentLevel) / Double(experienceNeeded))
    }

    /// Check if user should level up and return new level if so
    static func checkLevelUp(currentLevel: Int, currentExperience: Int) -> Int? {
        let newLevel = levelFromExperience(currentExperience)
        if newLevel > currentLevel {
            return newLevel
        }
        return nil
    }
}
