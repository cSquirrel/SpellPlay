//
//  WordInputView.swift
//  SpellPlay
//
//  Created on [Date]
//

import SwiftUI

struct WordInputView: View {
    @Binding var text: String
    let onSubmit: () -> Void
    let placeholder: String
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: AppConstants.bodySize))
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(AppConstants.cornerRadius)
                .focused($isFocused)
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .submitLabel(.done)
                .accessibilityIdentifier("WordInput_TextField")
                .onSubmit {
                    if !text.isEmpty {
                        onSubmit()
                    }
                }
            
            ZStack {
                // Invisible tap area covering entire button - must fill entire ZStack
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !text.isEmpty {
                            onSubmit()
                        }
                    }
                
                // Visible button content
                Text("Submit")
                    .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    .foregroundColor(.white)
                    .accessibilityIdentifier("WordInput_SubmitButton")
            }
            .frame(height: AppConstants.largeButtonHeight)
            .frame(maxWidth: .infinity)
            .background(text.isEmpty ? AppConstants.primaryColor.opacity(0.6) : AppConstants.primaryColor)
            .cornerRadius(AppConstants.cornerRadius)
            .shadow(color: AppConstants.primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
            .contentShape(Rectangle())
            .allowsHitTesting(!text.isEmpty)
        }
        .onAppear {
            isFocused = true
        }
    }
}

