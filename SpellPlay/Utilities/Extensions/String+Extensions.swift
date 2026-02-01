import Foundation

extension String {
    /// Normalizes a string for comparison (lowercase, trimmed)
    func normalized() -> String {
        lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Checks if two strings match (case-insensitive, trimmed)
    func matches(_ other: String) -> Bool {
        normalized() == other.normalized()
    }

    /// Splits a string into words, filtering out empty strings
    /// Handles commas, whitespaces, and newlines as separators
    /// Sanitizes words by removing all whitespace and converting to lowercase
    func splitIntoWords() -> [String] {
        // First split by commas, then by whitespaces/newlines
        let commaSeparated = components(separatedBy: ",")
        var words: [String] = []

        for part in commaSeparated {
            let whitespaceSeparated = part.components(separatedBy: .whitespacesAndNewlines)
            for word in whitespaceSeparated {
                // Remove all whitespace characters and convert to lowercase
                let sanitized = word
                    .filter { !$0.isWhitespace && !$0.isNewline }
                    .lowercased()

                if !sanitized.isEmpty {
                    words.append(sanitized)
                }
            }
        }

        return words
    }

    /// Calculates the Damerau-Levenshtein distance between two strings
    /// This includes insertions, deletions, substitutions, and transpositions (swapped adjacent characters)
    private func damerauLevenshteinDistance(to other: String) -> Int {
        let source = Array(self)
        let target = Array(other)
        let sourceCount = source.count
        let targetCount = target.count

        // Handle edge cases
        if sourceCount == 0 { return targetCount }
        if targetCount == 0 { return sourceCount }
        if source == target { return 0 }

        // Create distance matrix
        var matrix = Array(repeating: Array(repeating: 0, count: targetCount + 1), count: sourceCount + 1)

        // Initialize first row and column
        for i in 0 ... sourceCount {
            matrix[i][0] = i
        }
        for j in 0 ... targetCount {
            matrix[0][j] = j
        }

        // Fill the matrix
        for i in 1 ... sourceCount {
            for j in 1 ... targetCount {
                let cost = source[i - 1] == target[j - 1] ? 0 : 1

                // Standard operations: insertion, deletion, substitution
                matrix[i][j] = Swift.min(
                    matrix[i - 1][j] + 1, // deletion
                    matrix[i][j - 1] + 1, // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )

                // Transposition (Damerau extension)
                if i > 1, j > 1, source[i - 1] == target[j - 2], source[i - 2] == target[j - 1] {
                    matrix[i][j] = Swift.min(matrix[i][j], matrix[i - 2][j - 2] + 1)
                }
            }
        }

        return matrix[sourceCount][targetCount]
    }

    /// Calculates similarity percentage between this string and another string
    /// Returns a value between 0.0 (completely different) and 1.0 (identical)
    /// Uses Damerau-Levenshtein distance which handles transpositions, insertions, deletions, and substitutions
    func similarityPercentage(to other: String) -> Double {
        let normalizedSelf = normalized()
        let normalizedOther = other.normalized()

        // Handle edge cases
        if normalizedSelf.isEmpty && normalizedOther.isEmpty {
            return 1.0
        }
        if normalizedSelf.isEmpty || normalizedOther.isEmpty {
            return 0.0
        }
        if normalizedSelf == normalizedOther {
            return 1.0
        }

        // Calculate Damerau-Levenshtein distance
        let distance = normalizedSelf.damerauLevenshteinDistance(to: normalizedOther)
        let maxLength = Swift.max(normalizedSelf.count, normalizedOther.count)

        // Calculate similarity: 1 - (distance / maxLength)
        // Clamp to ensure result is between 0.0 and 1.0
        let similarity = 1.0 - (Double(distance) / Double(maxLength))
        return Swift.max(0.0, Swift.min(1.0, similarity))
    }
}
