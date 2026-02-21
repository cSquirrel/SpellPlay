import SwiftData
import SwiftUI

struct ChildHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SpellingTest.createdAt, order: .reverse)
    private var tests: [SpellingTest]

    @State private var selectedTest: SpellingTest?
    @State private var currentStreak = 0
    @State private var showingRoleSwitcher = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tests Tab
            testsTabView
                .tabItem {
                    Label("Tests", systemImage: "book.fill")
                }
                .tag(0)

            // Stats Tab
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "star.fill")
                }
                .tag(1)
        }
    }

    private var testsTabView: some View {
        NavigationStack {
            ZStack {
                AppConstants.backgroundColor
                    .ignoresSafeArea()

                if tests.isEmpty {
                    emptyStateView
                } else {
                    testListView
                }
            }
            .navigationTitle("WordCraft")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SyncStatusView()
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingRoleSwitcher = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityIdentifier("ChildHome_SettingsButton")
                }
            }
            .onAppear {
                let service = StreakService(modelContext: modelContext)
                currentStreak = service.getCurrentStreak()
            }
            .sheet(item: $selectedTest) { test in
                WordReviewView(test: test)
            }
            .sheet(isPresented: $showingRoleSwitcher) {
                RoleSwitcherView()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Tests Available")
                .font(.system(size: AppConstants.titleSize, weight: .semibold))
                .foregroundColor(.primary)
                .accessibilityIdentifier("ChildHome_EmptyStateText")

            Text("Ask a parent to create a spelling test for you!")
                .font(.system(size: AppConstants.bodySize))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConstants.padding)
        }
    }

    private var testListView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Streak indicator
                if currentStreak > 0 {
                    StreakIndicatorView(streak: currentStreak)
                        .padding(.horizontal, AppConstants.padding)
                        .padding(.top, AppConstants.padding)
                }

                // Test cards
                LazyVStack(spacing: 16) {
                    ForEach(tests) { test in
                        TestCardView(test: test, mode: .child(onStart: {
                            selectedTest = test
                        }))
                    }
                }
                .padding(.horizontal, AppConstants.padding)
            }
        }
    }
}
