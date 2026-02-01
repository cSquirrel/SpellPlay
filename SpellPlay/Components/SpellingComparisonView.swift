import SwiftUI

/// A view that displays a spelling comparison letter-by-letter,
/// showing matching letters in green and incorrect letters in red.
struct SpellingComparisonView: View {
    let userAnswer: String
    let correctWord: String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(comparisonData.enumerated()), id: \.offset) { _, letterData in
                Text(letterData.letter)
                    .font(.system(size: AppConstants.bodySize, weight: .medium))
                    .foregroundColor(letterData.isCorrect ? AppConstants.successColor : AppConstants.errorColor)
            }
        }
    }

    private var comparisonData: [(letter: String, isCorrect: Bool)] {
        let userChars = Array(userAnswer.lowercased())
        let correctChars = Array(correctWord.lowercased())

        var result: [(letter: String, isCorrect: Bool)] = []

        // Compare each position in the user's answer
        for i in 0 ..< userChars.count {
            let userChar = String(userChars[i])
            let correctChar = i < correctChars.count ? String(correctChars[i]) : ""

            // Letter is correct if it matches the corresponding position in the correct word
            let isCorrect = !correctChar.isEmpty && userChar == correctChar

            result.append((letter: userChar, isCorrect: isCorrect))
        }

        return result
    }
}
