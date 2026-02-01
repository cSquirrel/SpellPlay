import Foundation
import SwiftData

extension WordCraftSchemaV1_0_0 {
    @Model
    final class SpellingTest {
        // CloudKit doesn't support unique constraints - removed @Attribute(.unique)
        var id: UUID = UUID()
        var name: String = ""
        var createdAt: Date = Date()
        var lastPracticed: Date?
        var helpCoins: Int = 3

        /// CloudKit requires relationships to be optional
        @Relationship(deleteRule: .cascade)
        var words: [Word]? = []

        init(name: String, helpCoins: Int = 3) {
            id = UUID()
            self.name = name
            createdAt = Date()
            lastPracticed = nil
            self.helpCoins = helpCoins
            words = []
        }
    }
}
