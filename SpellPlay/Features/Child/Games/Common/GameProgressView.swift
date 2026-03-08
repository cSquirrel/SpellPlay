import SwiftUI

@MainActor
struct GameProgressView: View {
    let title: String
    let wordIndex: Int
    let wordCount: Int
    let points: Int
    let comboMultiplier: Int

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
                    .accessibilityIdentifier("Game_Title")

                Spacer()

                Text("\(wordIndex + 1)/\(max(wordCount, 1))")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("Game_ProgressText")
            }

            HStack(spacing: 12) {
                PointsDisplayView(points: points)

                if comboMultiplier > 1 {
                    Text("\(comboMultiplier)x")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.yellow.opacity(0.15))
                        .clipShape(Capsule())
                        .accessibilityIdentifier("Game_ComboMultiplier")
                }

                Spacer()
            }
        }
        .padding(.horizontal, AppConstants.padding)
        .padding(.top, AppConstants.padding)
    }
}
