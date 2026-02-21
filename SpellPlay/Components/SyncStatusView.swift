import SwiftUI
import UIKit

struct SyncStatusView: View {
    @Environment(CloudSyncService.self) private var syncService
    @State private var showingDetails = false

    var body: some View {
        Button {
            showingDetails = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: syncService.syncStatus.systemImageName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor)
                    .symbolEffect(.pulse, isActive: syncService.syncStatus == .syncing)

                if syncService.syncStatus == .syncing {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(iconColor.opacity(0.15)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(syncService.syncStatus.displayMessage)
        .accessibilityIdentifier("syncStatusButton")
        .sheet(isPresented: $showingDetails) {
            SyncStatusDetailView()
        }
    }

    private var iconColor: Color {
        switch syncService.syncStatus {
        case .idle, .synced:
            .green
        case .syncing:
            .blue
        case .error:
            .red
        case .noAccount, .restricted, .disabled:
            .orange
        }
    }
}

struct SyncStatusDetailView: View {
    @Environment(CloudSyncService.self) private var syncService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Sync Status") {
                    HStack(spacing: 12) {
                        Image(systemName: syncService.syncStatus.systemImageName)
                            .font(.title2)
                            .foregroundStyle(statusColor)
                            .frame(width: 44, height: 44)
                            .background(statusColor.opacity(0.15))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(statusTitle)
                                .font(.headline)
                            Text(syncService.syncStatus.displayMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                if let lastSync = syncService.lastSyncDate {
                    Section {
                        HStack {
                            Text("Last refreshed")
                            Spacer()
                            Text(lastSync, style: .relative)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button {
                        // Explicit user action; fire-and-forget refresh (cancellation on navigate not required).
                        Task { await syncService.refreshSync() }
                    } label: {
                        Label("Refresh Sync Status", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(syncService.syncStatus == .syncing)
                } footer: {
                    Text(
                        "Your spelling tests and progress sync automatically across devices signed in to the same iCloud account.")
                }

                if !syncService.isCloudAvailable {
                    Section {
                        Button {
                            openSettings()
                        } label: {
                            Label("Open Settings", systemImage: "gear")
                        }
                    } footer: {
                        Text("Sign in to iCloud and enable iCloud Drive to allow syncing.")
                    }
                }
            }
            .navigationTitle("iCloud Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var statusTitle: String {
        switch syncService.syncStatus {
        case .idle, .synced:
            "Synced"
        case .syncing:
            "Syncing"
        case .error:
            "Error"
        case .noAccount:
            "Not Signed In"
        case .restricted:
            "Restricted"
        case .disabled:
            "Disabled"
        }
    }

    private var statusColor: Color {
        switch syncService.syncStatus {
        case .idle, .synced:
            .green
        case .syncing:
            .blue
        case .error:
            .red
        case .noAccount, .restricted, .disabled:
            .orange
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview("Sync Status") {
    SyncStatusView()
        .environment(CloudSyncService())
}

#Preview("Sync Detail") {
    SyncStatusDetailView()
        .environment(CloudSyncService())
}
