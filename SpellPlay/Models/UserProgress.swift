//
//  UserProgress.swift
//  WordCraft
//
//  User progress and gamification data model
//

import Foundation
import SwiftData

extension WordCraftSchemaV1_0_0 {
    @Model
    final class UserProgress {
        // CloudKit doesn't support unique constraints - removed @Attribute(.unique)
        var id: UUID = UUID()
        var totalPoints: Int = 0
        var totalStars: Int = 0
        var level: Int = 1
        var experiencePoints: Int = 0
        var unlockedAchievements: [String] = [] // Array of AchievementID rawValues
        var totalWordsMastered: Int = 0
        var totalSessionsCompleted: Int = 0
        var createdAt: Date = Date()
        var lastUpdated: Date = Date()
        
        init() {
            self.id = UUID()
            self.createdAt = Date()
            self.lastUpdated = Date()
        }
        
        func hasAchievement(_ achievementId: AchievementID) -> Bool {
            return unlockedAchievements.contains(achievementId.rawValue)
        }
        
        func unlockAchievement(_ achievementId: AchievementID) {
            if !hasAchievement(achievementId) {
                unlockedAchievements.append(achievementId.rawValue)
                lastUpdated = Date()
            }
        }
        
        func addPoints(_ points: Int) {
            totalPoints += points
            experiencePoints += points
            lastUpdated = Date()
        }
        
        func addStars(_ stars: Int) {
            totalStars += stars
            lastUpdated = Date()
        }
        
        func incrementWordsMastered() {
            totalWordsMastered += 1
            lastUpdated = Date()
        }
        
        func incrementSessionsCompleted() {
            totalSessionsCompleted += 1
            lastUpdated = Date()
        }
    }
}

