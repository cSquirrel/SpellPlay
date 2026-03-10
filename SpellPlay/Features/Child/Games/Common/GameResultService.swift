import Foundation

/// Centralized service for computing and formatting game results.
/// Single source of truth for result calculation; GameStateManager (#14) or Game Views Consolidation (#23) can call
/// this service.
enum GameResultService {
    /// Builds a `GameResult` from session aggregates. Stateless: same inputs always produce the same output.
    /// - Parameters:
    ///   - totalPoints: Total points earned in the session
    ///   - totalStars: Total stars earned (sum of per-word stars)
    ///   - wordsCompleted: Number of words completed
    ///   - totalMistakes: Total mistakes in the session
    /// - Returns: A `GameResult` with the given values
    static func calculate(
        totalPoints: Int,
        totalStars: Int,
        wordsCompleted: Int,
        totalMistakes: Int
    )
    -> GameResult {
        GameResult(
            totalPoints: totalPoints,
            totalStars: totalStars,
            wordsCompleted: wordsCompleted,
            totalMistakes: totalMistakes)
    }

    /// Returns stars (1–3) for a single word based on time and mistakes. Matches existing game behavior.
    /// - Parameters:
    ///   - timeTaken: Time taken for the word, or nil if not applicable
    ///   - mistakesThisWord: Number of mistakes on this word
    /// - Returns: 3 if fast and no mistakes, 2 if no mistakes, 1 otherwise
    static func starsForWord(timeTaken: TimeInterval?, mistakesThisWord: Int) -> Int {
        if mistakesThisWord == 0, let t = timeTaken, t <= PointsService.speedBonusThreshold {
            return 3
        }
        if mistakesThisWord == 0 {
            return 2
        }
        return 1
    }

    /// Formats a short summary string for a result (e.g. for accessibility or logging).
    static func formatSummary(_ result: GameResult) -> String {
        "\(result.totalPoints) points • \(result.totalStars) stars • \(result.wordsCompleted) words • \(result.totalMistakes) mistakes"
    }
}
