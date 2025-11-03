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
    static let featuredRoute = PopularRoute(
        flightNumber: "AA1",
        origin: "New York",
        destination: "Los Angeles",
        originCode: "JFK",
        destinationCode: "LAX",
        originFlag: "🇺🇸",
        destinationFlag: "🇺🇸"
    )
    
    static let routes: [PopularRoute] = [
        // Ultra-long haul flagship routes
        // Note: Only including flights without codeshare/shared flight numbers
        // to ensure users see the exact flight they select
        PopularRoute(
            flightNumber: "SQ22",
            origin: "New York",
            destination: "Singapore",
            originCode: "JFK",
            destinationCode: "SIN",
            originFlag: "🇺🇸",
            destinationFlag: "🇸🇬"
        ),
        PopularRoute(
            flightNumber: "QF12",
            origin: "Sydney",
            destination: "Los Angeles",
            originCode: "SYD",
            destinationCode: "LAX",
            originFlag: "🇦🇺",
            destinationFlag: "🇺🇸"
        ),
        PopularRoute(
            flightNumber: "EK201",
            origin: "Dubai",
            destination: "New York",
            originCode: "DXB",
            destinationCode: "JFK",
            originFlag: "🇦🇪",
            destinationFlag: "🇺🇸"
        ),
        PopularRoute(
            flightNumber: "BA1",
            origin: "London",
            destination: "New York",
            originCode: "LHR",
            destinationCode: "JFK",
            originFlag: "🇬🇧",
            destinationFlag: "🇺🇸"
        ),
        PopularRoute(
            flightNumber: "UA14",
            origin: "San Francisco",
            destination: "London",
            originCode: "SFO",
            destinationCode: "LHR",
            originFlag: "🇺🇸",
            destinationFlag: "🇬🇧"
        ),
        PopularRoute(
            flightNumber: "LH400",
            origin: "Frankfurt",
            destination: "New York",
            originCode: "FRA",
            destinationCode: "JFK",
            originFlag: "🇩🇪",
            destinationFlag: "🇺🇸"
        ),
        PopularRoute(
            flightNumber: "AF6",
            origin: "Paris",
            destination: "New York",
            originCode: "CDG",
            destinationCode: "JFK",
            originFlag: "🇫🇷",
            destinationFlag: "🇺🇸"
        ),
        PopularRoute(
            flightNumber: "NH9",
            origin: "Tokyo",
            destination: "New York",
            originCode: "HND",
            destinationCode: "JFK",
            originFlag: "🇯🇵",
            destinationFlag: "🇺🇸"
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
            flightNumber: "AA2",
            origin: "New York",
            destination: "Los Angeles",
            originCode: "JFK",
            destinationCode: "LAX",
            originFlag: "🇺🇸",
            destinationFlag: "🇺🇸"
        )
    ]
}
