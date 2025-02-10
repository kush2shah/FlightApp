//
//  AeroAPIService.swift
//  FlightApp
//
//  Created by Kush Shah on 2/9/25.
//

import Foundation

enum AeroAPIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(Error)
}

class AeroAPIService {
    static let shared = AeroAPIService()
    private let baseURL = "https://aeroapi.flightaware.com/aeroapi"
    
    private var apiKey: String {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "AERO_API_KEY") as? String {
            print("📝 Raw API key value: '\(apiKey)'")  // Added quotes to see if we're getting whitespace
            if apiKey.contains("$(AERO_API_KEY)") {
                print("⚠️ Variable substitution failed - still seeing $(AERO_API_KEY)")
            }
            return apiKey
        }
        print("❌ No API key found in Info.plist")
        return ""
    }
    
    func searchFlight(_ flightNumber: String) async throws -> AeroFlightSearchResponse {
        let query = "-idents \(flightNumber)"
        guard let queryEncoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/flights/search?query=\(queryEncoded)&max_pages=1") else {
            throw AeroAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-apikey")
        
        print("🔍 Request URL: \(url)")
        print("🔑 API Key length: \(apiKey.count)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Response Status Code: \(httpResponse.statusCode)")
        }
        
        // Log raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Raw Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AeroAPIError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(AeroFlightSearchResponse.self, from: data)
        } catch {
            print("❌ Decoding Error: \(error)")
            throw AeroAPIError.decodingError
        }
    }
}

// Response models that match the API spec
struct AeroFlightSearchResponse: Codable {
    let flights: [AeroFlight]
    let numPages: Int
    let links: AeroLinks?  // Make links optional
    
    enum CodingKeys: String, CodingKey {
        case flights
        case numPages = "num_pages"
        case links
    }
}

struct AeroLinks: Codable {
    let next: String?  // Make next optional too since it might be null
}

struct AeroFlight: Codable {
    let ident: String
    let identIcao: String?
    let identIata: String?
    let faFlightId: String
    let registration: String?
    let origin: AeroAirport
    let destination: AeroAirport
    let lastPosition: AeroPosition?
    let aircraftType: String?
    let actualOff: String?
    let actualOn: String?
    
    enum CodingKeys: String, CodingKey {
        case ident
        case identIcao = "ident_icao"
        case identIata = "ident_iata"
        case faFlightId = "fa_flight_id"
        case registration
        case origin
        case destination
        case lastPosition = "last_position"
        case aircraftType = "aircraft_type"
        case actualOff = "actual_off"
        case actualOn = "actual_on"
    }
}

struct AeroAirport: Codable {
    let code: String
    let codeIcao: String?
    let codeIata: String?
    let timezone: String
    let name: String
    let city: String
    
    enum CodingKeys: String, CodingKey {
        case code
        case codeIcao = "code_icao"
        case codeIata = "code_iata"
        case timezone
        case name
        case city
    }
}

struct AeroPosition: Codable {
    let altitude: Int
    let groundspeed: Int
    let heading: Int
    let latitude: Double
    let longitude: Double
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case altitude
        case groundspeed
        case heading
        case latitude
        case longitude
        case timestamp
    }
}
