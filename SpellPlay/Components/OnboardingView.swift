//
//  OnboardingView.swift
//  SpellPlay
//
//  Created on [Date]
//

import SwiftUI

struct OnboardingView: View {
    let role: UserRole
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: role == .parent ? "book.fill" : "gamecontroller.fill")
                .font(.system(size: 80))
                .foregroundColor(role == .parent ? AppConstants.primaryColor : AppConstants.secondaryColor)
            
            Text(role == .parent ? "Parent Mode" : "Practice Mode")
                .font(.system(size: AppConstants.titleSize, weight: .bold))
                .foregroundColor(role == .parent ? AppConstants.primaryColor : AppConstants.secondaryColor)
            
            VStack(alignment: .leading, spacing: 16) {
                if role == .parent {
                    OnboardingItem(
                        icon: "plus.circle.fill",
                        text: "Create spelling tests by adding words"
                    )
                    OnboardingItem(
                        icon: "list.bullet",
                        text: "View and edit your saved tests"
                    )
                    OnboardingItem(
                        icon: "chart.bar.fill",
                        text: "See your child's progress"
                    )
                } else {
                    OnboardingItem(
                        icon: "play.circle.fill",
                        text: "Select a test to practice"
                    )
                    OnboardingItem(
                        icon: "speaker.wave.2.fill",
                        text: "Listen to word pronunciation"
                    )
                    OnboardingItem(
                        icon: "flame.fill",
                        text: "Build your daily streak"
                    )
                }
            }
            .padding(.horizontal, AppConstants.padding)
            
            Spacer()
            
            Button(action: {
                isPresented = false
            }) {
                Text("Get Started")
                    .font(.system(size: AppConstants.bodySize, weight: .semibold))
            }
            .largeButtonStyle(color: role == .parent ? AppConstants.primaryColor : AppConstants.secondaryColor)
            .padding(.horizontal, AppConstants.padding)
            .padding(.bottom, 40)
            .accessibilityIdentifier("Onboarding_GetStartedButton")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppConstants.backgroundColor)
    }
}

struct OnboardingItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppConstants.primaryColor)
                .frame(width: 32)
            
            Text(text)
                .font(.system(size: AppConstants.bodySize))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

