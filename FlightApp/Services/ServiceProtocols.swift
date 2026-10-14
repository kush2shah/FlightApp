//
//  ServiceProtocols.swift
//  FlightApp
//
//  Seams between view models and the network-backed services, so view models
//  can be constructed with fakes in tests. Production code uses the `.shared`
//  instances, which are the defaults everywhere.
//

import Foundation

/// FlightAware AeroAPI operations used by view models.
protocol FlightDataProviding {
    func getFlightInfo(_ flightNumber: String, startDate: Date?) async throws -> [AeroFlight]
    func getFlightsBetweenAirports(
        origin: String,
        destination: String,
        startDate: Date?,
        endDate: Date?,
        connection: String?
    ) async throws -> [AeroFlight]
    func getRouteInfo(origin: String, destination: String) async throws -> [IFRRouteInfo]
}

/// Seats.aero award search.
protocol AwardSearching {
    func searchAwards(
        origin: String,
        destination: String,
        startDate: Date?,
        endDate: Date?,
        cabins: String?,
        sources: String?
    ) async throws -> SeatsAeroSearchResponse
}

/// Amadeus cash fare search.
@MainActor
protocol CashFareSearching {
    func searchFlightOffers(params: AmadeusAPIService.FlightSearchParams) async throws -> [FlightOffer]
}

/// Generates short Claude-written insights.
protocol InsightGenerating {
    func generateInsight(type: InsightType, context: InsightContext) async throws -> String
}

/// Stores generated insights so repeat views don't re-hit the API.
protocol InsightCaching {
    func getCachedInsight(type: InsightType, context: InsightContext) -> String?
    func cacheInsight(_ insight: String, type: InsightType, context: InsightContext)
}

extension AeroAPIService: FlightDataProviding {}
extension SeatsAeroAPIService: AwardSearching {}
extension AmadeusAPIService: CashFareSearching {}
extension ClaudeAPIService: InsightGenerating {}
extension InsightsCacheService: InsightCaching {}
