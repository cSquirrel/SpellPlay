import Foundation
import SwiftData

@MainActor
class StreakService {
    private let modelContext: ModelContext
    var onError: ((String) -> Void)?

    init(modelContext: ModelContext, onError: ((String) -> Void)? = nil) {
        self.modelContext = modelContext
        self.onError = onError
    }

    func getCurrentStreak() -> Int {
        let descriptor = FetchDescriptor<PracticeSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard
            let sessions = try? modelContext.fetch(descriptor),
            !sessions.isEmpty
        else {
            return 0
        }

        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        // Check if there's a session today
        let today = calendar.startOfDay(for: Date())
        let hasToday = sessions.contains { session in
            calendar.isDate(session.date, inSameDayAs: today)
        }

        if !hasToday {
            // If no session today, check if there was one yesterday
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            let hasYesterday = sessions.contains { session in
                calendar.isDate(session.date, inSameDayAs: yesterday)
            }
            if !hasYesterday {
                return 0
            }
            currentDate = yesterday
        }

        // Count consecutive days
        for session in sessions {
            let sessionDate = calendar.startOfDay(for: session.date)

            if calendar.isDate(sessionDate, inSameDayAs: currentDate) {
                streak += 1
                if let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                    currentDate = previousDate
                } else {
                    break
                }
            } else if sessionDate < currentDate {
                // Gap detected, streak is broken
                break
            }
        }

        return streak
    }

    func updateStreak(for testId: UUID, wordsAttempted: Int, wordsCorrect: Int) -> Int {
        let newStreak = calculateNewStreak()

        let session = PracticeSession(
            testId: testId,
            wordsAttempted: wordsAttempted,
            wordsCorrect: wordsCorrect,
            streak: newStreak)

        modelContext.insert(session)

        do {
            try modelContext.save()
        } catch {
            let errorMessage = "Unable to save practice session. Your progress may not be recorded."
            onError?(errorMessage)
        }

        return newStreak
    }

    private func calculateNewStreak() -> Int {
        let currentStreak = getCurrentStreak()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<PracticeSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let lastSession = try? modelContext.fetch(descriptor).first else {
            return 1 // First practice session
        }

        let lastSessionDate = calendar.startOfDay(for: lastSession.date)

        if calendar.isDate(lastSessionDate, inSameDayAs: today) {
            // Already practiced today, maintain streak
            return currentStreak
        } else if
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
            calendar.isDate(lastSessionDate, inSameDayAs: yesterday)
        {
            // Practiced yesterday, increment streak
            return currentStreak + 1
        } else {
            // Gap detected, reset to 1
            return 1
        }
    }
}
