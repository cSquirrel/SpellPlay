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
                        actionTitle: "Create Test",
                        action: { showingCreateTest = true },
                        titleAccessibilityIdentifier: "ParentHome_EmptyStateText",
                        actionButtonAccessibilityIdentifier: "ParentHome_CreateTestButton")
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
                    TestCardView(test: test) {
                        selectedTest = test
                    } onDelete: {
                        deleteTest(test)
                    }
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

struct TestCardView: View {
    let test: SpellingTest
    let onEdit: () -> Void
    let onDelete: () -> Void

    /// Uses cached DateFormatter for better performance
    private var lastPracticedText: String {
        if let lastDate = test.lastPracticed {
            lastDate.mediumFormatted
        } else {
            "Never"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(test.name)
                    .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    .foregroundColor(.primary)
                    .accessibilityIdentifier("TestCard_Name_\(test.name)")

                Text("\((test.words ?? []).count) words")
                    .font(.system(size: AppConstants.captionSize))
                    .foregroundColor(.secondary)

                Text("Last practiced: \(lastPracticedText)")
                    .font(.system(size: AppConstants.captionSize))
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 18))
                        .foregroundColor(AppConstants.primaryColor)
                }
                .frame(width: AppConstants.minimumTouchTarget, height: AppConstants.minimumTouchTarget)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(AppConstants.errorColor)
                }
                .frame(width: AppConstants.minimumTouchTarget, height: AppConstants.minimumTouchTarget)
            }
        }
        .padding(AppConstants.padding)
        .cardStyle()
        .accessibilityIdentifier("TestCard_\(test.name)")
    }
}
