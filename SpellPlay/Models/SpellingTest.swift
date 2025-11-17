//
//  SpellingTest.swift
//  SpellPlay
//
//  Created on [Date]
//

import Foundation
import SwiftData

extension SpellPlaySchemaV1_0_0 {
    @Model
    final class SpellingTest {
        @Attribute(.unique) var id: UUID
        var name: String
        var createdAt: Date
        var lastPracticed: Date?
        
        @Relationship(deleteRule: .cascade)
        var words: [Word] = []
        
        init(name: String) {
            self.id = UUID()
            self.name = name
            self.createdAt = Date()
            self.lastPracticed = nil
        }
    }
}

