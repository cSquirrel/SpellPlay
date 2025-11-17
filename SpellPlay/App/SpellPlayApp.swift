//
//  SpellPlayApp.swift
//  SpellPlay
//
//  Created on [Date]
//

import SwiftUI
import SwiftData

@main
struct SpellPlayApp: App {
    @State private var appState = AppState()
    @State private var showOnboarding = false
    
    var modelContainer: ModelContainer = {
        let schema = Schema([
            SpellingTest.self,
            Word.self,
            PracticeSession.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .modelContainer(modelContainer)
                .onAppear {
                    // Show onboarding if role is selected and onboarding not completed
                    if let role = appState.selectedRole, !appState.hasCompletedOnboarding {
                        showOnboarding = true
                    }
                }
                .onChange(of: appState.selectedRole) { oldValue, newValue in
                    // Show onboarding when a role is selected for the first time
                    if let role = newValue, !appState.hasCompletedOnboarding {
                        showOnboarding = true
                    } else if newValue == nil {
                        showOnboarding = false
                    }
                }
                .sheet(isPresented: $showOnboarding) {
                    if let role = appState.selectedRole {
                        OnboardingView(role: role, isPresented: $showOnboarding)
                            .onDisappear {
                                appState.hasCompletedOnboarding = true
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

