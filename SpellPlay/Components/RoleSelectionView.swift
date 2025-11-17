//
//  RoleSelectionView.swift
//  SpellPlay
//
//  Created on [Date]
//

import SwiftUI

struct RoleSelectionView: View {
    @Bindable var appState: AppState
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("Welcome to SpellPlay!")
                .font(.system(size: AppConstants.largeTitleSize, weight: .bold))
                .foregroundColor(AppConstants.primaryColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConstants.padding)
            
            Text("Choose your role to get started")
                .font(.system(size: AppConstants.bodySize))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConstants.padding)
            
            Spacer()
            
            VStack(spacing: 20) {
                Button(action: {
                    appState.selectedRole = .parent
                }) {
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                        Text("I am a Parent")
                            .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    }
                }
                .largeButtonStyle(color: AppConstants.primaryColor)
                
                Button(action: {
                    appState.selectedRole = .child
                }) {
                    HStack {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 24))
                        Text("I am a Kid")
                            .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    }
                }
                .largeButtonStyle(color: AppConstants.secondaryColor)
            }
            .padding(.horizontal, AppConstants.padding)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppConstants.backgroundColor)
    }
}

