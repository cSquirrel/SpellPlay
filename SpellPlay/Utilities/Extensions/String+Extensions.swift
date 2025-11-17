//
//  String+Extensions.swift
//  SpellPlay
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
    func splitIntoWords() -> [String] {
        return self.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

