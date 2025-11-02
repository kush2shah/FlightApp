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
    @Published var awardFilters = AwardPreferences.shared.createDefaultFilters()
    @Published var isLoading = false
    @Published var error: String?
    @Published var originAirport: AeroAirport?
    @Published var destinationAirport: AeroAirport?

    var shouldShowAwards: Bool {
        FeatureFlags.shared.canUseSeatsAero
    }

    // Filtered awards based on user-selected filters
    var filteredAwards: [AwardAvailability] {
        var filtered = awards

        // Filter by cabin class
        filtered = filtered.filter { award in
            awardFilters.selectedCabins.contains { cabin in
                award.isCabinAvailable(cabin)
            }
        }

        // Filter by date range
        filtered = filtered.filter { award in
            guard let date = award.parsedDate else { return false }
            return date >= awardFilters.dateRange.startDate && date <= awardFilters.dateRange.endDate
        }

        // Filter by mileage programs (if specific programs selected)
        if !awardFilters.selectedPrograms.isEmpty {
            filtered = filtered.filter { award in
                awardFilters.selectedPrograms.contains { program in
                    award.source.lowercased().contains(program.lowercased())
                }
            }
        }

        // Filter by max points (if set)
        if let maxPoints = awardFilters.maxPoints {
            filtered = filtered.filter { award in
                guard let best = award.bestAvailableCabin() else { return false }
                let costString = best.cost.replacingOccurrences(of: ",", with: "")
                guard let cost = Int(costString) else { return false }
                return cost <= maxPoints
            }
        }

        return filtered
    }

    // Smart recommendations - top 3 best value awards
    var recommendedAwards: [AwardAvailability] {
        filteredAwards
            .sorted { $0.valueScore() > $1.valueScore() }
            .prefix(3)
            .map { $0 }
    }

    // All unique mileage programs in results (for filter UI)
    var availablePrograms: [String] {
        Array(Set(awards.map { $0.source })).sorted()
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
            .compactMap { AircraftTypeService.shared.getAircraftName(from: $0) }
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
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadRouteInfo(origin: origin, destination: destination) }
            group.addTask { await self.loadFlights(origin: origin, destination: destination) }
            group.addTask { await self.loadAwards(origin: origin, destination: destination) }
        }

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
            // COST OPTIMIZATION: Reduce time window from 36 hours to 18 hours
            // Get flights from 6 hours ago to 12 hours from now
            // This still captures en route and near-future flights while reducing API costs
            let startDate = Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date()
            let endDate = Calendar.current.date(byAdding: .hour, value: 12, to: Date())

            let flights = try await AeroAPIService.shared.getFlightsBetweenAirports(
                origin: origin,
                destination: destination,
                startDate: startDate,
                endDate: endDate,
                connection: "nonstop"
            )
            currentFlights = flights

            // Store origin/destination airport info from first flight
            if let firstFlight = flights.first {
                originAirport = firstFlight.origin
                destinationAirport = firstFlight.destination
            }

            print("✅ Loaded \(flights.count) flights (including \(flights.filter(\.isInProgress).count) en route)")
        } catch {
            print("⚠️ Failed to load flights: \(error)")
            // If this fails, show error since it's core functionality
            if currentFlights.isEmpty {
                self.error = "Could not load flights for this route"
            }
        }
    }

    private func loadAwards(origin: String, destination: String) async {
        print("🎯 [AWARDS] Starting award search for \(origin) → \(destination)")

        guard FeatureFlags.shared.canUseSeatsAero else {
            print("ℹ️ [AWARDS] Seats.aero disabled, skipping award search")
            return
        }

        do {
            // Convert ICAO to IATA if needed
            let originIATA = SearchInputParser.shared.icaoToIata(origin)
            let destIATA = SearchInputParser.shared.icaoToIata(destination)

            print("🔄 [AWARDS] Converted codes: \(origin) → \(originIATA), \(destination) → \(destIATA)")

            // Use date range from filter preferences
            let startDate = awardFilters.dateRange.startDate
            let endDate = awardFilters.dateRange.endDate

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            print("📅 [AWARDS] Date range: \(dateFormatter.string(from: startDate)) to \(dateFormatter.string(from: endDate))")

            // Use cabin preferences for API search
            let cabinsParam = awardFilters.cabinsParameter
            print("💺 [AWARDS] Searching cabins: \(cabinsParam)")

            let response = try await SeatsAeroAPIService.shared.searchAwards(
                origin: originIATA,
                destination: destIATA,
                startDate: startDate,
                endDate: endDate,
                cabins: cabinsParam
            )
            awards = response.data
            print("✅ [AWARDS] Loaded \(response.data.count) award options (searching: \(cabinsParam))")

            if response.data.isEmpty {
                print("ℹ️ [AWARDS] No award availability found for this route/date range")
            }
        } catch SeatsAeroAPIError.featureDisabled {
            print("ℹ️ [AWARDS] Seats.aero feature disabled by user")
        } catch SeatsAeroAPIError.unauthorized {
            print("❌ [AWARDS] API authentication failed - check API key")
        } catch SeatsAeroAPIError.rateLimitExceeded {
            print("⚠️ [AWARDS] Rate limit exceeded")
        } catch SeatsAeroAPIError.noResultsFound {
            print("ℹ️ [AWARDS] API returned no results (400 status)")
        } catch SeatsAeroAPIError.serverError(let statusCode) {
            print("❌ [AWARDS] Server error: \(statusCode)")
        } catch {
            print("⚠️ [AWARDS] Failed to load awards: \(error)")
            print("🔍 [AWARDS] Error details: \(error.localizedDescription)")
            // Award data is optional, don't show error
        }
    }

    // Get route info for booking URLs
    func getRouteInfo() -> (origin: String, destination: String)? {
        guard let origin = originAirport?.codeIata ?? originAirport?.codeIcao,
              let destination = destinationAirport?.codeIata ?? destinationAirport?.codeIcao else {
            return nil
        }
        return (origin, destination)
    }
}
