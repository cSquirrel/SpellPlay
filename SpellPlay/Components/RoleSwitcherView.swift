import SwiftUI

struct RoleSwitcherView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Switch Role") {
                    Text("Change between Parent and Kid mode")
                        .font(.system(size: AppConstants.bodySize))
                        .foregroundColor(.secondary)

                    Button(action: {
                        appState.selectedRole = .parent
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(AppConstants.primaryColor)
                            Text("Switch to Parent Mode")
                                .foregroundColor(.primary)
                                .accessibilityIdentifier("RoleSwitcher_ParentButton")
                            Spacer()
                            if appState.currentRole == .parent {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppConstants.primaryColor)
                            }
                        }
                    }

                    Button(action: {
                        appState.selectedRole = .child
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "face.smiling")
                                .foregroundColor(AppConstants.secondaryColor)
                            Text("Switch to Kid Mode")
                                .foregroundColor(.primary)
                                .accessibilityIdentifier("RoleSwitcher_ChildButton")
                            Spacer()
                            if appState.currentRole == .child {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppConstants.secondaryColor)
                            }
                        }
                    }
                }

                Section("Current Role") {
                    HStack {
                        Text("You are currently in:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(appState.currentRole == .parent ? "Parent Mode" : "Kid Mode")
                            .fontWeight(.semibold)
                            .foregroundColor(appState.currentRole == .parent ? AppConstants.primaryColor : AppConstants
                                .secondaryColor)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
