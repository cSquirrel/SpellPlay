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
                .onSubmit {
                    if !text.isEmpty {
                        onSubmit()
                    }
                }
            
            Button(action: {
                onSubmit()
            }) {
                Text("Submit")
                    .font(.system(size: AppConstants.bodySize, weight: .semibold))
            }
            .largeButtonStyle(color: AppConstants.primaryColor)
            .disabled(text.isEmpty)
            .opacity(text.isEmpty ? 0.6 : 1.0)
        }
        .onAppear {
            isFocused = true
        }
    }
}

