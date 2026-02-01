import Foundation

/// Points calculation service - pure static functions for calculating game points
/// Note: No @MainActor needed since these are pure calculations with no UI state
enum PointsService {
    // Point values
    static let basePointsPerCorrect = 10
    static let perfectRoundBonus = 50
    static let speedBonusThreshold: TimeInterval = 5.0 // seconds for speed bonus
    static let speedBonusPoints = 5

    // Combo multipliers
    static let maxComboMultiplier = 4
    static let comboThresholds = [2, 5, 10] // Combo counts for 2x, 3x, 4x

    struct PointsResult {
        let basePoints: Int
        let comboMultiplier: Int
        let speedBonus: Int
        let totalPoints: Int
    }

    /// Calculate points for a correct answer
    static func calculatePoints(
        isCorrect: Bool,
        comboCount: Int,
        timeTaken: TimeInterval? = nil,
        isFirstTry: Bool = false
    )
    -> PointsResult {
        guard isCorrect else {
            return PointsResult(basePoints: 0, comboMultiplier: 1, speedBonus: 0, totalPoints: 0)
        }

        var basePoints = basePointsPerCorrect

        // Calculate combo multiplier
        let multiplier: Int = if comboCount >= comboThresholds[2] {
            maxComboMultiplier
        } else if comboCount >= comboThresholds[1] {
            3
        } else if comboCount >= comboThresholds[0] {
            2
        } else {
            1
        }

        // Speed bonus
        var speedBonus = 0
        if let time = timeTaken, time <= speedBonusThreshold {
            speedBonus = speedBonusPoints
        }

        let totalPoints = (basePoints + speedBonus) * multiplier

        return PointsResult(
            basePoints: basePoints,
            comboMultiplier: multiplier,
            speedBonus: speedBonus,
            totalPoints: totalPoints)
    }

    /// Calculate combo multiplier for a given combo count
    static func getComboMultiplier(for comboCount: Int) -> Int {
        if comboCount >= comboThresholds[2] {
            maxComboMultiplier
        } else if comboCount >= comboThresholds[1] {
            3
        } else if comboCount >= comboThresholds[0] {
            2
        } else {
            1
        }
    }

    /// Calculate perfect round bonus
    static func getPerfectRoundBonus() -> Int {
        perfectRoundBonus
    }
}
