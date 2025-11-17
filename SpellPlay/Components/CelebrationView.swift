//
//  CelebrationView.swift
//  SpellPlay
//
//  Created on [Date]
//

import SwiftUI

struct CelebrationView: View {
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Confetti effect using emojis
            if showConfetti {
                ForEach(0..<20, id: \.self) { index in
                    Text(["🎉", "⭐", "✨", "🎊", "🌟"].randomElement() ?? "🎉")
                        .font(.system(size: 30))
                        .offset(
                            x: CGFloat.random(in: -150...150),
                            y: CGFloat.random(in: -200...200)
                        )
                        .opacity(showConfetti ? 1 : 0)
                        .animation(
                            .easeOut(duration: 1.5)
                            .delay(Double(index) * 0.05),
                            value: showConfetti
                        )
                }
            }
            
            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 80))
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                
                Text("Great Job!")
                    .font(.system(size: AppConstants.titleSize, weight: .bold))
                    .foregroundColor(AppConstants.successColor)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                rotation = 360
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }
}

