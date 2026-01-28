//
//  WordCraftApp.swift
//  WordCraft
//
//  Created on [Date]
//

import SwiftUI
import SwiftData

@main
struct WordCraftApp: App {
    @State private var appState = AppState()
    @State private var cloudSyncService = CloudSyncService()
    @State private var showOnboarding = false
    
    var modelContainer: ModelContainer = {
        let migrationPlan = WordCraftMigrationPlan.self
        
        // Create schema from the current versioned schema
        let schema = Schema(CurrentSchema.models)
        
        let modelConfiguration = CloudSyncService.makeCloudKitConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: migrationPlan,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // Force light mode
                .environment(appState)
                .environment(cloudSyncService)
                .modelContainer(modelContainer)
                .onAppear {
                    // Show onboarding if role is selected and onboarding not completed for that role
                    if let role = appState.selectedRole, !appState.hasCompletedOnboarding(for: role) {
                        showOnboarding = true
                    }
                }
                .onChange(of: appState.selectedRole) { oldValue, newValue in
                    // Show onboarding when a role is selected for the first time
                    if let role = newValue, !appState.hasCompletedOnboarding(for: role) {
                        showOnboarding = true
                    } else if newValue == nil {
                        showOnboarding = false
                    }
                }
                .sheet(isPresented: $showOnboarding) {
                    if let role = appState.selectedRole {
                        OnboardingView(role: role, isPresented: $showOnboarding)
                            .onDisappear {
                                appState.setOnboardingCompleted(for: role, completed: true)
                            }
                    }
                }
        }
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            if let role = appState.currentRole {
                switch role {
                case .parent:
                    ParentHomeView()
                case .child:
                    ChildHomeView()
                }
            } else {
                RoleSelectionView(appState: appState)
            }
        }
    }
}

