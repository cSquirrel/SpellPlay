//
//  View+Extensions.swift
//  SpellPlay
//
//  Created on [Date]
//

import SwiftUI

extension View {
    /// Applies a large button style for kid-friendly UI
    func largeButtonStyle(color: Color = AppConstants.primaryColor) -> some View {
        self
            .frame(height: AppConstants.largeButtonHeight)
            .frame(maxWidth: .infinity)
            .background(color)
            .foregroundColor(.white)
            .font(.system(size: AppConstants.bodySize, weight: .semibold))
            .cornerRadius(AppConstants.cornerRadius)
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
            .contentShape(Rectangle())
    }
    
    /// Applies card styling
    func cardStyle() -> some View {
        self
            .background(AppConstants.cardColor)
            .cornerRadius(AppConstants.cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

