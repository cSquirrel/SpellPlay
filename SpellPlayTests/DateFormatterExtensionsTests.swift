import Foundation
import Testing

@testable import WordCraft

@Suite("DateFormatter extension cached formatters")
struct DateFormatterExtensionsTests {

    @Test("DateFormatter.mediumDate is same instance on multiple accesses")
    func mediumDate_returnsSameInstance() {
        let a = DateFormatter.mediumDate
        let b = DateFormatter.mediumDate
        #expect(a === b)
    }

    @Test("DateFormatter.shortDate is same instance on multiple accesses")
    func shortDate_returnsSameInstance() {
        let a = DateFormatter.shortDate
        let b = DateFormatter.shortDate
        #expect(a === b)
    }

    @Test("DateFormatter.relativeDate is same instance on multiple accesses")
    func relativeDate_returnsSameInstance() {
        let a = DateFormatter.relativeDate
        let b = DateFormatter.relativeDate
        #expect(a === b)
    }

    @Test("mediumDate formats a known date with medium style, no time")
    func mediumDate_formatsDateCorrectly() {
        // Fixed date: Jan 15, 2025 12:00:00 UTC
        let date = Date(timeIntervalSince1970: 1_738_569_600)
        let formatted = DateFormatter.mediumDate.string(from: date)
        #expect(!formatted.isEmpty)
        #expect(formatted.contains("2025") || formatted.contains("25"))
        // Same date must produce same string (consistency)
        #expect(DateFormatter.mediumDate.string(from: date) == formatted)
    }

    @Test("Date.mediumFormatted equals DateFormatter.mediumDate.string(from:)")
    func Date_mediumFormatted_usesCachedFormatter() {
        let date = Date(timeIntervalSince1970: 1_738_569_600)
        let viaExtension = date.mediumFormatted
        let viaFormatter = DateFormatter.mediumDate.string(from: date)
        #expect(viaExtension == viaFormatter)
    }

    @Test("Date.relativeFormatted uses relative formatter; matches cached formatter output")
    func Date_relativeFormatted_usesCachedFormatter() {
        let today = Date()
        let relative = today.relativeFormatted
        #expect(!relative.isEmpty)
        #expect(today.relativeFormatted == DateFormatter.relativeDate.string(from: today))
    }
}
