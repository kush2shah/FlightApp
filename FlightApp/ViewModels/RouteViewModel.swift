//
//  RouteViewModel.swift
//  FlightApp
//
//  Created by Kush Shah on 10/7/25.
//

import Foundation
import OSLog

@MainActor
class RouteViewModel: ObservableObject {
    @Published var ifrRoutes: [IFRRouteInfo] = []
    @Published var currentFlights: [AeroFlight] = []
    @Published var awards: [AwardAvailability] = []
    @Published var awardFilters = AwardPreferences.shared.createDefaultFilters()
    @Published var cashOffers: [FlightOffer] = []
    @Published var isLoadingCashPrices = false
    @Published var cashPriceLoadingProgress: Double = 0.0
    @Published private(set) var cashPriceLoadingTotal: Int = RouteViewModel.cashSearchDays
    @Published var cashPriceError: Error?
    @Published var isLoading = false
    @Published var error: String?
    @Published var originAirport: AeroAirport?
    @Published var destinationAirport: AeroAirport?

    /// Number of consecutive days searched for cash fares
    static let cashSearchDays = 7
    /// Itineraries longer than this are almost always long-layover connections
    static let maxCashItineraryHours = 16.0

    private let flightData: FlightDataProviding
    private let awardSearch: AwardSearching
    private let cashFares: CashFareSearching
    private let featureFlags: FeatureFlags
    private let now: () -> Date

    private(set) var origin = ""
    private(set) var destination = ""

    init(
        flightData: FlightDataProviding? = nil,
        awardSearch: AwardSearching? = nil,
        cashFares: CashFareSearching? = nil,
        featureFlags: FeatureFlags? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.flightData = flightData ?? AeroAPIService.shared
        self.awardSearch = awardSearch ?? SeatsAeroAPIService.shared
        self.cashFares = cashFares ?? AmadeusAPIService.shared
        self.featureFlags = featureFlags ?? .shared
        self.now = now
    }

    // MARK: - Derived State

    var showsCashFares: Bool {
        featureFlags.canUseAmadeus
    }

    // Primary route to display (most frequently filed)
    var primaryRoute: IFRRouteInfo? {
        ifrRoutes.first
    }

    var hasRouteAirports: Bool {
        originAirport != nil && destinationAirport != nil
    }

    /// Nothing to show and nothing still loading
    var isEmpty: Bool {
        currentFlights.isEmpty && awards.isEmpty && cashOffers.isEmpty && !isLoading && !isLoadingCashPrices
    }

    /// In-progress flights first, then by scheduled departure
    var sortedFlights: [AeroFlight] {
        currentFlights.sorted { lhs, rhs in
            if lhs.isInProgress != rhs.isInProgress {
                return lhs.isInProgress
            }
            switch (lhs.scheduledOut, rhs.scheduledOut) {
            case let (l?, r?): return l < r
            case (.some, .none): return true
            default: return false
            }
        }
    }

    /// Cabins with at least one award, in display order
    var cabinsWithAwards: [CabinClass] {
        [CabinClass.economy, .premiumEconomy, .business, .first].filter(hasAwardsForCabin)
    }

    func hasAwardsForCabin(_ cabin: CabinClass) -> Bool {
        awards.contains { $0.isCabinAvailable(cabin) }
    }

    // MARK: - Insight Contexts

    var awardInsightContext: InsightContext {
        let offers = awards.flatMap(\.awardOffers)
        return InsightContext(
            awardData: offers.isEmpty ? nil : offers,
            origin: origin,
            destination: destination
        )
    }

    var routeInsightContext: InsightContext {
        var distance: Double?
        if let originLat = originAirport?.latitude, let originLon = originAirport?.longitude,
           let destLat = destinationAirport?.latitude, let destLon = destinationAirport?.longitude {
            distance = GreatCircle.distanceMiles(
                from: .init(latitude: originLat, longitude: originLon),
                to: .init(latitude: destLat, longitude: destLon)
            )
        }

        return InsightContext(
            origin: origin,
            destination: destination,
            distance: distance,
            destinationAirport: destination,
            destinationCity: destinationAirport?.city
        )
    }

    /// Brand colors of the first operating airline on the route
    var airlineColors: AirlineBrandColors? {
        guard let code = currentFlights.first?.operatorIata else { return nil }
        return AirlineColorService.shared.getBrandColors(for: code)
    }

    // MARK: - Loading

    func loadRouteData(origin: String, destination: String) async {
        self.origin = origin
        self.destination = destination
        isLoading = true
        error = nil

        // Load critical data in parallel (route info, flights, awards)
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadRouteInfo(origin: origin, destination: destination) }
            group.addTask { await self.loadFlights(origin: origin, destination: destination) }
            group.addTask { await self.loadAwards(origin: origin, destination: destination) }
        }

        isLoading = false

        // Cash prices load after main content is shown. Awaiting here (rather than
        // spawning a Task) keeps the work tied to the view's .task, so it's
        // cancelled if the user leaves the route.
        await loadCashPrices(origin: origin, destination: destination)
    }

    private func loadRouteInfo(origin: String, destination: String) async {
        do {
            ifrRoutes = try await flightData.getRouteInfo(origin: origin, destination: destination)
            Logger.route.debug("Loaded \(self.ifrRoutes.count) IFR routes")
        } catch {
            // Route info is optional
            Logger.route.error("Failed to load route info: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func loadFlights(origin: String, destination: String) async {
        do {
            // COST OPTIMIZATION: 18-hour window (6 hours ago to 12 hours from now)
            // still captures en route and near-future flights
            let start = Calendar.current.date(byAdding: .hour, value: -6, to: now()) ?? now()
            let end = Calendar.current.date(byAdding: .hour, value: 12, to: now())

            let flights = try await flightData.getFlightsBetweenAirports(
                origin: origin,
                destination: destination,
                startDate: start,
                endDate: end,
                connection: "nonstop"
            )
            currentFlights = flights

            if let firstFlight = flights.first {
                originAirport = firstFlight.origin
                destinationAirport = firstFlight.destination
            }
            Logger.route.debug("Loaded \(flights.count) flights")
        } catch {
            // Flights are core functionality, so surface the failure
            Logger.route.error("Failed to load flights: \(error.localizedDescription, privacy: .public)")
            if currentFlights.isEmpty {
                self.error = "Could not load flights for this route"
            }
        }
    }

    private func loadAwards(origin: String, destination: String) async {
        guard featureFlags.canUseSeatsAero else { return }

        do {
            let response = try await awardSearch.searchAwards(
                origin: SearchInputParser.shared.icaoToIata(origin),
                destination: SearchInputParser.shared.icaoToIata(destination),
                startDate: awardFilters.dateRange.startDate,
                endDate: awardFilters.dateRange.endDate,
                cabins: awardFilters.cabinsParameter,
                sources: nil
            )
            awards = response.data
            Logger.awards.debug("Loaded \(response.data.count) award options")
        } catch {
            // Award data is optional; SeatsAeroAPIError covers disabled, auth, rate limit, etc.
            Logger.awards.error("Failed to load awards: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func loadCashPrices(origin: String, destination: String) async {
        guard featureFlags.canUseAmadeus else { return }

        isLoadingCashPrices = true
        cashPriceError = nil
        cashPriceLoadingProgress = 0

        let originIATA = SearchInputParser.shared.icaoToIata(origin)
        let destIATA = SearchInputParser.shared.icaoToIata(destination)

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var allOffers: [FlightOffer] = []
        let baseDate = now()

        // Sequential on purpose: AmadeusAPIService rate-limits to ~10 req/sec
        for dayOffset in 0..<Self.cashSearchDays {
            guard !Task.isCancelled else { break }
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
                allOffers += try await cashFares.searchFlightOffers(params: params)
            } catch {
                // Keep going; one empty day shouldn't hide the rest
                Logger.cashFares.debug("No offers for \(dateString, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }

            cashPriceLoadingProgress = Double(dayOffset + 1)
        }

        cashOffers = Self.rankCashOffers(allOffers)
        if cashOffers.isEmpty {
            cashPriceError = NSError(domain: "FlightApp", code: 404, userInfo: [NSLocalizedDescriptionKey: "No flights available for these dates"])
        }

        isLoadingCashPrices = false
    }

    /// Drops long-layover itineraries, then orders by stops, duration, and price.
    static func rankCashOffers(_ offers: [FlightOffer]) -> [FlightOffer] {
        offers
            .filter { ($0.outbound?.durationHours ?? 0) < maxCashItineraryHours }
            .sorted { lhs, rhs in
                if lhs.numberOfStops != rhs.numberOfStops {
                    return lhs.numberOfStops < rhs.numberOfStops
                }
                let lhsHours = lhs.outbound?.durationHours ?? .infinity
                let rhsHours = rhs.outbound?.durationHours ?? .infinity
                if lhsHours != rhsHours {
                    return lhsHours < rhsHours
                }
                return lhs.totalPrice < rhs.totalPrice
            }
    }
}
