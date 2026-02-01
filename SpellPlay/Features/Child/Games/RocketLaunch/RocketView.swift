import SwiftUI

struct RocketView: View {
    let fuelLevel: Double
    let isLaunching: Bool
    let verticalOffset: CGFloat

    @State private var flameAnimationPhase: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            // Rocket body
            rocketBody

            // Flame
            flameView
                .offset(y: 8)
        }
        .offset(y: verticalOffset)
        .onChange(of: fuelLevel) { _, _ in
            updateFlameAnimation()
        }
        .onChange(of: isLaunching) { _, _ in
            updateFlameAnimation()
        }
        .onAppear {
            updateFlameAnimation()
        }
    }

    private var rocketBody: some View {
        ZStack {
            // Main body (capsule)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.7, green: 0.7, blue: 0.75),
                            Color(red: 0.5, green: 0.5, blue: 0.55),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing))
                .frame(width: 40, height: 100)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2))

            // Nose cone
            Path { path in
                path.move(to: CGPoint(x: 20, y: 0))
                path.addLine(to: CGPoint(x: 10, y: 20))
                path.addLine(to: CGPoint(x: 30, y: 20))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.9, green: 0.3, blue: 0.3),
                        Color(red: 0.7, green: 0.2, blue: 0.2),
                    ],
                    startPoint: .top,
                    endPoint: .bottom))

            // Window
            Circle()
                .fill(Color(red: 0.3, green: 0.6, blue: 0.9))
                .frame(width: 16, height: 16)
                .offset(y: -20)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1))

            // Fins
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    // Left fin
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: -8, y: 15))
                        path.addLine(to: CGPoint(x: 0, y: 12))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 0.4, green: 0.4, blue: 0.45))
                    .offset(x: -20)

                    Spacer()

                    // Right fin
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 8, y: 15))
                        path.addLine(to: CGPoint(x: 0, y: 12))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 0.4, green: 0.4, blue: 0.45))
                    .offset(x: 20)
                }
            }
        }
    }

    private var flameView: some View {
        TimelineView(.animation) { _ in
            ZStack {
                // Outer flame (orange/yellow)
                ForEach(0 ..< 3, id: \.self) { i in
                    flameShape(
                        width: baseFlameWidth * (1.0 + Double(i) * 0.3),
                        height: baseFlameHeight * (1.0 + Double(i) * 0.2),
                        color: i == 0 ? Color.orange : (i == 1 ? Color.yellow : Color.red),
                        offset: Double(i) * 2)
                }
            }
        }
    }

    private func flameShape(width: Double, height: Double, color: Color, offset: Double) -> some View {
        Path { path in
            let phase = flameAnimationPhase + offset
            let w = width * (0.8 + 0.4 * sin(phase * 2))
            let h = height * (0.9 + 0.2 * sin(phase * 1.5))

            path.move(to: CGPoint(x: 20 - w / 2, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: 20 + w / 2, y: 0),
                control: CGPoint(x: 20, y: -h * 0.3))
            path.addLine(to: CGPoint(x: 20 + w / 3, y: -h))
            path.addQuadCurve(
                to: CGPoint(x: 20 - w / 3, y: -h),
                control: CGPoint(x: 20, y: -h * 1.2))
            path.closeSubpath()
        }
        .fill(
            RadialGradient(
                colors: [
                    color.opacity(0.9),
                    color.opacity(0.6),
                    color.opacity(0.0),
                ],
                center: .top,
                startRadius: 5,
                endRadius: height * 0.8))
    }

    private var baseFlameWidth: Double {
        if isLaunching {
            return 35
        }
        return 20 + (fuelLevel * 15)
    }

    private var baseFlameHeight: Double {
        if isLaunching {
            return 60
        }
        return 25 + (fuelLevel * 25)
    }

    private func updateFlameAnimation() {
        let intensity = isLaunching ? 2.0 : (0.5 + fuelLevel * 1.5)
        withAnimation(.linear(duration: 0.1 / intensity).repeatForever(autoreverses: true)) {
            flameAnimationPhase += 0.5
        }
    }
}
