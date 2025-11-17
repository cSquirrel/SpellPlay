//
//  ParentHomeView.swift
//  SpellPlay
//
//  Created on [Date]
//

import SwiftUI
import SwiftData

struct ParentHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SpellingTest.createdAt, order: .reverse) private var tests: [SpellingTest]
    
    @State private var viewModel = TestListViewModel()
    @State private var showingCreateTest = false
    @State private var selectedTest: SpellingTest?
    @State private var showingRoleSwitcher = false
    
    var body: some View {
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
            .navigationTitle("My Spelling Tests")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingRoleSwitcher = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateTest = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                    }
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
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Tests Yet")
                .font(.system(size: AppConstants.titleSize, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Create your first spelling test to get started")
                .font(.system(size: AppConstants.bodySize))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConstants.padding)
            
            Button(action: {
                showingCreateTest = true
            }) {
                Text("Create Test")
                    .font(.system(size: AppConstants.bodySize, weight: .semibold))
            }
            .largeButtonStyle(color: AppConstants.primaryColor)
            .padding(.horizontal, AppConstants.padding)
        }
    }
    
    private var testListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(tests) { test in
                    TestCardView(test: test) {
                        selectedTest = test
                    } onDelete: {
                        viewModel.deleteTest(test)
                    }
                }
            }
            .padding(AppConstants.padding)
        }
    }
}

struct TestCardView: View {
    let test: SpellingTest
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var lastPracticedText: String {
        if let lastDate = test.lastPracticed {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: lastDate)
        } else {
            return "Never"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(test.name)
                    .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("\(test.words.count) words")
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
    }
}

