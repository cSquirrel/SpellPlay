//
//  Word.swift
//  SpellPlay
//
//  Created on [Date]
//

import Foundation
import SwiftData

@Model
final class Word {
    var id: UUID
    var text: String
    var createdAt: Date
    
    @Relationship(deleteRule: .nullify, inverse: \SpellingTest.words)
    var test: SpellingTest?
    
    init(text: String) {
        self.id = UUID()
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = Date()
    }
}

