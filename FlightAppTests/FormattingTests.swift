//
//  FormattingTests.swift
//  FlightAppTests
//

import Testing
@testable import FlightApp

struct MileageFormattingTests {
    @Test(arguments: [
        ("1000", "1k"),
        ("30000", "30k"),
        ("65600", "65.6k"),
        ("35,000", "35k"),
        ("999", "999"),
        ("0", "0"),
        (" 70000 ", "70k"),
        ("not a number", "not a number")
    ])
    func formatsCost(input: String, expected: String) {
        #expect(input.formattedMileageCost() == expected)
    }
}

struct ISO8601DurationTests {
    @Test(arguments: [
        ("PT7H30M", 7.5),
        ("PT10H", 10.0),
        ("PT45M", 0.75),
        ("PT1H30M36S", 1.51)
    ])
    func parsesHours(input: String, hours: Double) throws {
        let parsed = try #require(input.iso8601DurationHours)
        #expect(abs(parsed - hours) < 0.001)
    }

    @Test(arguments: ["", "PT", "7H30M", "PTXH", "PT7H30", "P1D"])
    func rejectsMalformed(input: String) {
        #expect(input.iso8601DurationHours == nil)
    }

    @Test(arguments: [
        ("PT7H30M", "7h 30m"),
        ("PT10H", "10h"),
        ("PT45M", "45m"),
        ("garbage", "garbage")
    ])
    func formatsForDisplay(input: String, expected: String) {
        #expect(input.formattedISO8601Duration == expected)
    }
}
