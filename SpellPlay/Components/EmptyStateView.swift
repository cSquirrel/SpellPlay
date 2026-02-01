//
//  EmptyStateView.swift
//  SpellPlay
//
//  Reusable empty state component
//

import SwiftUI

/// Reusable empty state view for displaying when content is not available
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.system(size: AppConstants.titleSize, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(message)
                .font(.system(size: AppConstants.bodySize))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConstants.padding)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: AppConstants.bodySize, weight: .semibold))
                }
                .largeButtonStyle(color: AppConstants.primaryColor)
                .padding(.horizontal, AppConstants.padding)
            }
        }
    }
}

#Preview("With Action") {
    EmptyStateView(
        icon: "book.closed",
        title: "No Tests Yet",
        message: "Create your first spelling test to get started",
        actionTitle: "Create Test",
        action: { print("Create test tapped") }
    )
}

#Preview("Without Action") {
    EmptyStateView(
        icon: "book.closed",
        title: "No Tests Available",
        message: "Ask a parent to create a spelling test for you!"
    )
}

