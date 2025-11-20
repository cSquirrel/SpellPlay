//
//  ComboIndicatorView.swift
//  WordCraft
//
//  Combo counter with multiplier display
//

import SwiftUI

struct ComboIndicatorView: View {
    let comboCount: Int
    let multiplier: Int
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 24))
                .foregroundColor(.yellow)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isPulsing)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(comboCount)x Combo")
                    .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    .foregroundColor(.primary)
                
                if multiplier > 1 {
                    Text("\(multiplier)x Multiplier")
                        .font(.system(size: AppConstants.captionSize, weight: .bold))
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(Color.yellow.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .stroke(Color.yellow, lineWidth: 2)
                )
        )
        .onAppear {
            if comboCount > 0 {
                isPulsing = true
            }
        }
        .onChange(of: comboCount) { oldValue, newValue in
            if newValue > oldValue && newValue > 0 {
                isPulsing = true
            } else if newValue == 0 {
                isPulsing = false
            }
        }
    }
}

