import SwiftData
import SwiftUI

struct ParentHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SpellingTest.createdAt, order: .reverse)
    private var tests: [SpellingTest]

    @State private var showingCreateTest = false
    @State private var selectedTest: SpellingTest?
    @State private var showingRoleSwitcher = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.backgroundColor
                    .ignoresSafeArea()

                if tests.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "No Tests Yet",
                        message: "Create your first spelling test to get started",
                        actionTitle: "Create Test")
                    {
                        showingCreateTest = true
                    }
                    .accessibilityIdentifier("ParentHome_EmptyState")
                } else {
                    testListView
                }
            }
            .navigationTitle("My Spelling Tests")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 12) {
                        Button(action: {
                            showingRoleSwitcher = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                        }
                        .accessibilityIdentifier("ParentHome_SettingsButton")

                        SyncStatusView()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateTest = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .accessibilityIdentifier("ParentHome_CreateTestToolbarButton")
                }
            }
            .sheet(isPresented: $showingRoleSwitcher) {
                RoleSwitcherView()
            }
            .sheet(isPresented: $showingCreateTest) {
                CreateTestView()
            }
            .sheet(item: $selectedTest) { test in
                EditTestView(test: test)
            }
            .errorAlert(errorMessage: $errorMessage)
        }
    }

    private var testListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(tests) { test in
                    TestCardView(test: test, mode: .parent(
                        onEdit: { selectedTest = test },
                        onDelete: { deleteTest(test) }))
                }
            }
            .padding(AppConstants.padding)
        }
    }

    /// Delete a test directly using model context
    private func deleteTest(_ test: SpellingTest) {
        modelContext.delete(test)

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to delete test: \(error.localizedDescription)"
        }
    }
}
