//
//  AirportSearchService.swift
//  FlightApp
//
//  Created by Kush Shah on 11/2/25.
//

import Foundation
import CoreLocation

/// Intelligent airport search service with ranking and context-aware suggestions
class AirportSearchService {
    static let shared = AirportSearchService()

    private var airports: [Airport] = []
    private var popularAirports: Set<String> = [] // IATA codes of major hubs

    // Popular international hubs (curated list, ordered by importance/passenger volume)
    private let majorHubs: Set<String> = [
        // US
        "JFK", "LAX", "ORD", "ATL", "DFW", "DEN", "SFO", "SEA", "MIA", "BOS", "EWR", "IAD",
        // Europe
        "LHR", "CDG", "FRA", "AMS", "MAD", "FCO", "MUC", "ZRH", "VIE", "CPH", "OPO", "LIS", "BCN",
        // Asia
        "HND", "NRT", "ICN", "SIN", "HKG", "PVG", "PEK", "BKK", "KUL", "DEL",
        // Middle East
        "DXB", "DOH", "AUH", "CAI",
        // Oceania
        "SYD", "MEL", "AKL",
        // Latin America
        "GRU", "MEX", "EZE", "BOG",
        // Canada
        "YYZ", "YVR", "YUL"
    ]

    // Manual airport data for important airports with incomplete database entries
    private let manualAirportData: [String: (name: String, city: String, country: String, countryCode: String)] = [
        "OPO": (name: "Francisco Sá Carneiro Airport", city: "Porto", country: "Portugal", countryCode: "PT"),
        // Add more as needed
    ]

    // Hub importance ranking (higher = more important)
    private let hubRanking: [String: Int] = [
        // Tier 1: Global mega-hubs
        "ATL": 100, "DXB": 99, "LHR": 98, "HND": 97, "LAX": 96,
        "ORD": 95, "CDG": 94, "DFW": 93, "JFK": 92, "SIN": 91,

        // Tier 2: Major international hubs
        "AMS": 85, "FRA": 84, "ICN": 83, "SFO": 82, "DEN": 81,
        "HKG": 80, "NRT": 79, "MAD": 78, "PEK": 77, "DOH": 76,

        // Tier 3: Important hubs
        "SYD": 70, "BKK": 69, "FCO": 68, "MIA": 67, "SEA": 66,
        "EWR": 65, "IAD": 64, "MUC": 63, "ZRH": 62, "YYZ": 61,

        // Tier 4: Regional hubs
        "BOS": 55, "PVG": 54, "GRU": 53, "MEX": 52, "MEL": 51,
        "CPH": 50, "VIE": 49, "AUH": 48, "KUL": 47, "DEL": 46,
        "AKL": 45, "EZE": 44, "BOG": 43, "YVR": 42, "YUL": 41,
        "CAI": 40
    ]

    // Popular routes (origin -> destinations)
    private var popularRoutes: [String: [String]] = [:]

    private init() {
        loadAirportDatabase()
        buildPopularRoutes()
    }

    // MARK: - Database Loading

    private func loadAirportDatabase() {
        // Try multiple paths
        var url = Bundle.main.url(forResource: "airports", withExtension: "json", subdirectory: "Resources")

        if url == nil {
            url = Bundle.main.url(forResource: "airports", withExtension: "json")
        }

        guard let url = url else {
            print("⚠️ Could not find airports.json in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let airportData = try JSONDecoder().decode([AirportDataExtended].self, from: data)

            // Convert to Airport models
            airports = airportData.compactMap { data -> Airport? in
                // Must have at least IATA or ICAO
                guard let code = (data.iata ?? data.icao)?.uppercased() else {
                    return nil
                }
                
                // Only include active airports with valid coordinates
                guard data.status == 1,
                      let latString = data.lat,
                      let lonString = data.lon,
                      let latitude = Double(latString),
                      let longitude = Double(lonString),
                      let iso = data.iso else {
                    return nil
                }
                
                // Check if we have manual data for this airport
                let manualData = manualAirportData[code]
                
                // Get airport name - use manual data if available, otherwise from JSON
                let airportName: String
                if let manual = manualData {
                    airportName = manual.name
                } else if let name = data.name, !name.isEmpty {
                    airportName = name
                } else {
                    // Skip airports without name and no manual data
                    return nil
                }

                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let iataCode = data.iata?.uppercased()
                let isPopular = (iataCode != nil && majorHubs.contains(iataCode!)) || data.size == "large"

                // Extract city from name if not provided
                let cityName: String
                if let manual = manualData {
                    // Use manual city name
                    cityName = manual.city
                } else if let city = data.city, !city.isEmpty {
                    cityName = city
                } else {
                    // Try to extract city from airport name
                    cityName = extractCityFromAirportName(airportName)
                }
                
                // Get country - use manual data if available
                let countryName = manualData?.country ?? data.country ?? ""

                return Airport(
                    id: code,
                    iata: data.iata?.uppercased(),
                    icao: data.icao?.uppercased(),
                    name: airportName,
                    city: cityName,
                    country: countryName,
                    countryCode: iso.uppercased(),
                    coordinate: coordinate,
                    timezone: data.timezone,
                    isPopular: isPopular
                )
            }

            // Build popular airports set
            popularAirports = Set(airports.filter { $0.isPopular }.map { $0.displayCode })

            print("✅ Loaded \(airports.count) airports (\(popularAirports.count) major hubs)")
        } catch {
            print("❌ Failed to load airports database: \(error)")
        }
    }

    private func buildPopularRoutes() {
        // Curated popular routes (can be expanded or loaded from API later)
        popularRoutes = [
            "JFK": ["LHR", "CDG", "FCO", "MAD", "AMS", "FRA", "LAX", "SFO", "MIA", "DXB"],
            "LAX": ["NRT", "ICN", "SYD", "LHR", "JFK", "SFO", "HNL", "PVG", "HKG"],
            "LHR": ["JFK", "DXB", "SIN", "HKG", "LAX", "CDG", "FRA", "AMS", "MAD"],
            "SFO": ["LAX", "JFK", "NRT", "ICN", "LHR", "CDG", "HKG", "SYD"],
            "ORD": ["LHR", "FRA", "NRT", "LAX", "SFO", "JFK", "DFW"],
            "DXB": ["LHR", "SIN", "HKG", "JFK", "SYD", "BKK", "KUL"],
            "SIN": ["LHR", "SYD", "HKG", "BKK", "NRT", "DXB"],
            "HKG": ["SIN", "NRT", "SYD", "LHR", "LAX", "SFO"],
        ]
    }

    // MARK: - Search Methods

    /// Search airports with intelligent ranking
    /// - Parameters:
    ///   - query: Search query (IATA, ICAO, city, or airport name)
    ///   - limit: Maximum results to return
    ///   - userLocation: Optional user location for distance-based ranking
    /// - Returns: Ranked list of matching airports
    func search(query: String, limit: Int = 8, userLocation: CLLocationCoordinate2D? = nil) -> [Airport] {
        let normalizedQuery = query.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedQuery.isEmpty else {
            return getDefaultSuggestions(userLocation: userLocation, limit: limit)
        }

        // Score and rank airports
        let scoredAirports = airports.compactMap { airport -> (airport: Airport, score: Double)? in
            guard let score = calculateMatchScore(airport: airport, query: normalizedQuery, userLocation: userLocation) else {
                return nil
            }
            return (airport, score)
        }

        // Sort by score (descending) and take top results
        return scoredAirports
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0.airport }
    }

    /// Get default suggestions when no query
    private func getDefaultSuggestions(userLocation: CLLocationCoordinate2D?, limit: Int) -> [Airport] {
        var suggestions: [Airport] = []

        // If we have user location, show nearby major airports
        if let location = userLocation {
            let nearby = airports
                .filter { $0.isPopular } // Only major hubs
                .sorted { $0.distance(from: location) < $1.distance(from: location) }
                .prefix(3)
            suggestions.append(contentsOf: nearby)
        }

        // Add popular hubs if we need more, sorted by importance
        if suggestions.count < limit {
            let popular = airports
                .filter { $0.isPopular && !suggestions.contains($0) }
                .sorted { airport1, airport2 in
                    let rank1 = hubRanking[airport1.displayCode] ?? 0
                    let rank2 = hubRanking[airport2.displayCode] ?? 0
                    return rank1 > rank2 // Higher rank first
                }
                .prefix(limit - suggestions.count)
            suggestions.append(contentsOf: popular)
        }

        return Array(suggestions.prefix(limit))
    }

    /// Get popular destinations from an origin airport
    func getPopularDestinations(from origin: String, limit: Int = 8) -> [Airport] {
        let originCode = origin.uppercased()

        // Check our curated popular routes first
        if let destinations = popularRoutes[originCode] {
            return destinations.compactMap { code in
                airports.first { $0.displayCode == code }
            }.prefix(limit).map { $0 }
        }

        // Fallback: return other popular airports
        return airports
            .filter { $0.isPopular && $0.displayCode != originCode }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Scoring Algorithm

    private func calculateMatchScore(airport: Airport, query: String, userLocation: CLLocationCoordinate2D?) -> Double? {
        var score: Double = 0

        // 1. Exact IATA/ICAO match (highest priority)
        if airport.iata == query || airport.icao == query {
            score += 1000
        }

        // 2. IATA/ICAO starts with query
        else if airport.iata?.hasPrefix(query) == true || airport.icao?.hasPrefix(query) == true {
            score += 500
        }

        // 3. City name starts with query
        else if airport.city.uppercased().hasPrefix(query) {
            score += 300
        }

        // 4. Airport name starts with query
        else if airport.name.uppercased().hasPrefix(query) {
            score += 200
        }

        // 5. City name contains query
        else if airport.city.uppercased().contains(query) {
            score += 100
        }

        // 6. Airport name contains query
        else if airport.name.uppercased().contains(query) {
            score += 50
        }

        // No match at all
        else {
            return nil
        }

        // Boost popular airports
        if airport.isPopular {
            score += 100
        }

        // Boost by proximity if user location available
        if let location = userLocation {
            let distance = airport.distance(from: location)
            // Inverse distance bonus (closer = higher score)
            // Max bonus of 50 points for very close airports
            let proximityBonus = max(0, 50 - (distance / 100))
            score += proximityBonus
        }

        return score
    }

    // MARK: - Utility Methods

    /// Extract city name from airport name
    private func extractCityFromAirportName(_ airportName: String) -> String {
        // Common patterns:
        // "Los Angeles International Airport" -> "Los Angeles"
        // "John F Kennedy International Airport" -> "John F Kennedy"
        // "London Heathrow Airport" -> "London"

        let patterns = [
            " International Airport",
            " Airport",
            " Intl",
            " Regional",
            " Municipal"
        ]

        var cityName = airportName
        for pattern in patterns {
            if let range = cityName.range(of: pattern, options: .caseInsensitive) {
                cityName = String(cityName[..<range.lowerBound])
                break
            }
        }

        return cityName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Get airport by code (IATA or ICAO)
    func getAirport(byCode code: String) -> Airport? {
        let normalizedCode = code.uppercased()
        return airports.first { $0.iata == normalizedCode || $0.icao == normalizedCode }
    }

    /// Get all airports (for debug purposes)
    func getAllAirports() -> [Airport] {
        return airports
    }

    /// Get count of loaded airports
    var airportCount: Int {
        airports.count
    }
}
