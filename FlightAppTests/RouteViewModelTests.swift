//
//  RouteViewModelTests.swift
//  FlightAppTests
//

import Foundation
import Testing
@testable import FlightApp

@MainActor
struct RouteViewModelTests {
    let flightData = FakeFlightData()
    let awardSearch = FakeAwardSearch()
    let cashFares = FakeCashFares()
    let fixedNow = ISO8601DateFormatter().date(from: "2026-11-01T12:00:00Z")!

    func makeViewModel(seatsAero: Bool = true, amadeus: Bool = true) -> RouteViewModel {
        RouteViewModel(
            flightData: flightData,
            awardSearch: awardSearch,
            cashFares: cashFares,
            featureFlags: .isolated(seatsAero: seatsAero, amadeus: amadeus),
            now: { fixedNow }
        )
    }

    // MARK: Loading

    @Test func loadsFlightsAndRouteAirports() async {
        flightData.flights = .success([
            Fixtures.flight(
                ident: "BA112",
                origin: Fixtures.airport("JFK", lat: 40.64, lon: -73.78),
                destination: Fixtures.airport("LHR", lat: 51.47, lon: -0.45, city: "London")
            )
        ])
        let viewModel = makeViewModel(seatsAero: false, amadeus: false)

        await viewModel.loadRouteData(origin: "JFK", destination: "LHR")

        #expect(viewModel.currentFlights.map(\.ident) == ["BA112"])
        #expect(viewModel.originAirport?.code == "JFK")
        #expect(viewModel.destinationAirport?.city == "London")
        #expect(viewModel.hasRouteAirports)
        #expect(!viewModel.isLoading)
        #expect(viewModel.error == nil)
    }

    @Test func surfacesFlightLoadFailure() async {
        flightData.flights = .failure(FakeError())
        let viewModel = makeViewModel(seatsAero: false, amadeus: false)

        await viewModel.loadRouteData(origin: "JFK", destination: "LHR")

        #expect(viewModel.error == "Could not load flights for this route")
        #expect(viewModel.isEmpty)
    }

    @Test func routeInfoFailureIsNotFatal() async {
        flightData.flights = .success([Fixtures.flight(ident: "BA112")])
        flightData.routes = .failure(FakeError())
        let viewModel = makeViewModel(seatsAero: false, amadeus: false)

        await viewModel.loadRouteData(origin: "JFK", destination: "LHR")

        #expect(viewModel.error == nil)
        #expect(viewModel.primaryRoute == nil)
    }

    @Test func respectsDisabledIntegrations() async {
        let viewModel = makeViewModel(seatsAero: false, amadeus: false)

        await viewModel.loadRouteData(origin: "JFK", destination: "LHR")

        #expect(awardSearch.requests.isEmpty)
        #expect(cashFares.requestedDates.isEmpty)
        #expect(!viewModel.showsCashFares)
        #expect(!viewModel.isLoadingCashPrices)
    }

    @Test func searchesAwardsWithIATACodes() async {
        awardSearch.awards = [Fixtures.award(id: "a", costs: [.business: "60000"])]
        let viewModel = makeViewModel(amadeus: false)

        await viewModel.loadRouteData(origin: "KJFK", destination: "EGLL")

        #expect(awardSearch.requests.first?.origin == "JFK")
        #expect(awardSearch.requests.first?.destination == "EGLL")
        #expect(viewModel.awards.map(\.id) == ["a"])
        #expect(viewModel.cabinsWithAwards == [.business])
    }

    @Test func searchesCashFaresAcrossTheWeek() async throws {
        cashFares.offersByDate = [
            "2026-11-03": [Fixtures.offer(id: "x", duration: "PT7H", price: "650.00")]
        ]
        let viewModel = makeViewModel(seatsAero: false)

        await viewModel.loadRouteData(origin: "JFK", destination: "LHR")

        #expect(cashFares.requestedDates.count == RouteViewModel.cashSearchDays)
        #expect(cashFares.requestedDates.first == "2026-11-01")
        #expect(viewModel.cashOffers.map(\.id) == ["x"])
        #expect(viewModel.cashPriceError == nil)
        #expect(viewModel.cashPriceLoadingProgress == Double(RouteViewModel.cashSearchDays))
        #expect(!viewModel.isLoadingCashPrices)
    }

    @Test func setsCashErrorWhenNoFaresFound() async {
        let viewModel = makeViewModel(seatsAero: false)

        await viewModel.loadRouteData(origin: "JFK", destination: "LHR")

        #expect(viewModel.cashOffers.isEmpty)
        #expect(viewModel.cashPriceError != nil)
    }

    // MARK: Derived State

    @Test func sortsInProgressFlightsFirstThenByDeparture() async {
        flightData.flights = .success([
            Fixtures.flight(ident: "LATE", scheduledOut: "2026-11-01T20:00:00Z"),
            Fixtures.flight(ident: "AIR", status: "En Route / On Time", scheduledOut: "2026-11-01T08:00:00Z"),
            Fixtures.flight(ident: "NOTIME"),
            Fixtures.flight(ident: "EARLY", scheduledOut: "2026-11-01T14:00:00Z")
        ])
        let viewModel = makeViewModel(seatsAero: false, amadeus: false)

        await viewModel.loadRouteData(origin: "JFK", destination: "LHR")

        #expect(viewModel.sortedFlights.map(\.ident) == ["AIR", "EARLY", "LATE", "NOTIME"])
    }

    @Test func buildsInsightContexts() async throws {
        flightData.flights = .success([
            Fixtures.flight(
                ident: "BA112",
                origin: Fixtures.airport("JFK", lat: 40.6413, lon: -73.7781),
                destination: Fixtures.airport("LHR", lat: 51.47, lon: -0.4543, city: "London")
            )
        ])
        awardSearch.awards = [Fixtures.award(id: "a", source: "aeroplan", costs: [.business: "60,000"])]
        let viewModel = makeViewModel(amadeus: false)

        await viewModel.loadRouteData(origin: "JFK", destination: "LHR")

        let award = viewModel.awardInsightContext
        #expect(award.origin == "JFK")
        #expect(award.awardData?.map(\.miles) == [60000])

        let route = viewModel.routeInsightContext
        #expect(route.destinationCity == "London")
        let distance = try #require(route.distance)
        #expect((3400...3500).contains(distance))
    }

    // MARK: Cash Ranking

    /// Regression: durations were compared as strings, so "PT10H" sorted before "PT7H".
    @Test func ranksCashOffersByStopsThenDurationThenPrice() {
        let ranked = RouteViewModel.rankCashOffers([
            Fixtures.offer(id: "oneStop", duration: "PT9H", stops: 1, price: "300.00"),
            Fixtures.offer(id: "nonstopLong", duration: "PT10H", price: "800.00"),
            Fixtures.offer(id: "nonstopPricey", duration: "PT7H", price: "900.00"),
            Fixtures.offer(id: "nonstopCheap", duration: "PT7H", price: "500.00"),
            Fixtures.offer(id: "tooLong", duration: "PT17H", price: "100.00")
        ])

        #expect(ranked.map(\.id) == ["nonstopCheap", "nonstopPricey", "nonstopLong", "oneStop"])
    }
}
