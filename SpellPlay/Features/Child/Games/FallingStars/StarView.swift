//
//  StarView.swift
//  SpellPlay
//
//  Star component for Falling Stars game
//

import SwiftUI

@MainActor
struct StarView: View {
    let letter: Character
    let id: UUID
    let onTap: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.6
    
    var body: some View {
        ZStack {
            // Outer glow
            StarShape()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.yellow.opacity(glowOpacity),
                            Color.yellow.opacity(0.1)
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .scaleEffect(pulseScale)
            
            // Star shape
            StarShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.95),
                            Color.orange.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    StarShape()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                }
                .frame(width: 60, height: 60)
            
            // Letter
            Text(String(letter).uppercased())
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .contentShape(Circle())
        .onTapGesture(perform: onTap)
        .onAppear {
            // Pulse animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
                glowOpacity = 0.9
            }
        }
        .accessibilityLabel("Star letter \(String(letter))")
        .accessibilityIdentifier("FallingStars_Star_\(String(letter))_\(id.uuidString)")
    }
}

// Custom star shape
private struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        
        var path = Path()
        
        // Create 5-pointed star
        for i in 0..<10 {
            let angle = Double(i) * .pi / 5 - .pi / 2
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = center.x + CGFloat(cos(angle)) * radius
            let y = center.y + CGFloat(sin(angle)) * radius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

