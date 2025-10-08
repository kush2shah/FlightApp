//
//  AircraftTypeService.swift
//  FlightApp
//
//  Created by Kush Shah on 10/7/25.
//

import Foundation

class AircraftTypeService {
    static let shared = AircraftTypeService()

    private init() {}

    // Map ICAO aircraft codes to readable names
    private let aircraftTypes: [String: String] = [
        // Boeing 737 Family
        "B737": "Boeing 737",
        "B738": "Boeing 737-800",
        "B739": "Boeing 737-900",
        "B37M": "Boeing 737 MAX 7",
        "B38M": "Boeing 737 MAX 8",
        "B39M": "Boeing 737 MAX 9",
        "B3XM": "Boeing 737 MAX 10",
        "B733": "Boeing 737-300",
        "B734": "Boeing 737-400",
        "B735": "Boeing 737-500",
        "B736": "Boeing 737-600",
        "B73G": "Boeing 737-700",

        // Boeing 747 Family
        "B744": "Boeing 747-400",
        "B748": "Boeing 747-8",

        // Boeing 757
        "B752": "Boeing 757-200",
        "B753": "Boeing 757-300",

        // Boeing 767
        "B762": "Boeing 767-200",
        "B763": "Boeing 767-300",
        "B764": "Boeing 767-400",

        // Boeing 777 Family
        "B772": "Boeing 777-200",
        "B77L": "Boeing 777-200LR",
        "B773": "Boeing 777-300",
        "B77W": "Boeing 777-300ER",
        "B778": "Boeing 777-8",
        "B779": "Boeing 777-9",

        // Boeing 787 Dreamliner
        "B788": "Boeing 787-8",
        "B789": "Boeing 787-9",
        "B78X": "Boeing 787-10",

        // Airbus A320 Family
        "A318": "Airbus A318",
        "A319": "Airbus A319",
        "A320": "Airbus A320",
        "A321": "Airbus A321",
        "A19N": "Airbus A319neo",
        "A20N": "Airbus A320neo",
        "A21N": "Airbus A321neo",
        "A21X": "Airbus A321XLR",

        // Airbus A330 Family
        "A332": "Airbus A330-200",
        "A333": "Airbus A330-300",
        "A339": "Airbus A330-900neo",

        // Airbus A350 Family
        "A359": "Airbus A350-900",
        "A35K": "Airbus A350-1000",

        // Airbus A380
        "A388": "Airbus A380",

        // Embraer Regional Jets
        "E170": "Embraer 170",
        "E175": "Embraer 175",
        "E190": "Embraer 190",
        "E195": "Embraer 195",
        "E290": "Embraer E190-E2",
        "E295": "Embraer E195-E2",

        // Bombardier/Airbus Canada
        "CRJ2": "Bombardier CRJ-200",
        "CRJ7": "Bombardier CRJ-700",
        "CRJ9": "Bombardier CRJ-900",
        "CRJX": "Bombardier CRJ-1000",
        "CS1": "Airbus A220-100",
        "CS3": "Airbus A220-300",
        "BCS1": "Airbus A220-100",
        "BCS3": "Airbus A220-300",

        // ATR Regional Aircraft
        "AT72": "ATR 72",
        "AT76": "ATR 72-600",
        "AT75": "ATR 72-500",
        "AT43": "ATR 42-300",
        "AT45": "ATR 42-500",

        // De Havilland Canada
        "DH8A": "Dash 8-100",
        "DH8B": "Dash 8-200",
        "DH8C": "Dash 8-300",
        "DH8D": "Dash 8-400",

        // McDonnell Douglas
        "MD11": "McDonnell Douglas MD-11",
        "MD82": "McDonnell Douglas MD-82",
        "MD83": "McDonnell Douglas MD-83",
        "MD88": "McDonnell Douglas MD-88",
        "MD90": "McDonnell Douglas MD-90"
    ]

    /// Convert ICAO aircraft code to readable name
    func getAircraftName(from code: String?) -> String? {
        guard let code = code?.uppercased() else { return nil }
        return aircraftTypes[code] ?? code // Return code if no mapping found
    }
}
