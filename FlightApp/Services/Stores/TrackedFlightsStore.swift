//
//  TrackedFlightsStore.swift
//  FlightApp
//
//  Manages user's tracked flights with persistence
//

import SwiftUI
import Combine

/// Represents a tracked flight with minimal data needed for display and updates
struct TrackedFlight: Codable, Identifiable, Hashable {
    let id: UUID
    let flightNumber: String
    let originCode: String
    let destinationCode: String

    // Rich metadata for display
    let airlineIATA: String?
    let airlineName: String?
    let originCity: String?
    let destinationCity: String?
    let originLat: Double?
    let originLon: Double?
    let destinationLat: Double?
    let destinationLon: Double?

    // Flight status (cached, will be refreshed)
    var scheduledDeparture: Date?
    var scheduledArrival: Date?
    var status: String?
    var progress: Double?
    var lastUpdated: Date

    // Metadata
    let dateAdded: Date
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        flightNumber: String,
        originCode: String,
        destinationCode: String,
        airlineIATA: String? = nil,
        airlineName: String? = nil,
        originCity: String? = nil,
        destinationCity: String? = nil,
        originLat: Double? = nil,
        originLon: Double? = nil,
        destinationLat: Double? = nil,
        destinationLon: Double? = nil,
        scheduledDeparture: Date? = nil,
        scheduledArrival: Date? = nil,
        status: String? = nil,
        progress: Double? = nil,
        lastUpdated: Date = Date(),
        dateAdded: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.flightNumber = flightNumber
        self.originCode = originCode
        self.destinationCode = destinationCode
        self.airlineIATA = airlineIATA
        self.airlineName = airlineName
        self.originCity = originCity
        self.destinationCity = destinationCity
        self.originLat = originLat
        self.originLon = originLon
        self.destinationLat = destinationLat
        self.destinationLon = destinationLon
        self.scheduledDeparture = scheduledDeparture
        self.scheduledArrival = scheduledArrival
        self.status = status
        self.progress = progress
        self.lastUpdated = lastUpdated
        self.dateAdded = dateAdded
        self.isPinned = isPinned
    }

    /// Create from AeroFlight
    static func from(flight: AeroFlight, airlineName: String? = nil) -> TrackedFlight {
        return TrackedFlight(
            flightNumber: flight.ident,
            originCode: flight.origin.codeIata ?? flight.origin.codeIcao ?? "",
            destinationCode: flight.destination.codeIata ?? flight.destination.codeIcao ?? "",
            airlineIATA: flight.operatorIata,
            airlineName: airlineName,
            originCity: flight.origin.city,
            destinationCity: flight.destination.city,
            originLat: flight.origin.latitude,
            originLon: flight.origin.longitude,
            destinationLat: flight.destination.latitude,
            destinationLon: flight.destination.longitude,
            scheduledDeparture: flight.scheduledOut.flatMap { ISO8601DateFormatter().date(from: $0) },
            scheduledArrival: flight.scheduledIn.flatMap { ISO8601DateFormatter().date(from: $0) },
            status: flight.status,
            progress: flight.progressPercent.flatMap { Double($0) / 100.0 }
        )
    }

    /// Display name for the route
    var routeDisplay: String {
        "\(originCode) → \(destinationCode)"
    }

    /// Check if flight is currently active
    var isActive: Bool {
        status == "active" || status == "scheduled"
    }
}

/// Manages tracked flights with persistence and background updates
class TrackedFlightsStore: ObservableObject {
    @Published var trackedFlights: [TrackedFlight] = []

    private let defaults = UserDefaults.standard
    private let trackedFlightsKey = "TrackedFlights"
    private let maxTrackedFlights = 50

    init() {
        loadTrackedFlights()
    }

    // MARK: - Public Methods

    /// Add a flight to tracked list
    func addFlight(_ flight: TrackedFlight) {
        // Check if already tracking this flight
        if trackedFlights.contains(where: { $0.flightNumber.lowercased() == flight.flightNumber.lowercased() }) {
            print("⚠️ Flight \(flight.flightNumber) is already being tracked")
            return
        }

        // Limit number of tracked flights
        if trackedFlights.count >= maxTrackedFlights {
            // Remove oldest non-pinned flight
            if let oldestIndex = trackedFlights.enumerated()
                .filter({ !$0.element.isPinned })
                .min(by: { $0.element.dateAdded < $1.element.dateAdded })?.offset {
                trackedFlights.remove(at: oldestIndex)
            }
        }

        trackedFlights.insert(flight, at: 0)
        saveTrackedFlights()

        print("✅ Added flight \(flight.flightNumber) to tracked flights")
    }

    /// Remove a flight from tracked list
    func removeFlight(_ flight: TrackedFlight) {
        trackedFlights.removeAll { $0.id == flight.id }
        saveTrackedFlights()

        print("🗑️ Removed flight \(flight.flightNumber) from tracked flights")
    }

    /// Toggle pin status for a flight
    func togglePin(for flight: TrackedFlight) {
        if let index = trackedFlights.firstIndex(where: { $0.id == flight.id }) {
            trackedFlights[index].isPinned.toggle()

            // Re-sort: pinned flights at top
            trackedFlights.sort { lhs, rhs in
                if lhs.isPinned != rhs.isPinned {
                    return lhs.isPinned
                }
                return lhs.dateAdded > rhs.dateAdded
            }

            saveTrackedFlights()
        }
    }

    /// Update flight data (e.g., after refresh)
    func updateFlight(_ updatedFlight: TrackedFlight) {
        if let index = trackedFlights.firstIndex(where: { $0.id == updatedFlight.id }) {
            trackedFlights[index] = updatedFlight
            saveTrackedFlights()
        }
    }

    /// Check if a flight is being tracked
    func isTracking(flightNumber: String) -> Bool {
        trackedFlights.contains { $0.flightNumber.lowercased() == flightNumber.lowercased() }
    }

    /// Get active flights only
    var activeFlights: [TrackedFlight] {
        trackedFlights.filter { $0.isActive }
    }

    /// Get completed/landed flights
    var completedFlights: [TrackedFlight] {
        trackedFlights.filter { !$0.isActive }
    }

    // MARK: - Persistence

    private func saveTrackedFlights() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(trackedFlights) {
            defaults.set(encoded, forKey: trackedFlightsKey)
        }
    }

    private func loadTrackedFlights() {
        guard let savedFlights = defaults.object(forKey: trackedFlightsKey) as? Data else {
            return
        }

        let decoder = JSONDecoder()
        if let loadedFlights = try? decoder.decode([TrackedFlight].self, from: savedFlights) {
            trackedFlights = loadedFlights
            print("📱 Loaded \(trackedFlights.count) tracked flights")
        }
    }
}
