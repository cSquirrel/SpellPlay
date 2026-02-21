import SwiftUI

struct WordInputView: View {
    @Binding var text: String
    let onSubmit: () -> Void
    let placeholder: String
    var isDisabled: Bool = false

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
                .disabled(isDisabled)
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
            }
            .frame(height: AppConstants.largeButtonHeight)
            .frame(maxWidth: .infinity)
            .background(text.isEmpty ? AppConstants.primaryColor.opacity(0.6) : AppConstants.primaryColor)
            .cornerRadius(AppConstants.cornerRadius)
            .shadow(color: AppConstants.primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
            .contentShape(Rectangle())
            .allowsHitTesting(!text.isEmpty)
            .accessibilityLabel("Submit answer")
            .accessibilityHint("Submits your spelling for the current word")
            .accessibilityIdentifier("WordInput_SubmitButton")
        }
        .onAppear {
            // Focus the field after a short delay to ensure view is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
        .task {
            // Also try to focus when task starts
            try? await Task.sleep(nanoseconds: 300_000_000)
            isFocused = true
        }
        .onChange(of: text) { oldValue, newValue in
            // Refocus when text is cleared (moving to next word)
            if oldValue.isEmpty == false, newValue.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if !isDisabled {
                        isFocused = true
                    }
                }
            }
        }
        .onChange(of: isDisabled) { oldValue, newValue in
            // Refocus when field becomes enabled again
            if oldValue == true, newValue == false {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            }
        }
    }
}
