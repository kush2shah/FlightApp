//
//  FlightOffer.swift
//  FlightApp
//
//  Amadeus API flight offer data models
//

import Foundation

/// Complete flight offer from Amadeus API
struct FlightOffer: Codable, Identifiable {
    let id: String
    let type: String
    let source: String
    let instantTicketingRequired: Bool?
    let numberOfBookableSeats: Int?
    let itineraries: [Itinerary]
    let price: Price
    let validatingAirlineCodes: [String]
    let travelerPricings: [TravelerPricing]?

    /// Get primary itinerary (outbound)
    var outbound: Itinerary? {
        itineraries.first
    }

    /// Total price as Double
    var totalPrice: Double {
        Double(price.total) ?? 0
    }

    /// Formatted total price (e.g., "$450")
    var formattedTotalPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = price.currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalPrice)) ?? "$\(Int(totalPrice))"
    }

    /// First airline code (for branding)
    var primaryAirline: String? {
        validatingAirlineCodes.first ?? outbound?.segments.first?.carrierCode
    }

    /// Friendly airline name from primary airline code
    var primaryAirlineName: String {
        guard let code = primaryAirline else { return "" }
        return AirlineNameService.shared.getAirlineName(from: code)
    }

    /// Airline booking website URL (no API call - local lookup only)
    var airlineWebsiteUrl: URL? {
        guard let airline = primaryAirline else { return nil }
        return AwardBookingService.shared.getAirlineWebsite(airlineIATA: airline)
    }

    /// Number of stops
    var numberOfStops: Int {
        max(0, (outbound?.segments.count ?? 1) - 1)
    }

    /// Primary cabin class
    var primaryCabin: String? {
        travelerPricings?.first?.fareDetailsBySegment.first?.cabin
    }

    var primaryCabinDisplay: String {
        guard let cabin = primaryCabin else { return "Economy" }
        switch cabin {
        case "FIRST": return "First"
        case "BUSINESS": return "Business"
        case "PREMIUM_ECONOMY": return "Premium Economy"
        case "ECONOMY": return "Economy"
        default: return cabin
        }
    }
}

// MARK: - Itinerary

struct Itinerary: Codable {
    let duration: String  // ISO 8601 duration (e.g., "PT2H30M")
    let segments: [FlightSegment]

    /// Human-readable duration (e.g., "2h 30m")
    var formattedDuration: String {
        duration.replacingOccurrences(of: "PT", with: "")
            .replacingOccurrences(of: "H", with: "h ")
            .replacingOccurrences(of: "M", with: "m")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Departure airport
    var origin: String {
        segments.first?.departure.iataCode ?? ""
    }

    /// Arrival airport
    var destination: String {
        segments.last?.arrival.iataCode ?? ""
    }
}

// MARK: - Flight Segment

struct FlightSegment: Codable, Identifiable {
    let id: String?
    let departure: FlightEndpoint
    let arrival: FlightEndpoint
    let carrierCode: String
    let number: String
    let aircraft: Aircraft
    let duration: String

    var flightNumber: String {
        "\(carrierCode)\(number)"
    }

    /// Friendly airline name from carrier code
    var airlineName: String {
        AirlineNameService.shared.getAirlineName(from: carrierCode)
    }

    var formattedDuration: String {
        duration.replacingOccurrences(of: "PT", with: "")
            .replacingOccurrences(of: "H", with: "h ")
            .replacingOccurrences(of: "M", with: "m")
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Flight Endpoint (Departure/Arrival)

struct FlightEndpoint: Codable {
    let iataCode: String
    let terminal: String?
    let at: String  // ISO 8601 datetime

    var date: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: at) ?? ISO8601DateFormatter().date(from: at)
    }

    var formattedTime: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    var formattedDate: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Aircraft

struct Aircraft: Codable {
    let code: String  // IATA aircraft code
}

// MARK: - Price

struct Price: Codable {
    let currency: String
    let total: String
    let base: String?
    let fees: [Fee]?

    var totalAsDouble: Double {
        Double(total) ?? 0
    }
}

// MARK: - Fee

struct Fee: Codable {
    let amount: String
    let type: String
}

// MARK: - Traveler Pricing

struct TravelerPricing: Codable {
    let travelerId: String
    let fareOption: String
    let travelerType: String
    let price: Price
    let fareDetailsBySegment: [FareDetailsBySegment]
}

// MARK: - Fare Details

struct FareDetailsBySegment: Codable {
    let segmentId: String
    let cabin: String?  // ECONOMY, PREMIUM_ECONOMY, BUSINESS, FIRST
    let fareBasis: String?
    let `class`: String?
}
