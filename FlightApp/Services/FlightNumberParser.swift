//
//  FlightNumberParser.swift
//  FlightApp
//
//  Created by Kush Shah on 11/2/25.
//

import Foundation

/// Helper service to parse flight numbers and extract airline codes
class FlightNumberParser {
    static let shared = FlightNumberParser()

    private init() {}

    /// Parse a flight number and extract airline code and flight number
    /// - Parameter flightNumber: Flight number string (e.g., "AA1", "UA60", "BA175", "B61234", "F9102")
    /// - Returns: Tuple of (airlineCode, flightNumber) or nil if invalid
    func parseFlightNumber(_ input: String) -> (airlineCode: String, flightNumber: String)? {
        let cleaned = input.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Flight number pattern: 2-3 character airline code (letters/numbers) + optional space + 1-4 digit flight number
        // Examples: AA1, B6123, F9102, UA60, DL1234
        // Airline code can be alphanumeric (B6, F9, etc.) but flight number is always numeric
        // Use non-greedy matching for airline code to prefer 2 characters when possible
        let pattern = "^([A-Z0-9]{2,3}?)\\s?([0-9]{1,4})$"

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)) else {
            return nil
        }

        // Extract airline code (group 1)
        guard let airlineCodeRange = Range(match.range(at: 1), in: cleaned) else {
            return nil
        }
        let airlineCode = String(cleaned[airlineCodeRange])

        // Extract flight number (group 2)
        guard let flightNumRange = Range(match.range(at: 2), in: cleaned) else {
            return nil
        }
        let flightNum = String(cleaned[flightNumRange])

        // Validate that airline code has at least one letter (not all numbers)
        guard airlineCode.contains(where: { $0.isLetter }) else {
            return nil
        }

        return (airlineCode, flightNum)
    }

    /// Get full flight number string without spaces
    /// - Parameter flightNumber: Flight number string
    /// - Returns: Normalized flight number (e.g., "AA1", "UA60")
    func normalizeFlightNumber(_ input: String) -> String? {
        guard let parsed = parseFlightNumber(input) else {
            return nil
        }
        return "\(parsed.airlineCode)\(parsed.flightNumber)"
    }

    /// Check if a string is a valid flight number
    func isValidFlightNumber(_ input: String) -> Bool {
        return parseFlightNumber(input) != nil
    }
}
