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
                    // Show onboarding if role not selected
                    if appState.selectedRole == nil {
                        showOnboarding = false
                    } else if !appState.hasCompletedOnboarding {
                        showOnboarding = true
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

