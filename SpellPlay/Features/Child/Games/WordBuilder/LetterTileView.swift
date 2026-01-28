//
//  LetterTileView.swift
//  SpellPlay
//
//  Draggable letter tile component for Word Builder game
//

import SwiftUI

@MainActor
struct LetterTileView: View {
    let letter: Character
    let isPlaced: Bool
    let isDragging: Bool
    
    var body: some View {
        Text(String(letter).uppercased())
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPlaced ? Color.gray.opacity(0.5) : AppConstants.primaryColor)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            )
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .opacity(isPlaced ? 0.5 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPlaced)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isDragging)
    }
}

