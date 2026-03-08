import SwiftUI

struct StarCollectionView: View {
    let stars: Int
    let totalStars: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedStars: Int = 0

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< 3, id: \.self) { index in
                Image(systemName: index < stars ? "star.fill" : "star")
                    .font(.system(size: 20))
                    .foregroundColor(index < stars ? .yellow : .gray.opacity(0.3))
                    .scaleEffect(index < animatedStars ? 1.2 : 1.0)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6).delay(Double(index) * 0.1),
                        value: animatedStars)
            }

            if totalStars > 0 {
                Text("(\(totalStars) total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(AppConstants.cornerRadius)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stars) of 3 stars earned, \(totalStars) total")
        .onChange(of: stars) { oldValue, newValue in
            if newValue > oldValue {
                withAnimation {
                    animatedStars = newValue
                }
            } else {
                animatedStars = newValue
            }
        }
        .onAppear {
            animatedStars = stars
        }
    }
}

struct SessionStarTotalView: View {
    let totalStars: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 24))
                .foregroundColor(.yellow)
                .accessibilityHidden(true)

            Text("\(totalStars)")
                .font(.title.bold())
                .foregroundColor(.primary)

            Text("stars earned")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.yellow.opacity(0.15))
        .cornerRadius(AppConstants.cornerRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(totalStars) stars earned")
    }
}
