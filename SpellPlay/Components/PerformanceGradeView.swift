import SwiftUI

struct PerformanceGradeView: View {
    let grade: PerformanceGrade
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 12) {
            Text(grade.rawValue)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(grade.color)
                .scaleEffect(scale)
                .opacity(opacity)

            Text(gradeMessage)
                .font(.system(size: AppConstants.bodySize))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(grade.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .stroke(grade.color, lineWidth: 3)))
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }

    private var gradeMessage: String {
        switch grade {
        case .perfect:
            "Amazing! You got everything right on the first try!"
        case .excellent:
            "Outstanding work! You're doing great!"
        case .great:
            "Well done! Keep up the good work!"
        case .good:
            "Nice job! Practice makes perfect!"
        case .keepPracticing:
            "Good effort! Keep practicing to improve!"
        }
    }
}
