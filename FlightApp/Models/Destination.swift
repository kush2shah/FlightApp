//
//  Destination.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import Foundation

struct Destination: Identifiable {
    let id: UUID
    let city: String
    let country: String
    let pointsRequired: Int
    let availableFlights: Int
    
    init(id: UUID = UUID(), city: String, country: String, pointsRequired: Int, availableFlights: Int) {
        self.id = id
        self.city = city
        self.country = country
        self.pointsRequired = pointsRequired
        self.availableFlights = availableFlights
    }
}
