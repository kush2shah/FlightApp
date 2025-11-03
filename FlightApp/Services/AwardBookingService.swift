//
//  AwardBookingService.swift
//  FlightApp
//
//  Created by Claude Code
//

import Foundation

/// Service for generating airline booking URLs for award flights
class AwardBookingService {
    static let shared = AwardBookingService()

    private init() {}

    /// Generate a booking URL for an award flight
    /// - Parameters:
    ///   - airline: Airline IATA code (e.g., "AA", "UA", "DL")
    ///   - origin: Origin airport IATA code
    ///   - destination: Destination airport IATA code
    ///   - date: Travel date
    ///   - cabinClass: Desired cabin class
    /// - Returns: URL to airline booking page, or nil if cannot be generated
    func generateBookingURL(
        airline: String,
        origin: String,
        destination: String,
        date: Date,
        cabinClass: CabinClass
    ) -> URL? {
        let dateString = formatDateForURL(date)
        let upperAirline = airline.uppercased()
        let upperOrigin = origin.uppercased()
        let upperDestination = destination.uppercased()

        // Generate airline-specific URLs
        switch upperAirline {
        case "AA", "AAL": // American Airlines
            return generateAmericanAirlinesURL(
                origin: upperOrigin,
                destination: upperDestination,
                date: dateString,
                cabin: cabinClass
            )

        case "UA", "UAL": // United Airlines
            return generateUnitedAirlinesURL(
                origin: upperOrigin,
                destination: upperDestination,
                date: dateString,
                cabin: cabinClass
            )

        case "DL", "DAL": // Delta Air Lines
            return generateDeltaAirlinesURL(
                origin: upperOrigin,
                destination: upperDestination,
                date: dateString,
                cabin: cabinClass
            )

        case "AS", "ASA": // Alaska Airlines
            return generateAlaskaAirlinesURL(
                origin: upperOrigin,
                destination: upperDestination,
                date: dateString,
                cabin: cabinClass
            )

        case "B6", "JBU": // JetBlue
            return generateJetBlueURL(
                origin: upperOrigin,
                destination: upperDestination,
                date: dateString
            )

        case "WN", "SWA": // Southwest
            return generateSouthwestURL(
                origin: upperOrigin,
                destination: upperDestination,
                date: dateString
            )

        default:
            // Generic fallback: try to construct a generic booking URL
            return generateGenericBookingURL(
                airline: upperAirline,
                origin: upperOrigin,
                destination: upperDestination,
                date: dateString
            )
        }
    }

    // MARK: - Airline-Specific URL Generators

    private func generateAmericanAirlinesURL(
        origin: String,
        destination: String,
        date: String,
        cabin: CabinClass
    ) -> URL? {
        // American Airlines award booking
        var components = URLComponents(string: "https://www.aa.com/booking/find-flights")
        components?.queryItems = [
            URLQueryItem(name: "searchType", value: "Award"),
            URLQueryItem(name: "slices", value: "[\(origin)|\(destination)|\(date)]"),
            URLQueryItem(name: "passengers", value: "1"),
            URLQueryItem(name: "cabin", value: cabin == .first || cabin == .business ? "F" : "Y")
        ]
        return components?.url
    }

    private func generateUnitedAirlinesURL(
        origin: String,
        destination: String,
        date: String,
        cabin: CabinClass
    ) -> URL? {
        // United MileagePlus award search
        var components = URLComponents(string: "https://www.united.com/ual/en/us/flight-search/book-a-flight")
        let cabinCode = cabin == .first || cabin == .business ? "F" : "Y"
        components?.queryItems = [
            URLQueryItem(name: "f", value: origin),
            URLQueryItem(name: "t", value: destination),
            URLQueryItem(name: "d", value: date),
            URLQueryItem(name: "tt", value: "1"), // Trip type: one-way
            URLQueryItem(name: "at", value: "1"), // Award travel
            URLQueryItem(name: "sc", value: "7"), // Passengers
            URLQueryItem(name: "px", value: "1"),
            URLQueryItem(name: "taxng", value: "1"),
            URLQueryItem(name: "cbm", value: cabinCode)
        ]
        return components?.url
    }

    private func generateDeltaAirlinesURL(
        origin: String,
        destination: String,
        date: String,
        cabin: CabinClass
    ) -> URL? {
        // Delta SkyMiles award search
        var components = URLComponents(string: "https://www.delta.com/flight-search/book-a-flight")
        let cabinParam = cabin == .first || cabin == .business ? "BUSINESS" : "MAIN_CABIN"
        components?.queryItems = [
            URLQueryItem(name: "origin", value: origin),
            URLQueryItem(name: "destination", value: destination),
            URLQueryItem(name: "departureDate", value: date),
            URLQueryItem(name: "tripType", value: "ONE_WAY"),
            URLQueryItem(name: "paxCount", value: "1"),
            URLQueryItem(name: "cabinClass", value: cabinParam),
            URLQueryItem(name: "awardTravel", value: "true")
        ]
        return components?.url
    }

    private func generateAlaskaAirlinesURL(
        origin: String,
        destination: String,
        date: String,
        cabin: CabinClass
    ) -> URL? {
        // Alaska Airlines Mileage Plan award search
        // Format: https://www.alaskaair.com/search/results?A=1&O=jfk&D=sin&OD=2025-11-19&OT=Anytime&RT=false&UPG=none&ShoppingMethod=onlineaward&locale=en-us
        var components = URLComponents(string: "https://www.alaskaair.com/search/results")

        // Upgrade preference based on cabin class
        let upgradePref: String
        switch cabin {
        case .first, .business:
            upgradePref = "premium"
        case .premiumEconomy:
            upgradePref = "premium"
        case .economy:
            upgradePref = "none"
        }

        components?.queryItems = [
            URLQueryItem(name: "A", value: "1"), // Number of adults
            URLQueryItem(name: "O", value: origin.lowercased()), // Origin
            URLQueryItem(name: "D", value: destination.lowercased()), // Destination
            URLQueryItem(name: "OD", value: date), // Outbound date (YYYY-MM-DD)
            URLQueryItem(name: "OT", value: "Anytime"), // Outbound time preference
            URLQueryItem(name: "RT", value: "false"), // Round trip = false (one-way)
            URLQueryItem(name: "UPG", value: upgradePref), // Upgrade preference
            URLQueryItem(name: "ShoppingMethod", value: "onlineaward"), // Award search
            URLQueryItem(name: "locale", value: "en-us")
        ]
        return components?.url
    }

    private func generateJetBlueURL(
        origin: String,
        destination: String,
        date: String
    ) -> URL? {
        // JetBlue TrueBlue
        var components = URLComponents(string: "https://www.jetblue.com/booking/flights")
        components?.queryItems = [
            URLQueryItem(name: "from", value: origin),
            URLQueryItem(name: "to", value: destination),
            URLQueryItem(name: "depart", value: date),
            URLQueryItem(name: "isAward", value: "true"),
            URLQueryItem(name: "adults", value: "1")
        ]
        return components?.url
    }

    private func generateSouthwestURL(
        origin: String,
        destination: String,
        date: String
    ) -> URL? {
        // Southwest Rapid Rewards
        var components = URLComponents(string: "https://www.southwest.com/air/booking/select.html")
        components?.queryItems = [
            URLQueryItem(name: "originationAirportCode", value: origin),
            URLQueryItem(name: "destinationAirportCode", value: destination),
            URLQueryItem(name: "outboundDateString", value: date),
            URLQueryItem(name: "adultPassengersCount", value: "1"),
            URLQueryItem(name: "tripType", value: "oneway")
        ]
        return components?.url
    }

    private func generateGenericBookingURL(
        airline: String,
        origin: String,
        destination: String,
        date: String
    ) -> URL? {
        // Fallback: Google Flights with specific airline filter
        var components = URLComponents(string: "https://www.google.com/travel/flights")
        components?.queryItems = [
            URLQueryItem(name: "q", value: "flights from \(origin) to \(destination) on \(date)"),
            URLQueryItem(name: "airline", value: airline)
        ]
        return components?.url
    }

    // MARK: - Helper Methods

    /// Format date as YYYY-MM-DD for URL parameters
    private func formatDateForURL(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// Get airline website homepage as fallback
    /// - Parameter airlineIATA: Airline IATA code
    /// - Returns: URL to airline website, or nil
    func getAirlineWebsite(airlineIATA: String) -> URL? {
        let upperCode = airlineIATA.uppercased()

        let websiteMap: [String: String] = [
            "AA": "https://www.aa.com",
            "AAL": "https://www.aa.com",
            "UA": "https://www.united.com",
            "UAL": "https://www.united.com",
            "DL": "https://www.delta.com",
            "DAL": "https://www.delta.com",
            "AS": "https://www.alaskaair.com",
            "ASA": "https://www.alaskaair.com",
            "B6": "https://www.jetblue.com",
            "JBU": "https://www.jetblue.com",
            "WN": "https://www.southwest.com",
            "SWA": "https://www.southwest.com",
            "F9": "https://www.flyfrontier.com",
            "FFT": "https://www.flyfrontier.com",
            "NK": "https://www.spirit.com",
            "NKS": "https://www.spirit.com"
        ]

        if let website = websiteMap[upperCode] {
            return URL(string: website)
        }

        return nil
    }

    /// Extract airline code from mileage program source
    /// - Parameter source: Source string from API (e.g., "American AAdvantage")
    /// - Returns: Airline IATA code, or nil if not recognized
    func extractAirlineCode(from source: String) -> String? {
        let lowercased = source.lowercased()

        if lowercased.contains("american") || lowercased.contains("aadvantage") {
            return "AA"
        } else if lowercased.contains("united") || lowercased.contains("mileageplus") {
            return "UA"
        } else if lowercased.contains("delta") || lowercased.contains("skymiles") {
            return "DL"
        } else if lowercased.contains("alaska") || lowercased.contains("mileage plan") {
            return "AS"
        } else if lowercased.contains("jetblue") || lowercased.contains("trueblue") {
            return "B6"
        } else if lowercased.contains("southwest") || lowercased.contains("rapid rewards") {
            return "WN"
        }

        return nil
    }
}
