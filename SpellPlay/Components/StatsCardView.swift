import SwiftData
import SwiftUI

struct StatsCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProgress: [UserProgress]
    @State private var initialized = false

    private var progress: UserProgress? {
        userProgress.first
    }

    var body: some View {
        Group {
            if let progress {
                statsContent(progress: progress)
            } else if !initialized {
                // Initialize user progress on first appearance
                Color.clear
                    .onAppear {
                        let achievementService = AchievementService(modelContext: modelContext)
                        _ = achievementService.getUserProgress()
                        initialized = true
                    }
            } else {
                // Show empty state while loading
                VStack {
                    Text("Loading stats...")
                        .font(.system(size: AppConstants.bodySize))
                        .foregroundColor(.secondary)
                }
                .padding(AppConstants.padding)
                .cardStyle()
            }
        }
    }

    @ViewBuilder
    private func statsContent(progress: UserProgress) -> some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("My Stats")
                    .font(.system(size: AppConstants.titleSize, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }

            // Main stats grid
            VStack(spacing: 12) {
                // Top row: Level and Points
                HStack(spacing: 12) {
                    // Level
                    VStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppConstants.secondaryColor)

                        Text("Level")
                            .font(.system(size: AppConstants.captionSize))
                            .foregroundColor(.secondary)

                        Text("\(progress.level)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppConstants.primaryColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppConstants.primaryColor.opacity(0.1))
                    .cornerRadius(AppConstants.cornerRadius)

                    // Total Points
                    VStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppConstants.secondaryColor)

                        Text("Points")
                            .font(.system(size: AppConstants.captionSize))
                            .foregroundColor(.secondary)

                        Text("\(progress.totalPoints)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppConstants.primaryColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppConstants.primaryColor.opacity(0.1))
                    .cornerRadius(AppConstants.cornerRadius)
                }

                // Second row: Stars and Words
                HStack(spacing: 12) {
                    // Total Stars
                    VStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.yellow)

                        Text("Stars")
                            .font(.system(size: AppConstants.captionSize))
                            .foregroundColor(.secondary)

                        Text("\(progress.totalStars)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(AppConstants.cornerRadius)

                    // Words Mastered
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppConstants.successColor)

                        Text("Words")
                            .font(.system(size: AppConstants.captionSize))
                            .foregroundColor(.secondary)

                        Text("\(progress.totalWordsMastered)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppConstants.successColor.opacity(0.1))
                    .cornerRadius(AppConstants.cornerRadius)
                }

                // Level Progress
                LevelProgressView(
                    level: progress.level,
                    experience: progress.experiencePoints)
            }

            // Achievements section - show all achievements
            VStack(spacing: 12) {
                HStack {
                    Text("Achievements")
                        .font(.system(size: AppConstants.bodySize, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(progress.unlockedAchievements.count)/\(Achievement.allAchievements.count)")
                        .font(.system(size: AppConstants.captionSize))
                        .foregroundColor(.secondary)
                }

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ], spacing: 12) {
                    ForEach(Achievement.allAchievements, id: \.id) { achievement in
                        let isUnlocked = progress.hasAchievement(achievement.id)

                        VStack(spacing: 6) {
                            Text(achievement.icon)
                                .font(.system(size: 40))

                            Text(achievement.name)
                                .font(.system(size: AppConstants.captionSize, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(width: 80)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(isUnlocked ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isUnlocked ? Color.green : Color.gray.opacity(0.3), lineWidth: 2))
                        .opacity(isUnlocked ? 1.0 : 0.4) // Fade out locked achievements
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(AppConstants.padding)
        .cardStyle()
    }
}
