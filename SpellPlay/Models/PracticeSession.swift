//
//  PracticeSession.swift
//  SpellPlay
//
//  Created on [Date]
//

import Foundation
import SwiftData

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

