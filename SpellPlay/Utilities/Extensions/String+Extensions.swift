//
//  String+Extensions.swift
//  WordCraft
//
//  Created on [Date]
//

import Foundation

extension String {
    /// Normalizes a string for comparison (lowercase, trimmed)
    func normalized() -> String {
        return self.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Checks if two strings match (case-insensitive, trimmed)
    func matches(_ other: String) -> Bool {
        return self.normalized() == other.normalized()
    }
    
    /// Splits a string into words, filtering out empty strings
    /// Handles commas, whitespaces, and newlines as separators
    func splitIntoWords() -> [String] {
        // First split by commas, then by whitespaces/newlines
        let commaSeparated = self.components(separatedBy: ",")
        var words: [String] = []
        
        for part in commaSeparated {
            let whitespaceSeparated = part.components(separatedBy: .whitespacesAndNewlines)
            for word in whitespaceSeparated {
                let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    words.append(trimmed)
                }
            }
        }
        
        return words
    }
}

