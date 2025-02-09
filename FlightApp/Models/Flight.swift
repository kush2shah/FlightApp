//
//  Flight.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import Foundation

struct Flight: Identifiable {
    let id: UUID
    let flightNumber: String
    let origin: String
    let destination: String
    let departureTime: Date
    let arrivalTime: Date
    let airline: String
    
    init(id: UUID = UUID(), flightNumber: String, origin: String, destination: String, departureTime: Date, arrivalTime: Date, airline: String) {
        self.id = id
        self.flightNumber = flightNumber
        self.origin = origin
        self.destination = destination
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
        self.airline = airline
    }
}
