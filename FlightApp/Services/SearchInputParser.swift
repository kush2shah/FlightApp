//
//  SearchInputParser.swift
//  FlightApp
//
//  Created by Kush Shah on 10/7/25.
//

import Foundation

enum SearchType {
    case flightNumber(String)
    case route(origin: String, destination: String)
    case invalid
}

class SearchInputParser {
    static let shared = SearchInputParser()

    private init() {}

    /// Parse user input to determine search type
    /// - Parameter input: Raw user input string
    /// - Returns: SearchType indicating flight number, route, or invalid
    func parse(_ input: String) -> SearchType {
        let cleaned = input.uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ") // Normalize multiple spaces

        // Empty input
        guard !cleaned.isEmpty else {
            return .invalid
        }

        // Try to parse as route (two airport codes)
        if let route = parseRoute(cleaned) {
            return .route(origin: route.origin, destination: route.destination)
        }

        // Try to parse as flight number
        if isValidFlightNumber(cleaned) {
            return .flightNumber(cleaned)
        }

        return .invalid
    }

    /// Attempt to parse as route (origin → destination)
    private func parseRoute(_ input: String) -> (origin: String, destination: String)? {
        // Common separators: space, dash, arrow, comma
        let separatorPatterns = [
            "→", "->", "—", "–", "-", " ", ","
        ]

        for separator in separatorPatterns {
            if input.contains(separator) {
                let parts = input.components(separatedBy: separator)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                if parts.count == 2 {
                    let origin = normalizeAirportCode(parts[0])
                    let destination = normalizeAirportCode(parts[1])

                    if isValidAirportCode(origin) && isValidAirportCode(destination) {
                        return (origin, destination)
                    }
                }
            }
        }

        // Try parsing as two consecutive codes without separator
        // e.g., "JFKLHR", "SFOLAX"
        if input.count >= 6 && input.count <= 8 {
            let midPoint = input.count / 2
            let origin = String(input.prefix(midPoint))
            let destination = String(input.suffix(input.count - midPoint))

            if isValidAirportCode(origin) && isValidAirportCode(destination) {
                return (origin, destination)
            }
        }

        return nil
    }

    /// Normalize airport code (strip K prefix for US airports if ICAO)
    private func normalizeAirportCode(_ code: String) -> String {
        // If it's a 4-letter code starting with K, it's likely ICAO
        // We prefer IATA for seats.aero, but keep ICAO for AeroAPI
        return code.uppercased()
    }

    /// Validate if string looks like an airport code
    private func isValidAirportCode(_ code: String) -> Bool {
        // Airport codes are typically 3 (IATA) or 4 (ICAO) letters
        let length = code.count
        guard length == 3 || length == 4 else { return false }

        // Must be all letters
        let letters = CharacterSet.letters
        return code.unicodeScalars.allSatisfy { letters.contains($0) }
    }

    /// Validate if string looks like a flight number
    private func isValidFlightNumber(_ input: String) -> Bool {
        // Flight number pattern: 2-3 letter airline code + 1-4 digit number
        // Examples: AA1, UA60, BA175, DL1234
        let pattern = "^[A-Z]{2,3}[0-9]{1,4}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(input.startIndex..., in: input)
        return regex?.firstMatch(in: input, range: range) != nil
    }

    /// Convert ICAO to IATA if possible (for seats.aero compatibility)
    func icaoToIata(_ code: String) -> String {
        // If it's a US airport with K prefix (ICAO), strip to get IATA
        if code.count == 4 && code.hasPrefix("K") {
            let potentialIata = String(code.dropFirst())
            if potentialIata.count == 3 {
                return potentialIata
            }
        }
        return code
    }
}
