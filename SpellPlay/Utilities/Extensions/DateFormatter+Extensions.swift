import Foundation

// MARK: - Cached DateFormatters (main-thread only)

// Cached formatters use the system locale (Locale.current). Call sites must run on the main thread
// because DateFormatter is not thread-safe. All UI date display (test list, test cards) uses these.

extension DateFormatter {
    /// Cached medium date formatter for displaying dates
    /// Example output: "Jan 15, 2025"
    /// - Note: Main-thread only; use from UI or @MainActor context.
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Cached short date formatter
    /// Example output: "1/15/25"
    /// - Note: Main-thread only; use from UI or @MainActor context.
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    /// Cached relative date formatter for "Today", "Yesterday", etc.
    /// - Note: Main-thread only; use from UI or @MainActor context.
    static let relativeDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
}

extension Date {
    /// Format date using cached medium formatter
    var mediumFormatted: String {
        DateFormatter.mediumDate.string(from: self)
    }

    /// Format date using cached short formatter
    var shortFormatted: String {
        DateFormatter.shortDate.string(from: self)
    }

    /// Format date using relative formatter ("Today", "Yesterday", etc.)
    var relativeFormatted: String {
        DateFormatter.relativeDate.string(from: self)
    }
}
