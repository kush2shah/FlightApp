//
//  AirportCoordinateService.swift
//  FlightApp
//
//  Created by Kush Shah on 2/20/25.
//

import Foundation
import CoreLocation

struct AirportCoordinate {
    let code: String
    let coordinate: CLLocationCoordinate2D
    let name: String
}

class AirportCoordinateService {
    static let shared = AirportCoordinateService()
    
    // Sample of major airports - in a real app, this would be a comprehensive database
    private let airportCoordinates: [String: AirportCoordinate] = [
        "JFK": AirportCoordinate(code: "JFK", coordinate: CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781), name: "John F. Kennedy International"),
        "LHR": AirportCoordinate(code: "LHR", coordinate: CLLocationCoordinate2D(latitude: 51.4700, longitude: -0.4543), name: "London Heathrow"),
        "LAX": AirportCoordinate(code: "LAX", coordinate: CLLocationCoordinate2D(latitude: 33.9425, longitude: -118.4081), name: "Los Angeles International"),
        "SFO": AirportCoordinate(code: "SFO", coordinate: CLLocationCoordinate2D(latitude: 37.6213, longitude: -122.3790), name: "San Francisco International"),
        "DFW": AirportCoordinate(code: "DFW", coordinate: CLLocationCoordinate2D(latitude: 32.8998, longitude: -97.0403), name: "Dallas/Fort Worth International"),
        "ORD": AirportCoordinate(code: "ORD", coordinate: CLLocationCoordinate2D(latitude: 41.9742, longitude: -87.9073), name: "Chicago O'Hare International"),
        "CDG": AirportCoordinate(code: "CDG", coordinate: CLLocationCoordinate2D(latitude: 49.0097, longitude: 2.5479), name: "Charles de Gaulle"),
        "NRT": AirportCoordinate(code: "NRT", coordinate: CLLocationCoordinate2D(latitude: 35.7647, longitude: 140.3864), name: "Narita International"),
        "SIN": AirportCoordinate(code: "SIN", coordinate: CLLocationCoordinate2D(latitude: 1.3644, longitude: 103.9915), name: "Singapore Changi"),
        "DXB": AirportCoordinate(code: "DXB", coordinate: CLLocationCoordinate2D(latitude: 25.2532, longitude: 55.3657), name: "Dubai International"),
        "AMS": AirportCoordinate(code: "AMS", coordinate: CLLocationCoordinate2D(latitude: 52.3105, longitude: 4.7683), name: "Amsterdam Schiphol"),
        "FRA": AirportCoordinate(code: "FRA", coordinate: CLLocationCoordinate2D(latitude: 50.0379, longitude: 8.5622), name: "Frankfurt am Main"),
        "HND": AirportCoordinate(code: "HND", coordinate: CLLocationCoordinate2D(latitude: 35.5494, longitude: 139.7798), name: "Tokyo Haneda"),
        "ICN": AirportCoordinate(code: "ICN", coordinate: CLLocationCoordinate2D(latitude: 37.4602, longitude: 126.4407), name: "Seoul Incheon"),
        "BOS": AirportCoordinate(code: "BOS", coordinate: CLLocationCoordinate2D(latitude: 42.3656, longitude: -71.0096), name: "Boston Logan International"),
        "SEA": AirportCoordinate(code: "SEA", coordinate: CLLocationCoordinate2D(latitude: 47.4502, longitude: -122.3088), name: "Seattle-Tacoma International"),
        "MIA": AirportCoordinate(code: "MIA", coordinate: CLLocationCoordinate2D(latitude: 25.7959, longitude: -80.2870), name: "Miami International"),
        "LAS": AirportCoordinate(code: "LAS", coordinate: CLLocationCoordinate2D(latitude: 36.0840, longitude: -115.1537), name: "McCarran International"),
        "PHX": AirportCoordinate(code: "PHX", coordinate: CLLocationCoordinate2D(latitude: 33.4373, longitude: -112.0078), name: "Phoenix Sky Harbor"),
        "DEN": AirportCoordinate(code: "DEN", coordinate: CLLocationCoordinate2D(latitude: 39.8561, longitude: -104.6737), name: "Denver International"),
        "ATL": AirportCoordinate(code: "ATL", coordinate: CLLocationCoordinate2D(latitude: 33.6407, longitude: -84.4277), name: "Hartsfield-Jackson Atlanta"),
        "YYZ": AirportCoordinate(code: "YYZ", coordinate: CLLocationCoordinate2D(latitude: 43.6777, longitude: -79.6248), name: "Toronto Pearson"),
        "MEL": AirportCoordinate(code: "MEL", coordinate: CLLocationCoordinate2D(latitude: -37.6690, longitude: 144.8410), name: "Melbourne Airport"),
        "SYD": AirportCoordinate(code: "SYD", coordinate: CLLocationCoordinate2D(latitude: -33.9399, longitude: 151.1753), name: "Sydney Kingsford Smith"),
        "AKL": AirportCoordinate(code: "AKL", coordinate: CLLocationCoordinate2D(latitude: -37.0082, longitude: 174.7850), name: "Auckland Airport"),
        "PVG": AirportCoordinate(code: "PVG", coordinate: CLLocationCoordinate2D(latitude: 31.1443, longitude: 121.8083), name: "Shanghai Pudong"),
        "KUL": AirportCoordinate(code: "KUL", coordinate: CLLocationCoordinate2D(latitude: 2.7456, longitude: 101.7072), name: "Kuala Lumpur International"),
        "RAK": AirportCoordinate(code: "RAK", coordinate: CLLocationCoordinate2D(latitude: 31.6068, longitude: -8.0363), name: "Marrakesh Menara"),
        "DOH": AirportCoordinate(code: "DOH", coordinate: CLLocationCoordinate2D(latitude: 25.2731, longitude: 51.6081), name: "Hamad International"),
        "PER": AirportCoordinate(code: "PER", coordinate: CLLocationCoordinate2D(latitude: -31.9385, longitude: 115.9672), name: "Perth Airport"),
        "RDU": AirportCoordinate(code: "RDU", coordinate: CLLocationCoordinate2D(latitude: 35.8776, longitude: -78.7875), name: "Raleigh-Durham International")
    ]
    
    func getCoordinate(for airportCode: String) -> AirportCoordinate? {
        return airportCoordinates[airportCode.uppercased()]
    }
    
    func getAllKnownAirports() -> [AirportCoordinate] {
        return Array(airportCoordinates.values)
    }
}