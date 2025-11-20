//
//  StatsView.swift
//  WordCraft
//
//  Stats view for child - separate tab
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProgress: [UserProgress]
    @State private var currentStreak = 0
    @State private var initialized = false
    
    private var progress: UserProgress? {
        userProgress.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if let progress = progress {
                            // Stats card with all metrics
                            StatsCardView()
                                .padding(.horizontal, AppConstants.padding)
                                .padding(.top, AppConstants.padding)
                            
                            // Streak indicator
                            if currentStreak > 0 {
                                StreakIndicatorView(streak: currentStreak)
                                    .padding(.horizontal, AppConstants.padding)
                            }
                            
                            // Additional stats section
                            VStack(spacing: 16) {
                                HStack {
                                    Text("More Stats")
                                        .font(.system(size: AppConstants.titleSize, weight: .bold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, AppConstants.padding)
                                
                                // Sessions completed
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Sessions Completed")
                                            .font(.system(size: AppConstants.bodySize))
                                            .foregroundColor(.secondary)
                                        Text("\(progress.totalSessionsCompleted)")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(AppConstants.primaryColor)
                                    }
                                    Spacer()
                                }
                                .padding(AppConstants.padding)
                                .background(AppConstants.primaryColor.opacity(0.1))
                                .cornerRadius(AppConstants.cornerRadius)
                                .padding(.horizontal, AppConstants.padding)
                            }
                        } else if !initialized {
                            // Initialize user progress on first appearance
                            Color.clear
                                .onAppear {
                                    let achievementService = AchievementService(modelContext: modelContext)
                                    _ = achievementService.getUserProgress()
                                    initialized = true
                                }
                        } else {
                            // Loading state
                            VStack(spacing: 16) {
                                ProgressView()
                                Text("Loading stats...")
                                    .font(.system(size: AppConstants.bodySize))
                                    .foregroundColor(.secondary)
                            }
                            .padding(AppConstants.padding * 2)
                        }
                    }
                }
            }
            .navigationTitle("My Stats")
            .onAppear {
                let service = StreakService(modelContext: modelContext)
                currentStreak = service.getCurrentStreak()
            }
        }
    }
}

