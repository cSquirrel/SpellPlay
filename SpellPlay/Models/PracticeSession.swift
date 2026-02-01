import Foundation
import SwiftData

extension WordCraftSchemaV1_0_0 {
    @Model
    final class PracticeSession {
        // CloudKit doesn't support unique constraints - removed @Attribute(.unique)
        var id: UUID = UUID()
        var testId: UUID = UUID()
        var date: Date = Date()
        var wordsAttempted: Int = 0
        var wordsCorrect: Int = 0
        var streak: Int = 0

        init(testId: UUID, wordsAttempted: Int, wordsCorrect: Int, streak: Int) {
            id = UUID()
            self.testId = testId
            date = Date()
            self.wordsAttempted = wordsAttempted
            self.wordsCorrect = wordsCorrect
            self.streak = streak
        }
    }
}
