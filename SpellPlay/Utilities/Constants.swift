import SwiftUI

enum AppConstants {
    // Colors
    static let primaryColor = Color(red: 0.2, green: 0.6, blue: 0.9)
    static let secondaryColor = Color(red: 0.9, green: 0.5, blue: 0.2)
    static let successColor = Color(red: 0.2, green: 0.8, blue: 0.3)
    static let errorColor = Color(red: 0.9, green: 0.2, blue: 0.2)
    static let backgroundColor = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let cardColor = Color.white

    // Sizes
    static let minimumTouchTarget: CGFloat = 44
    static let largeButtonHeight: CGFloat = 60
    static let cornerRadius: CGFloat = 12
    static let padding: CGFloat = 16

    // Typography
    static let largeTitleSize: CGFloat = 34
    static let titleSize: CGFloat = 28
    static let bodySize: CGFloat = 17
    static let captionSize: CGFloat = 13

    // Strings
    static let appName = "SpellPlay"
    static let parentRole = "Parent"
    static let childRole = "Kid"
}

/// Provides encouraging feedback messages based on spelling similarity
enum FeedbackMessages {
    /// Messages for low similarity (<20% match)
    static let lowSimilarityMessages = [
        "Unlucky",
        "You've tried",
        "Needs practice",
        "Keep going",
        "Don't give up",
        "Try again",
        "Practice makes perfect",
        "You can do it",
        "Keep learning",
        "Stay focused",
    ]

    /// Messages for medium similarity (20-80% match)
    static let mediumSimilarityMessages = [
        "Great effort",
        "Working hard",
        "A little bit more",
        "Almost matched",
        "Getting closer",
        "Good attempt",
        "You're improving",
        "Nice try",
        "Keep it up",
        "Making progress",
    ]

    /// Messages for high similarity (>80% match)
    static let highSimilarityMessages = [
        "Near perfection",
        "Almost there",
        "Minor mistakes",
        "So close",
        "Almost perfect",
        "Just a bit off",
        "Very close",
        "Almost got it",
        "Nearly correct",
        "Almost right",
    ]

    /// Returns a random feedback message based on similarity percentage
    /// - Parameter similarity: A value between 0.0 and 1.0 representing similarity percentage
    /// - Returns: A random encouraging message from the appropriate category
    static func getFeedbackMessage(for similarity: Double) -> String {
        let messages: [String] = if similarity < 0.2 {
            // Low similarity (<20%)
            lowSimilarityMessages
        } else if similarity <= 0.8 {
            // Medium similarity (20-80%)
            mediumSimilarityMessages
        } else {
            // High similarity (>80%)
            highSimilarityMessages
        }

        // Return a random message from the selected category
        return messages.randomElement() ?? messages[0]
    }
}
