import SwiftUI

struct RoleSelectionView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Welcome to WordCraft!")
                .font(.system(size: AppConstants.largeTitleSize, weight: .bold))
                .foregroundColor(AppConstants.primaryColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConstants.padding)
                .accessibilityIdentifier("RoleSelection_WelcomeText")

            Text("Choose your role to get started")
                .font(.system(size: AppConstants.bodySize))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConstants.padding)

            Spacer()

            VStack(spacing: 20) {
                Button(action: {
                    appState.selectedRole = .parent
                }) {
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                        Text("I am a Parent")
                            .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    }
                }
                .largeButtonStyle(color: AppConstants.primaryColor)
                .accessibilityIdentifier("RoleSelection_ParentButton")
                .accessibilityHint("Create and manage spelling tests")

                Button(action: {
                    appState.selectedRole = .child
                }) {
                    HStack {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 24))
                        Text("I am a Kid")
                            .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    }
                }
                .largeButtonStyle(color: AppConstants.secondaryColor)
                .accessibilityIdentifier("RoleSelection_ChildButton")
                .accessibilityHint("Practice spelling and play games")
            }
            .padding(.horizontal, AppConstants.padding)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppConstants.backgroundColor)
    }
}
