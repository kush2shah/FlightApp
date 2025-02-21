//
//  AirlineService.swift
//  FlightApp
//
//  Created by Kush Shah on 2/20/25.
//

import Foundation

// Model to represent airline/operator data from API
struct AirlineInfo: Codable {
    let icao: String?
    let iata: String?
    let callsign: String?
    let name: String
    let country: String?
    let location: String?
    let phone: String?
    let shortname: String?
    let url: String?
    let wiki_url: String?
    
    // Convert to our app's AirlineProfile model
    func toAirlineProfile() -> AirlineProfile {
        return AirlineProfile(
            name: name,
            shortName: shortname,
            iataCode: iata,
            icaoCode: icao,
            callsign: callsign,
            country: country,
            location: location,
            website: url
        )
    }
}

struct AirlineInfoResponse: Codable {
    let icao: String?
    let iata: String?
    let callsign: String?
    let name: String
    let country: String?
    let location: String?
    let phone: String?
    let shortname: String?
    let url: String?
    let wiki_url: String?
    let alternatives: [AirlineInfo]?
}

enum AirlineServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(Error)
    case notFound
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL format"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Error processing airline data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .notFound:
            return "Airline information not found"
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        }
    }
}

class AirlineService {
    static let shared = AirlineService()
    private let baseURL = "https://aeroapi.flightaware.com/aeroapi"
    
    private var apiKey: String {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "AERO_API_KEY") as? String {
            return apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        print("❌ No API key found in Info.plist")
        return ""
    }
    
    // Cache to store airline profiles to minimize API calls
    private var airlineCache: [String: AirlineProfile] = [:]
    
    func getAirlineInfo(code: String) async throws -> AirlineProfile {
        // Check cache first
        if let cachedAirline = airlineCache[code] {
            print("🚀 Using cached airline info for \(code)")
            return cachedAirline
        }
        
        // Construct URL for operator endpoint
        guard let url = URL(string: "\(baseURL)/operators/\(code)") else {
            throw AirlineServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-apikey")
        
        print("🔍 Fetching airline info: \(url)")
        
        do {
            let (data, urlResponse) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                throw AirlineServiceError.invalidResponse
            }
            
            print("📡 Response Status Code: \(httpResponse.statusCode)")
            
            // Handle error responses
            guard (200...299).contains(httpResponse.statusCode) else {
                switch httpResponse.statusCode {
                case 404:
                    throw AirlineServiceError.notFound
                default:
                    throw AirlineServiceError.serverError(httpResponse.statusCode)
                }
            }
            
            // Log raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Raw Response: \(responseString)")
            }
            
            let decoder = JSONDecoder()
            
            // Decode the response
            let airlineResponse = try decoder.decode(AirlineInfoResponse.self, from: data)
            
            // Convert to our model
            let airlineProfile = AirlineProfile(
                name: airlineResponse.name,
                shortName: airlineResponse.shortname,
                iataCode: airlineResponse.iata,
                icaoCode: airlineResponse.icao,
                callsign: airlineResponse.callsign,
                country: airlineResponse.country,
                location: airlineResponse.location,
                website: airlineResponse.url
            )
            
            // Cache the result
            airlineCache[code] = airlineProfile
            
            return airlineProfile
        } catch let decodingError as DecodingError {
            print("❌ Decoding Error: \(decodingError)")
            throw AirlineServiceError.decodingError
        } catch let networkError as URLError {
            print("❌ Network Error: \(networkError)")
            throw AirlineServiceError.networkError(networkError)
        } catch {
            print("❌ Unknown Error: \(error)")
            throw error
        }
    }
    
    // Utility method to extract airline code from flight
    func getAirlineCodeFromFlight(_ flight: AeroFlight) -> String? {
        // Prefer ICAO code, then IATA code
        return flight.operatorIcao ?? flight.operatorIata ?? flight.operator_
    }
    
    // Reset cache (useful for debugging or if airline data changes)
    func resetCache() {
        airlineCache.removeAll()
    }
}
