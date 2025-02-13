//
//  AeroAPIService.swift
//  FlightApp
//
//  Created by Kush Shah on 2/9/25.
//

import Foundation

enum AeroAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(Error)
    case noFlightsFound
    case rateLimitExceeded
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL format"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Error processing flight data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noFlightsFound:
            return "No flights found"
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please try again later."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        }
    }
}

class AeroAPIService {
    static let shared = AeroAPIService()
    private let baseURL = "https://aeroapi.flightaware.com/aeroapi"
    
    private var apiKey: String {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "AERO_API_KEY") as? String {
            return apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        print("❌ No API key found in Info.plist")
        return ""
    }
    
    func getFlightInfo(_ flightNumber: String) async throws -> AeroFlight {
        // Clean the flight number
        let cleanedNumber = flightNumber.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try multiple search strategies
        let searchStrategies: [(String) -> URLComponents?] = [
            createPreciseIdentSearch,
            createWildcardIdentSearch,
            createAirlineAndNumberSearch
        ]
        
        for strategy in searchStrategies {
            guard let urlComponents = strategy(cleanedNumber) else {
                continue
            }
            
            guard let url = urlComponents.url else {
                continue
            }
            
            var request = URLRequest(url: url)
            request.setValue(apiKey, forHTTPHeaderField: "x-apikey")
            
            print("🔍 Searching with strategy: \(url)")
            
            do {
                let (data, urlResponse) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = urlResponse as? HTTPURLResponse else {
                    continue
                }
                
                print("📡 Response Status Code: \(httpResponse.statusCode)")
                
                // Log raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📦 Raw Response: \(responseString)")
                }
                
                // Handle error responses
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❗ Search strategy failed with status code: \(httpResponse.statusCode)")
                    continue
                }
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                // Decode the full response first
                let flightResponse = try decoder.decode(AeroFlightResponse.self, from: data)
                
                // Prioritize in-progress flights
                let inProgressFlights = flightResponse.flights.filter { $0.isInProgress }
                
                // Return the first in-progress flight if available
                if let inProgressFlight = inProgressFlights.first {
                    return inProgressFlight
                }
                
                // If no in-progress flights, return the first flight
                if let firstFlight = flightResponse.flights.first {
                    return firstFlight
                }
            } catch {
                print("Search strategy failed: \(error)")
                continue
            }
        }
        
        // If all strategies fail, throw not found error
        throw AeroAPIError.noFlightsFound
    }
    
    // The search strategy methods remain the same
    private func createPreciseIdentSearch(_ flightNumber: String) -> URLComponents? {
        var urlComponents = URLComponents(string: "\(baseURL)/flights/\(flightNumber)")
        return urlComponents
    }
    
    private func createAirlineAndNumberSearch(_ flightNumber: String) -> URLComponents? {
        guard flightNumber.count >= 3 else { return nil }
        
        let airlineCode = String(flightNumber.prefix(2))
        let number = String(flightNumber.dropFirst(2))
        
        var urlComponents = URLComponents(string: "\(baseURL)/flights/search")
        urlComponents?.queryItems = [
            URLQueryItem(name: "query", value: "-airline \(airlineCode) -ident \(number)"),
            URLQueryItem(name: "max_pages", value: "1")
        ]
        return urlComponents
    }
    
    private func createWildcardIdentSearch(_ flightNumber: String) -> URLComponents? {
        var urlComponents = URLComponents(string: "\(baseURL)/flights/search")
        urlComponents?.queryItems = [
            URLQueryItem(name: "query", value: "-ident \(flightNumber)"),
            URLQueryItem(name: "max_pages", value: "1")
        ]
        return urlComponents
    }
}
