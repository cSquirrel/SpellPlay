//
//  PracticeSummaryView.swift
//  WordCraft
//
//  Created on [Date]
//

import SwiftUI

struct PracticeSummaryView: View {
    let roundsCompleted: Int
    let streak: Int
    let sessionPoints: Int
    let totalStars: Int
    let performanceGrade: PerformanceGrade?
    let newlyUnlockedAchievements: [AchievementID]
    let levelUpOccurred: Bool
    let newLevel: Int?
    let currentLevel: Int
    let experiencePoints: Int
    let onPracticeAgain: () -> Void
    let onBack: () -> Void
    
    @State private var showCelebration = true
    @State private var showLevelUp = false
    @State private var showAchievementUnlock = false
    @State private var currentAchievementIndex = 0
    
    var body: some View {
        ZStack {
            AppConstants.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer(minLength: 20)
                
                        // Level up celebration (if occurred)
                        if showLevelUp, let level = newLevel {
                            LevelUpView(newLevel: level)
                                .transition(.scale.combined(with: .opacity))
                                .padding(.bottom, 20)
                        }
                        
                        // Achievement unlock (if any)
                        if showAchievementUnlock, currentAchievementIndex < newlyUnlockedAchievements.count,
                           let achievement = Achievement.achievement(for: newlyUnlockedAchievements[currentAchievementIndex]) {
                            AchievementUnlockView(achievement: achievement)
                                .transition(.scale.combined(with: .opacity))
                                .padding(.bottom, 20)
                        }
                        
                        // Main celebration
                        if showCelebration && !showLevelUp && !showAchievementUnlock {
                            CelebrationView(type: .sessionComplete)
                        .transition(.scale.combined(with: .opacity))
                }
                
                        VStack(spacing: 20) {
                    Text("Practice Complete!")
                        .font(.system(size: AppConstants.largeTitleSize, weight: .bold))
                        .foregroundColor(AppConstants.primaryColor)
                            
                            // Performance grade
                            if let grade = performanceGrade {
                                PerformanceGradeView(grade: grade)
                            }
                            
                            // Points and stars
                            VStack(spacing: 16) {
                                HStack(spacing: 16) {
                                    // Points earned
                                    VStack(spacing: 8) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(AppConstants.secondaryColor)
                                        
                                        Text("\(sessionPoints)")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(AppConstants.primaryColor)
                                        
                                        Text("points")
                                            .font(.system(size: AppConstants.captionSize))
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(AppConstants.padding)
                                    .background(AppConstants.primaryColor.opacity(0.1))
                                    .cornerRadius(AppConstants.cornerRadius)
                                    
                                    // Stars earned
                                    VStack(spacing: 8) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.yellow)
                                        
                                        Text("\(totalStars)")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.primary)
                                        
                                        Text("stars")
                                            .font(.system(size: AppConstants.captionSize))
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(AppConstants.padding)
                                    .background(Color.yellow.opacity(0.1))
                                    .cornerRadius(AppConstants.cornerRadius)
                                }
                    
                    // Round count display
                    VStack(spacing: 8) {
                        Text("Completed in")
                            .font(.system(size: AppConstants.bodySize))
                            .foregroundColor(.secondary)
                        
                        Text("\(roundsCompleted) round\(roundsCompleted == 1 ? "" : "s")")
                                        .font(.system(size: 36, weight: .bold))
                            .foregroundColor(AppConstants.primaryColor)
                            .accessibilityIdentifier("PracticeSummary_RoundsCompleted")
                    }
                    .padding(AppConstants.padding * 2)
                    .cardStyle()
                                
                                // Level progress
                                LevelProgressView(
                                    level: currentLevel,
                                    experience: experiencePoints
                                )
                    
                    // Streak update
                    if streak > 0 {
                        StreakIndicatorView(streak: streak)
                    }
                                
                                // Newly unlocked achievements
                                if !newlyUnlockedAchievements.isEmpty {
                                    VStack(spacing: 12) {
                                        Text("Achievements Unlocked")
                                            .font(.system(size: AppConstants.titleSize, weight: .bold))
                                            .foregroundColor(.primary)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 12) {
                                                ForEach(newlyUnlockedAchievements, id: \.self) { achievementId in
                                                    if let achievement = Achievement.achievement(for: achievementId) {
                                                        AchievementBadgeView(
                                                            achievement: achievement,
                                                            isUnlocked: true
                                                        )
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, AppConstants.padding)
                                        }
                                    }
                                    .padding(.vertical, AppConstants.padding)
                                }
                            }
                }
                
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, AppConstants.padding)
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: onPracticeAgain) {
                        Text("Practice Again")
                            .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    }
                    .largeButtonStyle(color: AppConstants.primaryColor)
                    .accessibilityIdentifier("PracticeSummary_PracticeAgainButton")
                    
                    Button(action: onBack) {
                        Text("Back to Tests")
                            .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    }
                    .largeButtonStyle(color: AppConstants.secondaryColor)
                    .accessibilityIdentifier("PracticeSummary_BackToTestsButton")
                }
                .padding(.horizontal, AppConstants.padding)
                .padding(.bottom, 40)
                .background(AppConstants.backgroundColor)
            }
        }
        .task {
            // Show level up first if it occurred
            if levelUpOccurred {
                try? await Task.sleep(nanoseconds: 200_000_000)
                await MainActor.run {
                    withAnimation {
                        showLevelUp = true
                    }
                }
                // Wait for level up animation
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                await MainActor.run {
                    withAnimation {
                        showLevelUp = false
                    }
                }
            }
            
            // Then show achievement unlocks
            if !newlyUnlockedAchievements.isEmpty {
                for index in 0..<newlyUnlockedAchievements.count {
                    currentAchievementIndex = index
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    await MainActor.run {
                        withAnimation {
                            showAchievementUnlock = true
                        }
                    }
                    // Wait for achievement animation
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run {
                        withAnimation {
                            showAchievementUnlock = false
                        }
                    }
                }
            }
            
            // Finally show main celebration
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                withAnimation {
                    showCelebration = true
                }
            }
        }
    }
}

