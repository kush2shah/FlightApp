//
//  Fixtures.swift
//  FlightAppTests
//
//  Builders for API models. They decode JSON, the same way production does,
//  so fixtures stay in sync with the models' CodingKeys.
//

import Foundation
@testable import FlightApp

enum Fixtures {
    static func decode<T: Decodable>(_ type: T.Type, _ json: [String: Any]) -> T {
        let data = try! JSONSerialization.data(withJSONObject: json)
        return try! JSONDecoder().decode(T.self, from: data)
    }

    // MARK: AeroAPI

    static func airport(_ code: String, lat: Double? = nil, lon: Double? = nil, city: String? = nil) -> [String: Any] {
        var json: [String: Any] = ["code": code, "code_iata": code]
        if let lat { json["latitude"] = lat }
        if let lon { json["longitude"] = lon }
        if let city { json["city"] = city }
        return json
    }

    static func flight(
        ident: String,
        status: String = "Scheduled",
        scheduledOut: String? = nil,
        operatorIata: String? = nil,
        origin: [String: Any] = airport("JFK"),
        destination: [String: Any] = airport("LHR")
    ) -> AeroFlight {
        var json: [String: Any] = [
            "ident": ident,
            "fa_flight_id": "\(ident)-id",
            "origin": origin,
            "destination": destination,
            "status": status,
            "type": "Airline",
            "diverted": false,
            "cancelled": false,
            "blocked": false,
            "position_only": false
        ]
        if let scheduledOut { json["scheduled_out"] = scheduledOut }
        if let operatorIata { json["operator_iata"] = operatorIata }
        return decode(AeroFlight.self, json)
    }

    // MARK: Seats.aero

    /// Costs are raw API strings, keyed by cabin. A cabin with a cost is marked available.
    static func award(
        id: String,
        source: String = "united",
        date: String = "2026-11-01",
        costs: [CabinClass: String],
        seats: Int = 2
    ) -> AwardAvailability {
        var json: [String: Any] = ["ID": id, "RouteID": "route", "Date": date, "Source": source]
        let prefixes: [CabinClass: String] = [.economy: "Y", .premiumEconomy: "W", .business: "J", .first: "F"]
        for (cabin, cost) in costs {
            let prefix = prefixes[cabin]!
            json["\(prefix)Available"] = true
            json["\(prefix)MileageCost"] = cost
            json["\(prefix)RemainingSeats"] = seats
        }
        return decode(AwardAvailability.self, json)
    }

    // MARK: Amadeus

    static func offer(id: String, duration: String, stops: Int = 0, price: String) -> FlightOffer {
        let segments: [[String: Any]] = (0...stops).map { index in
            [
                "id": "\(id)-\(index)",
                "departure": ["iataCode": "JFK", "at": "2026-11-01T18:00:00"],
                "arrival": ["iataCode": "LHR", "at": "2026-11-02T06:00:00"],
                "carrierCode": "BA",
                "number": "11\(index)",
                "aircraft": ["code": "777"],
                "duration": duration
            ]
        }
        return decode(FlightOffer.self, [
            "id": id,
            "type": "flight-offer",
            "source": "GDS",
            "itineraries": [["duration": duration, "segments": segments]],
            "price": ["currency": "USD", "total": price],
            "validatingAirlineCodes": ["BA"]
        ])
    }
}
