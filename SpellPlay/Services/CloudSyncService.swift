//
//  CloudSyncService.swift
//  WordCraft
//
//  CloudKit / iCloud sync monitoring helpers for SwiftData.
//

import CloudKit
import Foundation
import Observation
import SwiftData
import os

/// Represents the current synchronization state as surfaced to the UI.
enum SyncStatus: Equatable, Sendable {
    case idle
    case syncing
    case synced
    case error(String)
    case noAccount
    case restricted
    case disabled
    
    var displayMessage: String {
        switch self {
        case .idle:
            return "Ready"
        case .syncing:
            return "Syncing…"
        case .synced:
            return "All data synced"
        case .error(let message):
            return "Sync error: \(message)"
        case .noAccount:
            return "Sign in to iCloud to sync"
        case .restricted:
            return "iCloud access restricted"
        case .disabled:
            return "iCloud sync disabled"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .idle, .synced:
            return "checkmark.icloud"
        case .syncing:
            return "arrow.triangle.2.circlepath.icloud"
        case .error:
            return "exclamationmark.icloud"
        case .noAccount:
            return "person.crop.circle.badge.xmark"
        case .restricted, .disabled:
            return "xmark.icloud"
        }
    }
}

/// Service for monitoring iCloud account availability.
///
/// SwiftData handles the actual CloudKit sync; this service exists to:
/// - surface user-friendly status in UI
/// - help create the CloudKit-enabled `ModelConfiguration`
@MainActor
@Observable
final class CloudSyncService {
    nonisolated static let containerIdentifier = "iCloud.com.wordcraft.app"
    
    private(set) var syncStatus: SyncStatus = .idle
    private(set) var lastSyncDate: Date?
    private(set) var isCloudAvailable: Bool = false
    
    private let container: CKContainer
    private let logger = Logger(subsystem: "com.wordcraft.app", category: "CloudSync")
    
    init(containerIdentifier: String = CloudSyncService.containerIdentifier) {
        self.container = CKContainer(identifier: containerIdentifier)
        logger.info("🚀 CloudSyncService initialized with container: \(containerIdentifier, privacy: .public)")
        
        Task {
            await checkAccountStatus()
            startMonitoringAccountChanges()
        }
    }
    
    func checkAccountStatus() async {
        logger.info("🔍 Checking iCloud account status...")
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                isCloudAvailable = true
                if syncStatus == .idle {
                    syncStatus = .synced
                }
                logger.info("✅ iCloud account available - CloudKit sync enabled")
                
            case .noAccount:
                isCloudAvailable = false
                syncStatus = .noAccount
                logger.warning("⚠️ No iCloud account signed in - sync disabled")
                
            case .restricted:
                isCloudAvailable = false
                syncStatus = .restricted
                logger.warning("⚠️ iCloud access restricted (parental controls?) - sync disabled")
                
            case .couldNotDetermine:
                isCloudAvailable = false
                syncStatus = .error("Could not determine iCloud status")
                logger.error("❌ Could not determine iCloud status")
                
            case .temporarilyUnavailable:
                isCloudAvailable = false
                syncStatus = .error("iCloud temporarily unavailable")
                logger.warning("⚠️ iCloud temporarily unavailable - will retry")
                
            @unknown default:
                isCloudAvailable = false
                syncStatus = .error("Unknown iCloud status")
                logger.error("❌ Unknown iCloud account status: \(String(describing: status))")
            }
        } catch {
            isCloudAvailable = false
            syncStatus = .error(error.localizedDescription)
            logger.error("❌ Error checking iCloud status: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    /// Provides a user-triggered refresh. SwiftData sync is automatic; this just re-checks account state
    /// and updates UI to indicate activity.
    func refreshSync() async {
        logger.info("🔄 Manual sync refresh triggered")
        syncStatus = .syncing
        defer {
            self.lastSyncDate = Date()
            if self.isCloudAvailable {
                self.syncStatus = .synced
                logger.info("✅ Sync refresh completed at \(self.lastSyncDate?.formatted() ?? "unknown", privacy: .public)")
            } else {
                logger.warning("⚠️ Sync refresh completed but iCloud not available")
            }
        }
        
        await checkAccountStatus()
    }
    
    private func startMonitoringAccountChanges() {
        // We intentionally don't store/cancel this task. It captures `self` weakly and exits
        // automatically when `self` is released, which avoids actor-isolation issues in `deinit`.
        logger.info("👂 Started monitoring iCloud account changes")
        Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(named: .CKAccountChanged)
            for await _ in notifications {
                guard let self, !Task.isCancelled else { break }
                logger.info("📢 iCloud account changed notification received - rechecking status")
                await self.checkAccountStatus()
            }
        }
    }
}

extension CloudSyncService {
    static func makeCloudKitConfiguration(
        schema: Schema,
        isStoredInMemoryOnly: Bool = false
    ) -> ModelConfiguration {
        ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            cloudKitDatabase: isStoredInMemoryOnly ? .none : .private(containerIdentifier)
        )
    }
}


