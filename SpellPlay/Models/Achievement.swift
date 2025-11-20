//
//  Achievement.swift
//  WordCraft
//
//  Achievement definitions and types
//

import Foundation

enum AchievementID: String, Codable {
    case firstSteps = "first_steps"
    case perfectRound = "perfect_round"
    case speedDemon = "speed_demon"
    case streakMaster = "streak_master"
    case wordWizard = "word_wizard"
    case noHelpNeeded = "no_help_needed"
    case comebackKid = "comeback_kid"
}

struct Achievement {
    let id: AchievementID
    let name: String
    let description: String
    let icon: String
    
    static let allAchievements: [Achievement] = [
        Achievement(
            id: .firstSteps,
            name: "First Steps",
            description: "Complete your first practice session",
            icon: "🎯"
        ),
        Achievement(
            id: .perfectRound,
            name: "Perfect Round",
            description: "Get all words correct in one round",
            icon: "⭐"
        ),
        Achievement(
            id: .speedDemon,
            name: "Speed Demon",
            description: "Complete a round in under 2 minutes",
            icon: "⚡"
        ),
        Achievement(
            id: .streakMaster,
            name: "Streak Master",
            description: "Maintain a 7-day streak",
            icon: "🔥"
        ),
        Achievement(
            id: .wordWizard,
            name: "Word Wizard",
            description: "Master 50 words total",
            icon: "🧙"
        ),
        Achievement(
            id: .noHelpNeeded,
            name: "No Help Needed",
            description: "Complete a session without using help coins",
            icon: "💪"
        ),
        Achievement(
            id: .comebackKid,
            name: "Comeback Kid",
            description: "Master all words after initial mistakes",
            icon: "🎪"
        )
    ]
    
    static func achievement(for id: AchievementID) -> Achievement? {
        return allAchievements.first { $0.id == id }
    }
}

