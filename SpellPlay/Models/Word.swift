//
//  Word.swift
//  WordCraft
//
//  Created on [Date]
//

import Foundation
import SwiftData

extension WordCraftSchemaV1_0_0 {
    @Model
    final class Word {
        var id: UUID
        var text: String
        var createdAt: Date
        var displayOrder: Int
        
        @Relationship(deleteRule: .nullify, inverse: \SpellingTest.words)
        var test: SpellingTest?
        
        init(text: String, displayOrder: Int = 0) {
            self.id = UUID()
            self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            self.createdAt = Date()
            self.displayOrder = displayOrder
        }
    }
}

// Extension to sort words by their creation order
extension Array where Element == Word {
    /// Sorts words by displayOrder, falling back to createdAt for words without displayOrder
    /// This preserves the order in which words were entered by the parent
    func sortedAsCreated() -> [Word] {
        self.sorted { word1, word2 in
            // If displayOrder is 0 (default for old words), use createdAt as fallback
            if word1.displayOrder == 0 && word2.displayOrder == 0 {
                return word1.createdAt < word2.createdAt
            }
            return word1.displayOrder < word2.displayOrder
        }
    }
}

