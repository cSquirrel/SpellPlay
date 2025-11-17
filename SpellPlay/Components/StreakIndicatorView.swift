//
//  StreakIndicatorView.swift
//  SpellPlay
//
//  Created on [Date]
//

import SwiftUI

struct StreakIndicatorView: View {
    let streak: Int
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 24))
                .foregroundColor(AppConstants.secondaryColor)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isAnimating)
            
            Text("\(streak)")
                .font(.system(size: AppConstants.titleSize, weight: .bold))
                .foregroundColor(AppConstants.secondaryColor)
            
            Text("day streak")
                .font(.system(size: AppConstants.bodySize))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppConstants.secondaryColor.opacity(0.1))
        .cornerRadius(AppConstants.cornerRadius)
        .onAppear {
            if streak > 0 {
                isAnimating = true
            }
        }
    }
}

