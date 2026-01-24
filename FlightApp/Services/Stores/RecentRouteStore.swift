//
//  RecentRouteStore.swift
//  FlightApp
//
//  Manages user's recent route searches with persistence
//

import SwiftUI
import Combine

/// Represents a recent route search (non-time-sensitive)
struct RecentRoute: Codable, Identifiable, Hashable {
    let id: UUID
    let originCode: String
    let destinationCode: String
    let originName: String?
    let destinationName: String?
    let originCity: String?
    let destinationCity: String?
    let lastSearched: Date

    init(
        id: UUID = UUID(),
        originCode: String,
        destinationCode: String,
        originName: String? = nil,
        destinationName: String? = nil,
        originCity: String? = nil,
        destinationCity: String? = nil,
        lastSearched: Date = Date()
    ) {
        self.id = id
        self.originCode = originCode
        self.destinationCode = destinationCode
        self.originName = originName
        self.destinationName = destinationName
        self.originCity = originCity
        self.destinationCity = destinationCity
        self.lastSearched = lastSearched
    }

    /// Create from AeroAirport objects
    static func from(origin: AeroAirport, destination: AeroAirport) -> RecentRoute {
        return RecentRoute(
            originCode: origin.displayCode,
            destinationCode: destination.displayCode,
            originName: origin.name,
            destinationName: destination.name,
            originCity: origin.city,
            destinationCity: destination.city
        )
    }

    /// Display title for the route
    var displayTitle: String {
        return "\(originCode) → \(destinationCode)"
    }

    /// Display subtitle with city names if available
    var displaySubtitle: String? {
        if let originCity = originCity, let destCity = destinationCity {
            return "\(originCity) to \(destCity)"
        }
        return nil
    }
}

class RecentRouteStore: ObservableObject {
    @Published var recentRoutes: [RecentRoute] = []
    private let defaults = UserDefaults.standard
    private let recentRoutesKey = "recentRoutes"

    init() {
        loadRecentRoutes()
    }

    /// Add a route to recent searches (or update if already exists)
    func addRoute(_ route: RecentRoute) {
        print("🟢 Adding route: \(route.originCode) → \(route.destinationCode)")

        // Remove if already exists (to update timestamp and move to top)
        if let existingIndex = recentRoutes.firstIndex(where: {
            $0.originCode == route.originCode && $0.destinationCode == route.destinationCode
        }) {
            recentRoutes.remove(at: existingIndex)
        }

        // Insert at the beginning
        recentRoutes.insert(route, at: 0)

        // Limit to last 10 routes
        if recentRoutes.count > 10 {
            recentRoutes.removeLast()
        }

        saveRecentRoutes()
    }

    /// Convenience method to add route with airport codes only
    func addRoute(origin: String, destination: String) {
        let route = RecentRoute(
            originCode: origin,
            destinationCode: destination
        )
        addRoute(route)
    }

    private func saveRecentRoutes() {
        if let encoded = try? JSONEncoder().encode(recentRoutes) {
            defaults.set(encoded, forKey: recentRoutesKey)
            print("💾 Saved \(recentRoutes.count) recent routes")
        }
    }

    private func loadRecentRoutes() {
        if let data = defaults.data(forKey: recentRoutesKey),
           let decoded = try? JSONDecoder().decode([RecentRoute].self, from: data) {
            recentRoutes = decoded
            print("📂 Loaded \(recentRoutes.count) recent routes")
        }
    }

    func removeRoute(_ route: RecentRoute) {
        recentRoutes.removeAll { $0.id == route.id }
        saveRecentRoutes()
    }

    func clearAll() {
        recentRoutes.removeAll()
        saveRecentRoutes()
    }
}
