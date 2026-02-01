//
//  GameModels.swift
//  SpellPlay
//

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



