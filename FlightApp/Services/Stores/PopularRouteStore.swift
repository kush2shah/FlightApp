//
//  PopularRouteStore.swift
//  FlightApp
//
//  Created by Kush Shah on 2/12/25.
//

import SwiftUI

struct PopularRoute: Identifiable, Hashable {
    let id = UUID()
    let flightNumber: String
    let origin: String
    let destination: String
    let originCode: String
    let destinationCode: String
    let originFlag: String
    let destinationFlag: String
    
    var routeDisplayName: String {
        "\(flightNumber) \(originCode) → \(destinationCode)"
    }
}

struct PopularRouteStore {
    static let routes: [PopularRoute] = [
        PopularRoute(
            flightNumber: "SQ23",
            origin: "New York",
            destination: "Singapore",
            originCode: "JFK",
            destinationCode: "SIN",
            originFlag: "🇺🇸",
            destinationFlag: "🇸🇬"
        ),
        PopularRoute(
            flightNumber: "DL1",
            origin: "New York",
            destination: "London",
            originCode: "JFK",
            destinationCode: "LHR",
            originFlag: "🇺🇸",
            destinationFlag: "🇬🇧"
        ),
        PopularRoute(
            flightNumber: "AF693",
            origin: "Raleigh",
            destination: "Paris",
            originCode: "RDU",
            destinationCode: "CDG",
            originFlag: "🇺🇸",
            destinationFlag: "🇫🇷"
        ),
        PopularRoute(
            flightNumber: "UA60",
            origin: "San Francisco",
            destination: "Melbourne",
            originCode: "SFO",
            destinationCode: "MEL",
            originFlag: "🇺🇸",
            destinationFlag: "🇦🇺"
        ),
        PopularRoute(
            flightNumber: "UA1",
            origin: "San Francisco",
            destination: "Singapore",
            originCode: "SFO",
            destinationCode: "SIN",
            originFlag: "🇺🇸",
            destinationFlag: "🇸🇬"
        ),
        PopularRoute(
            flightNumber: "AA1",
            origin: "New York",
            destination: "Los Angeles",
            originCode: "JFK",
            destinationCode: "LAX",
            originFlag: "🇺🇸",
            destinationFlag: "🇺🇸"
        ),
        PopularRoute(
            flightNumber: "MH387",
            origin: "Shanghai",
            destination: "Kuala Lumpur",
            originCode: "PVG",
            destinationCode: "KUL",
            originFlag: "🇨🇳",
            destinationFlag: "🇲🇾"
        ),
        PopularRoute(
            flightNumber: "BA175",
            origin: "London",
            destination: "New York",
            originCode: "LHR",
            destinationCode: "JFK",
            originFlag: "🇬🇧",
            destinationFlag: "🇺🇸"
        ),
        PopularRoute(
            flightNumber: "LH440",
            origin: "Frankfurt",
            destination: "Houston",
            originCode: "FRA",
            destinationCode: "IAH",
            originFlag: "🇩🇪",
            destinationFlag: "🇺🇸"
        ),
        PopularRoute(
            flightNumber: "QF34",
            origin: "Paris",
            destination: "Perth",
            originCode: "CDG",
            destinationCode: "PER",
            originFlag: "🇫🇷",
            destinationFlag: "🇦🇺"
        )
    ]
}
