//
//  PracticeSession.swift
//  WordCraft
//
//  Created on [Date]
//

import Foundation
import SwiftData

extension WordCraftSchemaV1_0_0 {
    @Model
    final class PracticeSession {
        @Attribute(.unique) var id: UUID
        var testId: UUID
        var date: Date
        var wordsAttempted: Int
        var wordsCorrect: Int
        var streak: Int
        
        init(testId: UUID, wordsAttempted: Int, wordsCorrect: Int, streak: Int) {
            self.id = UUID()
            self.testId = testId
            self.date = Date()
            self.wordsAttempted = wordsAttempted
            self.wordsCorrect = wordsCorrect
            self.streak = streak
        }
    }
}
