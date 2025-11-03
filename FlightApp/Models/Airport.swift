//
//  Airport.swift
//  FlightApp
//
//  Created by Kush Shah on 11/2/25.
//

import Foundation
import CoreLocation

/// Rich airport model with metadata for search and display
struct Airport: Identifiable, Hashable {
    let id: String // ICAO or IATA
    let iata: String?
    let icao: String?
    let name: String
    let city: String
    let country: String
    let countryCode: String // ISO 2-letter code for flag emoji
    let coordinate: CLLocationCoordinate2D
    let timezone: String? // e.g., "America/New_York"
    let isPopular: Bool // Major international hub

    /// Primary display code (prefer IATA over ICAO)
    var displayCode: String {
        iata ?? icao ?? id
    }

    /// Normalized city name for display (handles common variations)
    var displayCity: String {
        // Common city name variations that should be normalized
        let cityMapping: [String: String] = [
            "Oporto": "Porto",
            "München": "Munich",
            "Wien": "Vienna",
            "København": "Copenhagen",
            "Zürich": "Zurich",
            "Moskva": "Moscow",
            "Lisboa": "Lisbon",
            "Warszawa": "Warsaw",
            "Praha": "Prague",
            "Athina": "Athens",
            "Roma": "Rome",
            "Milano": "Milan",
            "Venezia": "Venice",
            "Firenze": "Florence",
            "Napoli": "Naples"
        ]
        
        return cityMapping[city] ?? city
    }

    /// Full display name with code
    var displayName: String {
        "\(displayCity) (\(displayCode))"
    }

    /// Detailed display name including airport name
    var detailedDisplayName: String {
        "\(displayCity) (\(displayCode)) - \(name)"
    }

    /// Country flag emoji
    var flagEmoji: String {
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let unicodeScalar = UnicodeScalar(base + scalar.value) {
                emoji.append(String(unicodeScalar))
            }
        }
        return emoji
    }

    /// Calculate distance from a coordinate (in miles)
    func distance(from coordinate: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location2.distance(from: location1) / 1609.34 // meters to miles
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Airport, rhs: Airport) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Extended Airport Data

/// Airport data from JSON (matches actual airports.json structure)
struct AirportDataExtended: Codable {
    let iata: String?
    let icao: String?
    let name: String?
    let city: String?
    let country: String?
    let iso: String? // ISO country code (e.g., "US")
    let lat: String?
    let lon: String?
    let timezone: String?
    let status: Int?
    let continent: String? // e.g., "NA", "EU"
    let type: String? // e.g., "airport", "heliport"
    let size: String? // e.g., "large", "medium", "small"

    enum CodingKeys: String, CodingKey {
        case iata, icao, name, city, country, lat, lon, timezone, status, continent, type, size, iso
    }
}
