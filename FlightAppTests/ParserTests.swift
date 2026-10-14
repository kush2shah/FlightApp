//
//  ParserTests.swift
//  FlightAppTests
//

import Testing
@testable import FlightApp

struct FlightNumberParserTests {
    let parser = FlightNumberParser.shared

    @Test(arguments: [
        ("AA1", "AA", "1"),
        ("ua60", "UA", "60"),
        ("BA 175", "BA", "175"),
        ("B61234", "B6", "1234"),
        ("F9102", "F9", "102"),
        ("AAL1234", "AAL", "1234")
    ])
    func parsesValidFlightNumbers(input: String, airline: String, number: String) throws {
        let parsed = try #require(parser.parseFlightNumber(input))
        #expect(parsed.airlineCode == airline)
        #expect(parsed.flightNumber == number)
    }

    @Test(arguments: ["", "1234", "12 345", "AA", "JFK-LHR"])
    func rejectsInvalidFlightNumbers(input: String) {
        #expect(parser.parseFlightNumber(input) == nil)
        #expect(!parser.isValidFlightNumber(input))
    }

    @Test func normalizesSpacing() {
        #expect(parser.normalizeFlightNumber(" ba 175 ") == "BA175")
    }
}

struct SearchInputParserTests {
    let parser = SearchInputParser.shared

    @Test(arguments: [
        ("JFK LHR", "JFK", "LHR"),
        ("jfk-lhr", "JFK", "LHR"),
        ("SFO → NRT", "SFO", "NRT"),
        ("SFO->LAX", "SFO", "LAX"),
        ("BOS, ORD", "BOS", "ORD"),
        ("JFKLHR", "JFK", "LHR"),
        ("KJFK EGLL", "KJFK", "EGLL")
    ])
    func parsesRoutes(input: String, origin: String, destination: String) {
        guard case let .route(parsedOrigin, parsedDestination) = parser.parse(input) else {
            Issue.record("Expected a route for \(input)")
            return
        }
        #expect(parsedOrigin == origin)
        #expect(parsedDestination == destination)
    }

    @Test(arguments: ["UA60", "BA 175", "DL1234"])
    func parsesFlightNumbers(input: String) {
        guard case .flightNumber = parser.parse(input) else {
            Issue.record("Expected a flight number for \(input)")
            return
        }
    }

    @Test(arguments: ["", "   ", "hello world!", "12"])
    func rejectsGarbage(input: String) {
        guard case .invalid = parser.parse(input) else {
            Issue.record("Expected invalid for \(input)")
            return
        }
    }

    @Test(arguments: [("KJFK", "JFK"), ("JFK", "JFK"), ("EGLL", "EGLL")])
    func convertsUSICAOToIATA(input: String, expected: String) {
        #expect(parser.icaoToIata(input) == expected)
    }
}
