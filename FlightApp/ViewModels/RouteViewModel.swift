//
//  RouteViewModel.swift
//  FlightApp
//
//  Created by Kush Shah on 10/7/25.
//

import Foundation

@MainActor
class RouteViewModel: ObservableObject {
    @Published var ifrRoutes: [IFRRouteInfo] = []
    @Published var currentFlights: [AeroFlight] = []
    @Published var awards: [AwardAvailability] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var originAirport: AeroAirport?
    @Published var destinationAirport: AeroAirport?

    var shouldShowAwards: Bool {
        FeatureFlags.shared.canUseSeatsAero
    }

    // Primary route to display (most frequently filed)
    var primaryRoute: IFRRouteInfo? {
        ifrRoutes.first
    }

    // Aggregate all aircraft types from all routes
    var commonAircraft: [String] {
        let allAircraft = ifrRoutes.flatMap { $0.aircraftTypes }
        let uniqueAircraft = Array(Set(allAircraft))
        return Array(uniqueAircraft.prefix(8)) // Top 8
    }

    // Total flights filed across all routes
    var totalFlightCount: String {
        let total = ifrRoutes.reduce(0) { $0 + $1.count }
        return total > 0 ? "\(total)" : ""
    }

    var hasAggregateStats: Bool {
        !commonAircraft.isEmpty || !totalFlightCount.isEmpty
    }

    func loadRouteData(origin: String, destination: String) async {
        isLoading = true
        error = nil

        // Load data in parallel
        async let routeInfoTask = loadRouteInfo(origin: origin, destination: destination)
        async let flightsTask = loadFlights(origin: origin, destination: destination)
        async let awardsTask = loadAwards(origin: origin, destination: destination)

        // Wait for all to complete
        _ = await (routeInfoTask, flightsTask, awardsTask)

        isLoading = false
    }

    private func loadRouteInfo(origin: String, destination: String) async {
        do {
            let routes = try await AeroAPIService.shared.getRouteInfo(
                origin: origin,
                destination: destination
            )
            ifrRoutes = routes
            print("✅ Loaded \(routes.count) IFR routes")
        } catch {
            print("⚠️ Failed to load route info: \(error)")
            // Don't set error - route info is optional
        }
    }

    private func loadFlights(origin: String, destination: String) async {
        do {
            // Get flights for today
            let flights = try await AeroAPIService.shared.getFlightsBetweenAirports(
                origin: origin,
                destination: destination,
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                connection: "nonstop"
            )
            currentFlights = flights

            // Store origin/destination airport info from first flight
            if let firstFlight = flights.first {
                originAirport = firstFlight.origin
                destinationAirport = firstFlight.destination
            }

            print("✅ Loaded \(flights.count) flights")
        } catch {
            print("⚠️ Failed to load flights: \(error)")
            // If this fails, show error since it's core functionality
            if currentFlights.isEmpty {
                self.error = "Could not load flights for this route"
            }
        }
    }

    private func loadAwards(origin: String, destination: String) async {
        guard FeatureFlags.shared.canUseSeatsAero else {
            print("ℹ️ Seats.aero disabled, skipping award search")
            return
        }

        do {
            // Convert ICAO to IATA if needed
            let originIATA = SearchInputParser.shared.icaoToIata(origin)
            let destIATA = SearchInputParser.shared.icaoToIata(destination)

            // Search next 30 days
            let startDate = Date()
            let endDate = Calendar.current.date(byAdding: .day, value: 30, to: startDate)

            let response = try await SeatsAeroAPIService.shared.searchAwards(
                origin: originIATA,
                destination: destIATA,
                startDate: startDate,
                endDate: endDate,
                cabins: "business,first"
            )
            awards = response.data
            print("✅ Loaded \(response.data.count) award options")
        } catch SeatsAeroAPIError.featureDisabled {
            print("ℹ️ Seats.aero feature disabled by user")
        } catch {
            print("⚠️ Failed to load awards: \(error)")
            // Award data is optional, don't show error
        }
    }
}
