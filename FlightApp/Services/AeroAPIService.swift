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
    
    func getFlightInfo(_ flightNumber: String) async throws -> AeroAPIResponse {
        // Clean the flight number
        let cleanedNumber = flightNumber.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create URL with query parameters
        var urlComponents = URLComponents(string: "\(baseURL)/flights/\(cleanedNumber)")
        urlComponents?.queryItems = [
            URLQueryItem(name: "max_pages", value: "1")
        ]
        
        guard let url = urlComponents?.url else {
            throw AeroAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-apikey")
        
        print("🔍 Fetching flight info for: \(cleanedNumber)")
        
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
                case 404:
                    throw AeroAPIError.noFlightsFound
                case 429:
                    throw AeroAPIError.rateLimitExceeded
                default:
                    throw AeroAPIError.serverError(httpResponse.statusCode)
                }
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let flightResponse = try decoder.decode(AeroAPIResponse.self, from: data)
            
            if flightResponse.flights.isEmpty {
                throw AeroAPIError.noFlightsFound
            }
            
            return flightResponse
            
        } catch let decodingError as DecodingError {
            print("❌ Decoding Error: \(decodingError)")
            throw AeroAPIError.decodingError
        } catch {
            if let aeroError = error as? AeroAPIError {
                throw aeroError
            }
            throw AeroAPIError.networkError(error)
        }
    }
}
