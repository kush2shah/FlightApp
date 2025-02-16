//
//  AeroFlight.swift
//  FlightApp
//
//  Created by Kush Shah on 2/13/25.
//

import Foundation

struct AeroFlightResponse: Codable {
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
    let codeshares: [String]?
    let codeshares_iata: [String]?
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
        case codeshares
        case codeshares_iata
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
    
    var isInProgress: Bool {
        // Explicitly check for in-progress status
        let inProgressStatuses = [
            "en route",
            "in progress",
            "airborne",
            "en route / delayed"
        ]
        
        // Check status first
        if let statusLowercased = status.lowercased() as String?,
           inProgressStatuses.contains(where: { statusLowercased.contains($0) }) {
            return true
        }
        
        // Check flight timing conditions
        guard actualOff != nil, actualOn == nil else {
            return false
        }
        
        // Parse actual off time
        guard let offTimeString = actualOff,
              let dateFormatter = ISO8601DateFormatter().date(from: offTimeString) else {
            return false
        }
        
        // Consider flight in progress if actual off time is in the past
        return dateFormatter < Date()
    }
    
    var accurateProgressPercent: Int {
        // If flight is not in the air, return existing progress or 0
        guard isInProgress else {
            return progressPercent ?? 0
        }
        
        // Calculate progress based on flight timing
        guard let scheduledOff = scheduledOff,
              let scheduledOn = scheduledOn,
              let offTime = ISO8601DateFormatter().date(from: scheduledOff),
              let onTime = ISO8601DateFormatter().date(from: scheduledOn) else {
            return progressPercent ?? 0
        }
        
        let now = Date()
        
        // Calculate total flight duration and elapsed time
        let totalFlightDuration = onTime.timeIntervalSince(offTime)
        let elapsedTime = now.timeIntervalSince(offTime)
        
        // Calculate progress, ensuring it's between 0 and 100
        let calculatedProgress = min(max(Int((elapsedTime / totalFlightDuration) * 100), 0), 100)
        
        return calculatedProgress
    }
}

enum FlightCategory: String, Codable {
    case generalAviation = "General_Aviation"
    case airline = "Airline"
}

struct AeroAirport: Codable {
    let code: String
    let codeIcao: String?
    let codeIata: String?
    let timezone: String?
    let name: String?
    let city: String?
    
    // Prefer IATA code, fallback to ICAO or generic code
    var displayCode: String {
        return codeIata ?? codeIcao ?? code
    }
    
    enum CodingKeys: String, CodingKey {
        case code
        case codeIcao = "code_icao"
        case codeIata = "code_iata"
        case timezone
        case name
        case city
    }
}

struct AeroFlightDetails: Codable {
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
    let type: FlightType
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
        case type
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

enum FlightType: String, Codable {
    case generalAviation = "General_Aviation"
    case airline = "Airline"
}
