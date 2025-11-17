//
//  PracticeSummaryView.swift
//  SpellPlay
//
//  Created on [Date]
//

import SwiftUI

struct PracticeSummaryView: View {
    let roundsCompleted: Int
    let streak: Int
    let onPracticeAgain: () -> Void
    let onBack: () -> Void
    
    @State private var showCelebration = true
    
    var body: some View {
        ZStack {
            AppConstants.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                if showCelebration {
                    CelebrationView()
                        .transition(.scale.combined(with: .opacity))
                }
                
                VStack(spacing: 16) {
                    Text("Practice Complete!")
                        .font(.system(size: AppConstants.largeTitleSize, weight: .bold))
                        .foregroundColor(AppConstants.primaryColor)
                    
                    // Round count display
                    VStack(spacing: 8) {
                        Text("Completed in")
                            .font(.system(size: AppConstants.bodySize))
                            .foregroundColor(.secondary)
                        
                        Text("\(roundsCompleted) round\(roundsCompleted == 1 ? "" : "s")")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(AppConstants.primaryColor)
                    }
                    .padding(AppConstants.padding * 2)
                    .cardStyle()
                    
                    // Streak update
                    if streak > 0 {
                        StreakIndicatorView(streak: streak)
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: onPracticeAgain) {
                        Text("Practice Again")
                            .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    }
                    .largeButtonStyle(color: AppConstants.primaryColor)
                    
                    Button(action: onBack) {
                        Text("Back to Tests")
                            .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    }
                    .largeButtonStyle(color: AppConstants.secondaryColor)
                }
                .padding(.horizontal, AppConstants.padding)
                .padding(.bottom, 40)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            await MainActor.run {
                withAnimation {
                    showCelebration = true
                }
            }
        }
    }
}

