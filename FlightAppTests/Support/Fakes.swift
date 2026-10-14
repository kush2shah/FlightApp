//
//  Fakes.swift
//  FlightAppTests
//

import Foundation
@testable import FlightApp

struct FakeError: Error {}

final class FakeFlightData: FlightDataProviding {
    var flights: Result<[AeroFlight], Error> = .success([])
    var routes: Result<[IFRRouteInfo], Error> = .success([])
    private(set) var flightInfoRequests: [(flightNumber: String, startDate: Date?)] = []

    func getFlightInfo(_ flightNumber: String, startDate: Date?) async throws -> [AeroFlight] {
        flightInfoRequests.append((flightNumber, startDate))
        return try flights.get()
    }

    func getFlightsBetweenAirports(origin: String, destination: String, startDate: Date?, endDate: Date?, connection: String?) async throws -> [AeroFlight] {
        try flights.get()
    }

    func getRouteInfo(origin: String, destination: String) async throws -> [IFRRouteInfo] {
        try routes.get()
    }
}

final class FakeAwardSearch: AwardSearching {
    var awards: [AwardAvailability] = []
    private(set) var requests: [(origin: String, destination: String)] = []

    func searchAwards(origin: String, destination: String, startDate: Date?, endDate: Date?, cabins: String?, sources: String?) async throws -> SeatsAeroSearchResponse {
        requests.append((origin, destination))
        return SeatsAeroSearchResponse(data: awards, count: awards.count, hasMore: false, cursor: nil)
    }
}

@MainActor
final class FakeCashFares: CashFareSearching {
    /// Offers returned per departure date ("yyyy-MM-dd"); dates not listed throw.
    var offersByDate: [String: [FlightOffer]] = [:]
    private(set) var requestedDates: [String] = []

    func searchFlightOffers(params: AmadeusAPIService.FlightSearchParams) async throws -> [FlightOffer] {
        requestedDates.append(params.departureDate)
        guard let offers = offersByDate[params.departureDate] else { throw FakeError() }
        return offers
    }
}

final class FakeInsightGenerator: InsightGenerating {
    var result: Result<String, Error> = .success("Insight")
    private(set) var callCount = 0

    func generateInsight(type: InsightType, context: InsightContext) async throws -> String {
        callCount += 1
        return try result.get()
    }
}

final class FakeInsightCache: InsightCaching {
    var stored: [String: String] = [:]

    private func key(_ type: InsightType, _ context: InsightContext) -> String {
        "\(type)-\(context.origin ?? "")-\(context.destination ?? "")"
    }

    func getCachedInsight(type: InsightType, context: InsightContext) -> String? {
        stored[key(type, context)]
    }

    func cacheInsight(_ insight: String, type: InsightType, context: InsightContext) {
        stored[key(type, context)] = insight
    }
}

extension FeatureFlags {
    /// Flags backed by a throwaway UserDefaults suite, so tests never touch real settings.
    static func isolated(seatsAero: Bool = true, amadeus: Bool = true) -> FeatureFlags {
        let flags = FeatureFlags(defaults: UserDefaults(suiteName: "FlightAppTests-\(UUID().uuidString)")!)
        flags.isSeatsAeroEnabled = seatsAero
        flags.isAmadeusEnabled = amadeus
        return flags
    }
}
