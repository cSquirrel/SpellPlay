import SwiftUI

@MainActor
struct FishView: View {
    let letter: Character
    let id: UUID
    let color: Color
    let onTap: () -> Void

    @State private var tailWiggle: Double = 0

    var body: some View {
        ZStack {
            // Fish body
            FishShape()
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.95),
                            color.opacity(0.75),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing))
                .overlay {
                    FishShape()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                }
                .frame(width: 80, height: 50)
                .rotationEffect(.degrees(tailWiggle))

            // Letter overlay
            Text(String(letter).uppercased())
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onAppear {
            // Tail wiggle animation
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                tailWiggle = 8
            }
        }
        .accessibilityLabel("Fish letter \(String(letter))")
        .accessibilityIdentifier("FishCatcher_Fish_\(String(letter))_\(id.uuidString)")
    }
}

/// Custom fish shape (ellipse body + triangular tail)
private struct FishShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Body (ellipse)
        let bodyRect = CGRect(
            x: rect.minX + rect.width * 0.15,
            y: rect.minY + rect.height * 0.2,
            width: rect.width * 0.7,
            height: rect.height * 0.6)
        path.addEllipse(in: bodyRect)

        // Tail (triangle on the left)
        let tailSize = rect.width * 0.25
        path.move(to: CGPoint(x: rect.minX + tailSize, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY - tailSize * 0.5))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + tailSize * 0.5))
        path.closeSubpath()

        // Eye
        let eyeSize: CGFloat = 6
        let eyeX = rect.minX + rect.width * 0.4
        let eyeY = rect.minY + rect.height * 0.35
        path.addEllipse(in: CGRect(
            x: eyeX - eyeSize / 2,
            y: eyeY - eyeSize / 2,
            width: eyeSize,
            height: eyeSize))

        return path
    }
}
