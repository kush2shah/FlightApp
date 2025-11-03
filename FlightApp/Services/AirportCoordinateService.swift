//
//  AirportCoordinateService.swift
//  FlightApp
//
//  Created by Kush Shah on 8/20/25.
//

import Foundation
import CoreLocation

struct AirportCoordinate {
    let code: String
    let coordinate: CLLocationCoordinate2D
    let name: String
}

// JSON structure from airports.json
private struct AirportData: Codable {
    let iata: String?
    let icao: String?
    let lon: String?
    let lat: String?
    let name: String?
    let status: Int?

    enum CodingKeys: String, CodingKey {
        case iata, icao, lon, lat, name, status
    }
}

class AirportCoordinateService {
    static let shared = AirportCoordinateService()

    private var airportCoordinates: [String: AirportCoordinate] = [:]

    private init() {
        loadAirportDatabase()
    }

    private func loadAirportDatabase() {
        guard let url = Bundle.main.url(forResource: "airports", withExtension: "json") else {
            print("⚠️ Could not find airports.json in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let airports = try JSONDecoder().decode([AirportData].self, from: data)

            // Build lookup dictionary from IATA and ICAO codes
            for airport in airports {
                // Only include active airports with valid coordinates and name
                guard airport.status == 1,
                      let name = airport.name,
                      !name.isEmpty,
                      let latString = airport.lat,
                      let lonString = airport.lon,
                      let latitude = Double(latString),
                      let longitude = Double(lonString) else {
                    continue
                }

                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

                // Add entry for IATA code
                if let iata = airport.iata, !iata.isEmpty {
                    let airportCoord = AirportCoordinate(
                        code: iata,
                        coordinate: coordinate,
                        name: name
                    )
                    airportCoordinates[iata.uppercased()] = airportCoord
                }

                // Add entry for ICAO code
                if let icao = airport.icao, !icao.isEmpty {
                    let airportCoord = AirportCoordinate(
                        code: icao,
                        coordinate: coordinate,
                        name: name
                    )
                    airportCoordinates[icao.uppercased()] = airportCoord
                }
            }

            print("✅ Loaded \(airportCoordinates.count) airport coordinates from database")
        } catch {
            print("❌ Failed to load airports database: \(error)")
        }
    }

    func getCoordinate(for airportCode: String) -> AirportCoordinate? {
        return airportCoordinates[airportCode.uppercased()]
    }

    func getAllKnownAirports() -> [AirportCoordinate] {
        return Array(airportCoordinates.values)
    }
}
