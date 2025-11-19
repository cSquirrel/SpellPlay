//
//  TestListViewModel.swift
//  WordCraft
//
//  Created on [Date]
//

import Foundation
import SwiftData

@MainActor
@Observable
class TestListViewModel {
    private var modelContext: ModelContext?
    
    var tests: [SpellingTest] = []
    var errorMessage: String?
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadTests()
    }
    
    func loadTests() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<SpellingTest>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            tests = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load tests: \(error.localizedDescription)"
        }
    }
    
    func deleteTest(_ test: SpellingTest) {
        guard let modelContext = modelContext else { return }
        
        modelContext.delete(test)
        
        do {
            try modelContext.save()
            loadTests()
        } catch {
            errorMessage = "Failed to delete test: \(error.localizedDescription)"
        }
    }
    
    func getTestStats(for test: SpellingTest) -> (totalWords: Int, lastPracticed: String) {
        let totalWords = test.words.count
        
        let lastPracticed: String
        if let lastDate = test.lastPracticed {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            lastPracticed = formatter.string(from: lastDate)
        } else {
            lastPracticed = "Never"
        }
        
        return (totalWords, lastPracticed)
    }
}

