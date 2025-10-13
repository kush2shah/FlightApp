//
//  RecentSearchStore.swift
//  FlightApp
//
//  Created by Kush Shah on 2/12/25.
//

import SwiftUI

/// Rich flight data stored with recent searches
struct RecentFlightData: Codable, Hashable {
    let flightNumber: String
    let airlineIATA: String?
    let airlineName: String?
    let originCode: String
    let originCity: String?
    let destinationCode: String
    let destinationCity: String?
    let scheduledDeparture: Date?
    let scheduledArrival: Date?
    let status: String?        // "scheduled", "active", "landed", "cancelled"
    let progress: Double?      // 0.0 - 1.0
    let lastUpdated: Date

    /// Create from AeroFlight
    static func from(flight: AeroFlight) -> RecentFlightData {
        return RecentFlightData(
            flightNumber: flight.ident,
            airlineIATA: flight.operatorIata,
            airlineName: nil,  // Will be fetched asynchronously
            originCode: flight.origin.codeIata ?? flight.origin.codeIcao ?? "",
            originCity: flight.origin.city,
            destinationCode: flight.destination.codeIata ?? flight.destination.codeIcao ?? "",
            destinationCity: flight.destination.city,
            scheduledDeparture: flight.scheduledOut.flatMap { ISO8601DateFormatter().date(from: $0) },
            scheduledArrival: flight.scheduledIn.flatMap { ISO8601DateFormatter().date(from: $0) },
            status: flight.status,
            progress: flight.progressPercent.flatMap { Double($0) / 100.0 },
            lastUpdated: Date()
        )
    }

    /// Create from AeroFlight with airline name fetched from API
    static func from(flight: AeroFlight, airlineName: String?) -> RecentFlightData {
        return RecentFlightData(
            flightNumber: flight.ident,
            airlineIATA: flight.operatorIata,
            airlineName: airlineName,
            originCode: flight.origin.codeIata ?? flight.origin.codeIcao ?? "",
            originCity: flight.origin.city,
            destinationCode: flight.destination.codeIata ?? flight.destination.codeIcao ?? "",
            destinationCity: flight.destination.city,
            scheduledDeparture: flight.scheduledOut.flatMap { ISO8601DateFormatter().date(from: $0) },
            scheduledArrival: flight.scheduledIn.flatMap { ISO8601DateFormatter().date(from: $0) },
            status: flight.status,
            progress: flight.progressPercent.flatMap { Double($0) / 100.0 },
            lastUpdated: Date()
        )
    }
}

struct RecentSearch: Identifiable, Codable, Hashable {
    let id: UUID
    let route: String
    let timestamp: Date
    let searchType: SearchKind
    let flightData: RecentFlightData?  // Rich flight details

    // Parsed details for rich display
    var displayInfo: SearchDisplayInfo {
        SearchDisplayInfo.parse(from: route, type: searchType)
    }

    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var lastUpdatedString: String {
        guard let data = flightData else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: data.lastUpdated, relativeTo: Date())
    }

    init(route: String, searchType: SearchKind = .unknown, flightData: RecentFlightData? = nil) {
        self.id = UUID()
        self.route = route
        self.timestamp = Date()
        self.searchType = searchType
        self.flightData = flightData
    }
}

enum SearchKind: String, Codable {
    case flightNumber
    case route
    case unknown
}

struct SearchDisplayInfo {
    let icon: String
    let title: String
    let subtitle: String?
    let origin: String?
    let destination: String?
    let originFlag: String?
    let destinationFlag: String?

    static func parse(from text: String, type: SearchKind) -> SearchDisplayInfo {
        let cleaned = text.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        switch type {
        case .flightNumber:
            return SearchDisplayInfo(
                icon: "airplane",
                title: cleaned,
                subtitle: "Flight",
                origin: nil,
                destination: nil,
                originFlag: nil,
                destinationFlag: nil
            )
        case .route:
            // Try to parse as route
            let components = cleaned.components(separatedBy: " ").filter { !$0.isEmpty }
            if components.count >= 2 {
                return SearchDisplayInfo(
                    icon: "arrow.right",
                    title: "\(components[0]) → \(components[1])",
                    subtitle: "Route",
                    origin: components[0],
                    destination: components[1],
                    originFlag: getFlag(for: components[0]),
                    destinationFlag: getFlag(for: components[1])
                )
            }
            fallthrough
        case .unknown:
            return SearchDisplayInfo(
                icon: "clock",
                title: cleaned,
                subtitle: nil,
                origin: nil,
                destination: nil,
                originFlag: nil,
                destinationFlag: nil
            )
        }
    }

    private static func getFlag(for airportCode: String) -> String? {
        // Basic flag mapping for common airports
        let flagMap: [String: String] = [
            "JFK": "🇺🇸", "LAX": "🇺🇸", "SFO": "🇺🇸", "ORD": "🇺🇸", "ATL": "🇺🇸",
            "LHR": "🇬🇧", "LGW": "🇬🇧", "MAN": "🇬🇧",
            "CDG": "🇫🇷", "ORY": "🇫🇷",
            "FRA": "🇩🇪", "MUC": "🇩🇪",
            "AMS": "🇳🇱",
            "DXB": "🇦🇪",
            "SIN": "🇸🇬",
            "HND": "🇯🇵", "NRT": "🇯🇵",
            "ICN": "🇰🇷",
            "PVG": "🇨🇳", "PEK": "🇨🇳",
            "SYD": "🇦🇺", "MEL": "🇦🇺",
            "YYZ": "🇨🇦", "YVR": "🇨🇦"
        ]
        return flagMap[airportCode]
    }
}

class RecentSearchStore: ObservableObject {
    @Published var recentSearches: [RecentSearch] = []
    private let defaults = UserDefaults.standard
    private let recentSearchKey = "RecentFlightSearches"
    
    init() {
        loadRecentSearches()
    }
    
    func addSearch(_ route: String, type: SearchKind = .unknown, flightData: RecentFlightData? = nil) {
        print("🟢 Adding search: \(route), has flight data: \(flightData != nil)")
        if let data = flightData {
            print("🟢 Flight data details - airline: \(data.airlineIATA ?? "nil"), origin: \(data.originCode), dest: \(data.destinationCode)")
        }

        // Prevent duplicate recent searches - but update if flight data is provided
        if let existingIndex = recentSearches.firstIndex(where: { $0.route.lowercased() == route.lowercased() }) {
            // Remove old entry to replace with updated one
            recentSearches.remove(at: existingIndex)
        }

        let newSearch = RecentSearch(route: route, searchType: type, flightData: flightData)
        recentSearches.insert(newSearch, at: 0)

        // Limit to last 10 searches
        if recentSearches.count > 10 {
            recentSearches.removeLast()
        }

        saveRecentSearches()
    }
    
    private func saveRecentSearches() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(recentSearches) {
            defaults.set(encoded, forKey: recentSearchKey)
        }
    }
    
    private func loadRecentSearches() {
        guard let savedSearches = defaults.object(forKey: recentSearchKey) as? Data else {
            return
        }
        
        let decoder = JSONDecoder()
        if let loadedSearches = try? decoder.decode([RecentSearch].self, from: savedSearches) {
            recentSearches = loadedSearches
        }
    }
    
    func removeSearch(_ search: RecentSearch) {
        recentSearches.removeAll { $0.id == search.id }
        saveRecentSearches()
    }
}
