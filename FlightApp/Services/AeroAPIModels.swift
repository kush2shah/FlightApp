//
//  AeroAPIModels.swift
//  FlightApp
//
//  Created by Kush Shah on 2/11/25.
//

import Foundation

// MARK: - API Response Types
struct AeroAPIResponse: Codable {
    let flights: [AeroFlight]
    let links: AeroLinks?
    let numPages: Int
    
    enum CodingKeys: String, CodingKey {
        case flights
        case links
        case numPages = "num_pages"
    }
}

struct AeroLinks: Codable {
    let next: String?
}

// MARK: - Flight Model
struct AeroFlight: Codable, Identifiable {
    let id = UUID()
    let ident: String
    let identIcao: String?
    let identIata: String?
    let faFlightId: String
    let operator_: String?
    let operatorIcao: String?
    let operatorIata: String?
    let flightNumber: String?
    let registration: String?
    let atcIdent: String?
    let inboundFaFlightId: String?
    let origin: AeroAirport
    let destination: AeroAirport
    let departureDelay: Int?
    let arrivalDelay: Int?
    let filedEte: Int?
    let progressPercent: Int?
    let status: String
    let aircraftType: String?
    let routeDistance: Int?
    let filedAirspeed: Int?
    let filedAltitude: Int?
    let route: String?
    let baggageClaim: String?
    let gateOrigin: String?
    let gateDestination: String?
    let terminalOrigin: String?
    let terminalDestination: String?
    let flightType: FlightCategory
    let scheduledOut: String?
    let estimatedOut: String?
    let actualOut: String?
    let scheduledOff: String?
    let estimatedOff: String?
    let actualOff: String?
    let scheduledOn: String?
    let estimatedOn: String?
    let actualOn: String?
    let scheduledIn: String?
    let estimatedIn: String?
    let actualIn: String?
    let diverted: Bool
    let cancelled: Bool
    let blocked: Bool
    let positionOnly: Bool
    
    enum CodingKeys: String, CodingKey {
        case ident
        case identIcao = "ident_icao"
        case identIata = "ident_iata"
        case faFlightId = "fa_flight_id"
        case operator_ = "operator"
        case operatorIcao = "operator_icao"
        case operatorIata = "operator_iata"
        case flightNumber = "flight_number"
        case registration
        case atcIdent = "atc_ident"
        case inboundFaFlightId = "inbound_fa_flight_id"
        case origin
        case destination
        case departureDelay = "departure_delay"
        case arrivalDelay = "arrival_delay"
        case filedEte = "filed_ete"
        case progressPercent = "progress_percent"
        case status
        case aircraftType = "aircraft_type"
        case routeDistance = "route_distance"
        case filedAirspeed = "filed_airspeed"
        case filedAltitude = "filed_altitude"
        case route
        case baggageClaim = "baggage_claim"
        case gateOrigin = "gate_origin"
        case gateDestination = "gate_destination"
        case terminalOrigin = "terminal_origin"
        case terminalDestination = "terminal_destination"
        case flightType = "type"
        case scheduledOut = "scheduled_out"
        case estimatedOut = "estimated_out"
        case actualOut = "actual_out"
        case scheduledOff = "scheduled_off"
        case estimatedOff = "estimated_off"
        case actualOff = "actual_off"
        case scheduledOn = "scheduled_on"
        case estimatedOn = "estimated_on"
        case actualOn = "actual_on"
        case scheduledIn = "scheduled_in"
        case estimatedIn = "estimated_in"
        case actualIn = "actual_in"
        case diverted
        case cancelled
        case blocked
        case positionOnly = "position_only"
    }
}

// MARK: - Supporting Types
struct AeroAirport: Codable {
    let code: String
    let codeIcao: String?
    let codeIata: String?
    let timezone: String?
    let name: String?
    let city: String?
    
    enum CodingKeys: String, CodingKey {
        case code
        case codeIcao = "code_icao"
        case codeIata = "code_iata"
        case timezone
        case name
        case city
    }
}

enum FlightCategory: String, Codable {
    case generalAviation = "General_Aviation"
    case airline = "Airline"
}
