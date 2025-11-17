//
//  PracticeSummaryView.swift
//  SpellPlay
//
//  Created on [Date]
//

import SwiftUI

struct PracticeSummaryView: View {
    let score: (correct: Int, total: Int)
    let streak: Int
    let onPracticeAgain: () -> Void
    let onBack: () -> Void
    
    @State private var showCelebration = true
    
    var percentage: Int {
        guard score.total > 0 else { return 0 }
        return Int((Double(score.correct) / Double(score.total)) * 100)
    }
    
    var body: some View {
        ZStack {
            AppConstants.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                if showCelebration && percentage >= 80 {
                    CelebrationView()
                        .transition(.scale.combined(with: .opacity))
                }
                
                VStack(spacing: 16) {
                    Text("Practice Complete!")
                        .font(.system(size: AppConstants.largeTitleSize, weight: .bold))
                        .foregroundColor(AppConstants.primaryColor)
                    
                    // Score display
                    VStack(spacing: 8) {
                        Text("\(score.correct) / \(score.total)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(percentage)%")
                            .font(.system(size: AppConstants.titleSize, weight: .semibold))
                            .foregroundColor(percentage >= 80 ? AppConstants.successColor : AppConstants.errorColor)
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
        .onAppear {
            if percentage >= 80 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        showCelebration = true
                    }
                }
            }
        }
    }
}

