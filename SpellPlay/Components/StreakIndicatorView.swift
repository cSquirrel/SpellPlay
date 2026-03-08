import SwiftUI

struct StreakIndicatorView: View {
    let streak: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 24))
                .foregroundColor(AppConstants.secondaryColor)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                    value: isAnimating)
                .accessibilityHidden(true)

            Text("\(streak)")
                .font(.title.bold())
                .foregroundColor(AppConstants.secondaryColor)

            Text("day streak")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppConstants.secondaryColor.opacity(0.1))
        .cornerRadius(AppConstants.cornerRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(streak) day streak")
        .onAppear {
            if streak > 0, !reduceMotion {
                isAnimating = true
            }
        }
    }
}
