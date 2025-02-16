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
    
    func getFlightInfo(_ flightNumber: String) async throws -> [AeroFlight] {
        // Clean the flight number
        let cleanedNumber = flightNumber.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Construct URL for the specific flight endpoint
        guard var urlComponents = URLComponents(string: "\(baseURL)/flights/\(cleanedNumber)") else {
            throw AeroAPIError.invalidURL
        }
        
        // Add parameters for latest flights
        let now = ISO8601DateFormatter().string(from: Date())
        urlComponents.queryItems = [
            URLQueryItem(name: "ident_type", value: "designator"),
            URLQueryItem(name: "max_pages", value: "1")
        ]
        
        guard let url = urlComponents.url else {
            throw AeroAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-apikey")
        
        print("🔍 Fetching flight: \(url)")
        
        do {
            let (data, urlResponse) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                throw AeroAPIError.invalidResponse
            }
            
            print("📡 Response Status Code: \(httpResponse.statusCode)")
            
            // Log raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Raw Response: \(responseString)")
            }
            
            // Handle error responses
            guard (200...299).contains(httpResponse.statusCode) else {
                switch httpResponse.statusCode {
                case 429:
                    throw AeroAPIError.rateLimitExceeded
                case 400:
                    throw AeroAPIError.noFlightsFound
                default:
                    throw AeroAPIError.serverError(httpResponse.statusCode)
                }
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // Decode the response
            let flightResponse = try decoder.decode(AeroFlightResponse.self, from: data)
            
            // Sort flights by priority (in-progress first, then by departure time)
            let sortedFlights = flightResponse.flights.sorted { first, second in
                if first.isInProgress && !second.isInProgress {
                    return true
                }
                if !first.isInProgress && second.isInProgress {
                    return false
                }
                
                // If neither or both are in progress, sort by departure time
                let firstDate = first.scheduledOut.flatMap { ISO8601DateFormatter().date(from: $0) } ?? .distantFuture
                let secondDate = second.scheduledOut.flatMap { ISO8601DateFormatter().date(from: $0) } ?? .distantFuture
                return firstDate < secondDate
            }
            
            if sortedFlights.isEmpty {
                throw AeroAPIError.noFlightsFound
            }
            
            return sortedFlights
            
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            throw AeroAPIError.decodingError
        } catch {
            print("Network error: \(error)")
            throw AeroAPIError.networkError(error)
        }
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
