import SwiftUI

/// Reusable empty state view for displaying when content is not available.
/// Supports Dynamic Type and accessibility (optional title/button identifiers, button label and hint).
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    let titleAccessibilityIdentifier: String?
    let actionButtonAccessibilityIdentifier: String?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        titleAccessibilityIdentifier: String? = nil,
        actionButtonAccessibilityIdentifier: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        self.titleAccessibilityIdentifier = titleAccessibilityIdentifier
        self.actionButtonAccessibilityIdentifier = actionButtonAccessibilityIdentifier
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
                .accessibilityIdentifier(when: titleAccessibilityIdentifier)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConstants.padding)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.body.weight(.semibold))
                }
                .largeButtonStyle(color: AppConstants.primaryColor)
                .padding(.horizontal, AppConstants.padding)
                .accessibilityLabel(actionTitle)
                .accessibilityHint("Creates a new spelling test")
                .accessibilityIdentifier(when: actionButtonAccessibilityIdentifier)
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
        action: { print("Create test tapped") })
}

#Preview("Without Action") {
    EmptyStateView(
        icon: "book.closed",
        title: "No Tests Available",
        message: "Ask a parent to create a spelling test for you!")
}
