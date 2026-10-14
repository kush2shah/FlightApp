//
//  AwardPricingTests.swift
//  FlightAppTests
//

import Testing
@testable import FlightApp

struct AwardPricingTests {
    @Test func parsesRawCostsNumerically() {
        let award = Fixtures.award(id: "a", costs: [.business: "70000", .economy: "35,000"])
        #expect(award.mileageCostValue(for: .business) == 70000)
        #expect(award.mileageCostValue(for: .economy) == 35000)
        #expect(award.mileageCostValue(for: .first) == nil)
    }

    /// Regression: costs used to be compared after formatting ("70k"), which
    /// parsed as nil → Int.max for every award, making "best" arbitrary.
    @Test func cheapestUsesNumericCost() {
        let awards = [
            Fixtures.award(id: "pricey", costs: [.business: "120000"]),
            Fixtures.award(id: "cheap", costs: [.business: "55000"]),
            Fixtures.award(id: "mid", costs: [.business: "70000"])
        ]
        #expect(awards.cheapest(for: .business)?.id == "cheap")
        #expect(awards.sortedByCost(for: .business).map(\.id) == ["cheap", "mid", "pricey"])
    }

    @Test func sortedByCostBreaksTiesByDateAndSkipsUnavailableCabins() {
        let awards = [
            Fixtures.award(id: "later", date: "2026-11-09", costs: [.business: "60000"]),
            Fixtures.award(id: "economyOnly", costs: [.economy: "20000"]),
            Fixtures.award(id: "earlier", date: "2026-11-02", costs: [.business: "60000"])
        ]
        #expect(awards.sortedByCost(for: .business).map(\.id) == ["earlier", "later"])
    }

    @Test func groupsByProgramOrderedByBestPrice() {
        let awards = [
            Fixtures.award(id: "u1", source: "united", costs: [.business: "90000"]),
            Fixtures.award(id: "a1", source: "aeroplan", costs: [.business: "60000"]),
            Fixtures.award(id: "u2", source: "united", costs: [.business: "80000"])
        ]
        let groups = awards.groupedByProgram(for: .business)

        #expect(groups.count == 2)
        #expect(groups.first?.awards.map(\.id) == ["a1"])
        #expect(Set(groups.last?.awards.map(\.id) ?? []) == ["u1", "u2"])
    }

    @Test func awardOffersListEveryAvailableCabin() {
        let award = Fixtures.award(id: "a", source: "united", costs: [.business: "70000", .first: "110000"])
        let offers = award.awardOffers.sorted { $0.miles < $1.miles }

        #expect(offers.map(\.cabin) == ["Business", "First"])
        #expect(offers.map(\.miles) == [70000, 110000])
        #expect(offers.allSatisfy { $0.program == "united" })
    }
}
