import SwiftUI

struct PointsDisplayView: View {
    let points: Int
    @State private var displayedPoints: Int = 0
    @State private var showPopup = false
    @State private var popupPoints: Int = 0

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 20))
                .foregroundColor(AppConstants.secondaryColor)

            Text("\(displayedPoints)")
                .font(.system(size: AppConstants.titleSize, weight: .bold))
                .foregroundColor(AppConstants.primaryColor)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppConstants.primaryColor.opacity(0.1))
        .cornerRadius(AppConstants.cornerRadius)
        .overlay(
            // Points popup animation
            Group {
                if showPopup {
                    Text("+\(popupPoints)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppConstants.secondaryColor)
                        .padding(12)
                        .background(AppConstants.secondaryColor.opacity(0.2))
                        .cornerRadius(8)
                        .offset(y: -60)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showPopup)
                }
            })
        .onChange(of: points) { oldValue, newValue in
            let difference = newValue - oldValue
            if difference > 0 {
                popupPoints = difference
                withAnimation {
                    showPopup = true
                }

                // Animate counter
                withAnimation(.easeOut(duration: 0.5)) {
                    displayedPoints = newValue
                }

                // Hide popup after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        showPopup = false
                    }
                }
            } else {
                displayedPoints = newValue
            }
        }
        .onAppear {
            displayedPoints = points
        }
    }
}
