//
//  BalloonView.swift
//  SpellPlay
//

import SwiftUI

@MainActor
struct BalloonView: View {
    let letter: Character
    let color: Color
    let onTap: () -> Void

    @State private var wobbleDegrees: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.95), color.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Ellipse()
                            .stroke(Color.white.opacity(0.25), lineWidth: 2)
                    }
                    .frame(width: 70, height: 90)

                Text(String(letter).uppercased())
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
            }

            // Knot
            Triangle()
                .fill(color.opacity(0.9))
                .frame(width: 16, height: 12)
                .offset(y: -2)

            // String
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addCurve(
                    to: CGPoint(x: 0, y: 40),
                    control1: CGPoint(x: -8, y: 12),
                    control2: CGPoint(x: 8, y: 28)
                )
            }
            .stroke(Color.gray.opacity(0.7), lineWidth: 2)
            .frame(width: 2, height: 40)
        }
        .rotationEffect(.degrees(wobbleDegrees))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                wobbleDegrees = 4
            }
        }
        .accessibilityLabel("Balloon letter \(String(letter))")
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}



