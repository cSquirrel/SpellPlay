//
//  AchievementBadgeView.swift
//  WordCraft
//
//  Achievement badge display
//

import SwiftUI

struct AchievementBadgeView: View {
    let achievement: Achievement
    let isUnlocked: Bool
    @State private var showAnimation = false
    
    var body: some View {
        VStack(spacing: 8) {
            Text(achievement.icon)
                .font(.system(size: 50))
                .scaleEffect(showAnimation ? 1.2 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showAnimation)
            
            Text(achievement.name)
                .font(.system(size: AppConstants.bodySize, weight: .bold))
                .foregroundColor(.primary)
            
            Text(achievement.description)
                .font(.system(size: AppConstants.captionSize))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(isUnlocked ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .stroke(isUnlocked ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                )
        )
        .opacity(isUnlocked ? 1.0 : 0.6)
        .onAppear {
            if isUnlocked {
                showAnimation = true
            }
        }
    }
}

struct AchievementUnlockView: View {
    let achievement: Achievement
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = 0
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // Confetti effect
            if showConfetti {
                ForEach(0..<30, id: \.self) { index in
                    Text(["🎉", "⭐", "✨", "🎊", "🌟", "💫"].randomElement() ?? "🎉")
                        .font(.system(size: 25))
                        .offset(
                            x: CGFloat.random(in: -200...200),
                            y: CGFloat.random(in: -250...250)
                        )
                        .opacity(showConfetti ? 1 : 0)
                        .animation(
                            .easeOut(duration: 2.0)
                            .delay(Double(index) * 0.05),
                            value: showConfetti
                        )
                }
            }
            
            VStack(spacing: 20) {
                Text("Achievement Unlocked!")
                    .font(.system(size: AppConstants.titleSize, weight: .bold))
                    .foregroundColor(AppConstants.primaryColor)
                
                AchievementBadgeView(achievement: achievement, isUnlocked: true)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                
                Text(achievement.name)
                    .font(.system(size: AppConstants.largeTitleSize, weight: .bold))
                    .foregroundColor(AppConstants.secondaryColor)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                rotation = 360
            }
            
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                await MainActor.run {
                    showConfetti = true
                }
            }
        }
    }
}

