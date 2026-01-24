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
    @Published var cashOffers: [FlightOffer] = []
    @Published var isLoadingCashPrices = false
    @Published var cashPriceLoadingProgress: Double = 0.0
    @Published var cashPriceLoadingTotal: Int = 7
    @Published var cashPriceError: Error?
    @Published var isLoading = false
    @Published var error: String?
    @Published var originAirport: AeroAirport?
    @Published var destinationAirport: AeroAirport?
    
    // Expansion states for collapsed/expanded views
    @Published var awardsExpanded = false
    @Published var cashPricesExpanded = false

    // Constants for collapsed view
    let collapsedAwardCount = 5
    let collapsedCashCount = 3
    let maxBookingDaysAhead = 330 // Most airlines allow booking ~330-360 days out

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
    
    // Best awards to show in collapsed view
    var topAwards: [AwardAvailability] {
        filteredAwards
            .sorted { $0.valueScore() > $1.valueScore() }
            .prefix(collapsedAwardCount)
            .map { $0 }
    }
    
    // Best cash offers to show in collapsed view
    var topCashOffers: [FlightOffer] {
        Array(cashOffers.prefix(collapsedCashCount))
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

        // Load critical data in parallel (route info, flights, awards)
        // Cash prices load separately in background to not block UI
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadRouteInfo(origin: origin, destination: destination) }
            group.addTask { await self.loadFlights(origin: origin, destination: destination) }
            group.addTask { await self.loadAwards(origin: origin, destination: destination) }
        }

        isLoading = false

        // Load cash prices asynchronously after main content is ready
        Task {
            await loadCashPrices(origin: origin, destination: destination)
        }
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

    private func loadCashPrices(origin: String, destination: String) async {
        print("💵 [AMADEUS] Starting cash price search for \(origin) → \(destination)")

        guard FeatureFlags.shared.canUseAmadeus else {
            print("ℹ️ [AMADEUS] Amadeus disabled, skipping cash price search")
            return
        }

        isLoadingCashPrices = true
        cashPriceError = nil
        cashPriceLoadingProgress = 0.0
        cashPriceLoadingTotal = 7

        // Convert ICAO to IATA if needed
        let originIATA = SearchInputParser.shared.icaoToIata(origin)
        let destIATA = SearchInputParser.shared.icaoToIata(destination)

        print("🔄 [AMADEUS] Converted codes: \(origin) → \(originIATA), \(destination) → \(destIATA)")

        // Use actual system date - let the API tell us if it's too far out
        let baseDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        print("📅 [AMADEUS] Searching from: \(dateFormatter.string(from: baseDate))")

        // Search next 7 days
        var allOffers: [FlightOffer] = []

        for dayOffset in 0..<7 {
            guard let searchDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: baseDate) else {
                continue
            }

            let dateString = dateFormatter.string(from: searchDate)

            let params = AmadeusAPIService.FlightSearchParams(
                originLocationCode: originIATA,
                destinationLocationCode: destIATA,
                departureDate: dateString,
                adults: 1,
                travelClass: nil,  // All classes
                max: 5  // Limit to 5 offers per day
            )

            do {
                let offers = try await AmadeusAPIService.shared.searchFlightOffers(params: params)
                allOffers.append(contentsOf: offers)
                print("✅ [AMADEUS] Found \(offers.count) offers for \(dateString)")
            } catch {
                print("⚠️ [AMADEUS] No offers for \(dateString): \(error)")
                // Continue to next date instead of failing completely
            }

            // Update progress after each API call
            cashPriceLoadingProgress = Double(dayOffset + 1)
        }

        // Filter out unreasonably long itineraries (>2x typical nonstop duration)
        // For transatlantic routes like JFK-LHR, nonstop is ~7-8hrs, so filter >16hrs
        let filteredOffers = allOffers.filter { offer in
            guard let duration = offer.outbound?.duration else { return true }
            // Extract hours from ISO 8601 duration (e.g., "PT7H30M" → 7.5)
            let hours = parseDurationHours(duration)
            return hours < 16  // Filter out multi-stop itineraries with long layovers
        }

        // Smart sorting: prioritize nonstop, then duration, then price
        cashOffers = filteredOffers.sorted { offer1, offer2 in
            // 1. Prioritize nonstop flights
            if offer1.numberOfStops != offer2.numberOfStops {
                return offer1.numberOfStops < offer2.numberOfStops
            }

            // 2. For same number of stops, prioritize shorter duration
            let duration1 = offer1.outbound?.duration ?? "PT99H"
            let duration2 = offer2.outbound?.duration ?? "PT99H"
            if duration1 != duration2 {
                return duration1 < duration2
            }

            // 3. Finally, sort by price
            return offer1.totalPrice < offer2.totalPrice
        }

        if cashOffers.isEmpty {
            print("⚠️ [AMADEUS] No valid offers found")
            cashPriceError = NSError(domain: "FlightApp", code: 404, userInfo: [NSLocalizedDescriptionKey: "No flights available for these dates"])
        } else {
            print("✅ [AMADEUS] Loaded \(cashOffers.count) cash price options (sorted by stops → duration → price)")
        }

        isLoadingCashPrices = false
    }

    // Helper to parse ISO 8601 duration to hours
    private func parseDurationHours(_ duration: String) -> Double {
        // Parse "PT7H30M" format
        var result = 0.0
        let components = duration.replacingOccurrences(of: "PT", with: "")

        if let hRange = components.range(of: "H") {
            let hours = String(components[..<hRange.lowerBound])
            result += Double(hours) ?? 0
        }

        if let mRange = components.range(of: "M") {
            var minuteStr = components
            if let hRange = components.range(of: "H") {
                minuteStr = String(components[hRange.upperBound..<mRange.lowerBound])
            } else {
                minuteStr = String(components[..<mRange.lowerBound])
            }
            let minutes = Double(minuteStr) ?? 0
            result += minutes / 60.0
        }

        return result
    }

    // Get route info for booking URLs

    // Get best award for a specific cabin class
    func bestAwardForCabin(_ cabin: CabinClass) -> AwardAvailability? {
        awards
            .filter { $0.isCabinAvailable(cabin) }
            .min(by: { award1, award2 in
                guard let cost1String = award1.getMileageCost(for: cabin),
                      let cost2String = award2.getMileageCost(for: cabin) else {
                    return false
                }
                // Remove commas and convert to int for comparison
                let cost1 = Int(cost1String.replacingOccurrences(of: ",", with: "")) ?? Int.max
                let cost2 = Int(cost2String.replacingOccurrences(of: ",", with: "")) ?? Int.max
                return cost1 < cost2
            })
    }

    // Check if any awards are available for a specific cabin
    func hasAwardsForCabin(_ cabin: CabinClass) -> Bool {
        awards.contains { $0.isCabinAvailable(cabin) }
    }

    func getRouteInfo() -> (origin: String, destination: String)? {
        guard let origin = originAirport?.codeIata ?? originAirport?.codeIcao,
              let destination = destinationAirport?.codeIata ?? destinationAirport?.codeIcao else {
            return nil
        }
        return (origin, destination)
    }
}
