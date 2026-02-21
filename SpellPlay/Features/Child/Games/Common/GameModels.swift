import Foundation

enum GameDifficulty: String, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        }
    }
}

enum GamePhase: Equatable {
    case ready
    case playing
    case wordComplete
    case gameComplete
}

struct GameResult: Equatable {
    let totalPoints: Int
    let totalStars: Int
    let wordsCompleted: Int
    let totalMistakes: Int
}

/// Protocol for computing final game result. Implemented by GameResultService (#15).
/// GameStateManager calls this when finishing a game; result calculation is not done inline.
protocol GameResultServiceProtocol: AnyObject {
    func calculateResult(score: Int, totalStars: Int, wordsCompleted: Int, totalMistakes: Int) -> GameResult
}
