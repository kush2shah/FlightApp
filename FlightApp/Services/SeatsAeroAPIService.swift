//
//  SeatsAeroAPIService.swift
//  FlightApp
//
//  Created by Kush Shah on 10/7/25.
//

import Foundation

enum SeatsAeroAPIError: LocalizedError {
    case featureDisabled
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(Error)
    case noResultsFound
    case rateLimitExceeded
    case unauthorized
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .featureDisabled:
            return "Award search is currently disabled"
        case .invalidURL:
            return "Invalid URL format"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Error processing award data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noResultsFound:
            return "No award availability found"
        case .rateLimitExceeded:
            return "Award search limit exceeded. Please try again later."
        case .unauthorized:
            return "Award search authentication failed"
        case .serverError(let code):
            return "Award search server error (\(code)). Please try again later."
        }
    }
}

class SeatsAeroAPIService {
    static let shared = SeatsAeroAPIService()
    private let baseURL = "https://seats.aero/partnerapi"

    private var apiKey: String {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "SEATS_AERO_API_KEY") as? String {
            return apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        print("⚠️ No Seats.aero API key found in Info.plist")
        return ""
    }

    /// Search for award availability between airports
    /// - Parameters:
    ///   - origin: Origin airport code (IATA)
    ///   - destination: Destination airport code (IATA)
    ///   - startDate: Optional start date for search range
    ///   - endDate: Optional end date for search range
    ///   - cabins: Optional cabin classes to filter (e.g., "business,first")
    ///   - sources: Optional mileage programs to filter
    /// - Returns: Array of award availability results
    func searchAwards(
        origin: String,
        destination: String,
        startDate: Date? = nil,
        endDate: Date? = nil,
        cabins: String? = nil,
        sources: String? = nil
    ) async throws -> SeatsAeroSearchResponse {
        // Check feature flag
        guard FeatureFlags.shared.canUseSeatsAero else {
            throw SeatsAeroAPIError.featureDisabled
        }

        // Construct URL
        guard var urlComponents = URLComponents(string: "\(baseURL)/search") else {
            throw SeatsAeroAPIError.invalidURL
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var queryItems = [
            URLQueryItem(name: "origin_airport", value: origin.uppercased()),
            URLQueryItem(name: "destination_airport", value: destination.uppercased())
        ]

        if let startDate = startDate {
            queryItems.append(URLQueryItem(name: "start_date", value: formatter.string(from: startDate)))
        }

        if let endDate = endDate {
            queryItems.append(URLQueryItem(name: "end_date", value: formatter.string(from: endDate)))
        }

        if let cabins = cabins {
            queryItems.append(URLQueryItem(name: "cabins", value: cabins))
        }

        if let sources = sources {
            queryItems.append(URLQueryItem(name: "sources", value: sources))
        }

        // Default to business/first class, take top 100 results
        if cabins == nil {
            queryItems.append(URLQueryItem(name: "cabins", value: "business,first"))
        }
        queryItems.append(URLQueryItem(name: "take", value: "100"))
        queryItems.append(URLQueryItem(name: "order_by", value: "lowest_mileage"))

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw SeatsAeroAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "Partner-Authorization")

        print("🎫 Fetching award availability: \(origin) → \(destination)")

        do {
            let (data, urlResponse) = try await URLSession.shared.data(for: request)

            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                throw SeatsAeroAPIError.invalidResponse
            }

            print("📡 Seats.aero Response Status: \(httpResponse.statusCode)")

            // Handle error responses
            guard (200...299).contains(httpResponse.statusCode) else {
                switch httpResponse.statusCode {
                case 401:
                    throw SeatsAeroAPIError.unauthorized
                case 429:
                    throw SeatsAeroAPIError.rateLimitExceeded
                case 400:
                    throw SeatsAeroAPIError.noResultsFound
                default:
                    throw SeatsAeroAPIError.serverError(httpResponse.statusCode)
                }
            }

            let decoder = JSONDecoder()
            let response = try decoder.decode(SeatsAeroSearchResponse.self, from: data)

            print("✅ Found \(response.data.count) award options")

            return response
        } catch let error as SeatsAeroAPIError {
            throw error
        } catch {
            throw SeatsAeroAPIError.networkError(error)
        }
    }
}

// MARK: - Response Models

struct SeatsAeroSearchResponse: Codable {
    let data: [AwardAvailability]
    let count: Int
    let hasMore: Bool
    let cursor: Int?

    enum CodingKeys: String, CodingKey {
        case data, count, hasMore, cursor
    }
}

struct AwardAvailability: Codable, Identifiable {
    let id: String
    let routeID: String
    let date: String
    let source: String

    // Economy availability
    let yAvailable: Bool?
    let yMileageCost: String?
    let yRemainingSeats: Int?

    // Premium Economy availability
    let wAvailable: Bool?
    let wMileageCost: String?
    let wRemainingSeats: Int?

    // Business availability
    let jAvailable: Bool?
    let jMileageCost: String?
    let jRemainingSeats: Int?

    // First Class availability
    let fAvailable: Bool?
    let fMileageCost: String?
    let fRemainingSeats: Int?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case routeID = "RouteID"
        case date = "Date"
        case source = "Source"
        case yAvailable = "YAvailable"
        case yMileageCost = "YMileageCost"
        case yRemainingSeats = "YRemainingSeats"
        case wAvailable = "WAvailable"
        case wMileageCost = "WMileageCost"
        case wRemainingSeats = "WRemainingSeats"
        case jAvailable = "JAvailable"
        case jMileageCost = "JMileageCost"
        case jRemainingSeats = "JRemainingSeats"
        case fAvailable = "FAvailable"
        case fMileageCost = "FMileageCost"
        case fRemainingSeats = "FRemainingSeats"
    }

    /// Get best available cabin class
    func bestAvailableCabin() -> (cabin: String, cost: String, seats: Int)? {
        if let fAvailable = fAvailable, fAvailable, let cost = fMileageCost, let seats = fRemainingSeats {
            return ("First", cost, seats)
        }
        if let jAvailable = jAvailable, jAvailable, let cost = jMileageCost, let seats = jRemainingSeats {
            return ("Business", cost, seats)
        }
        if let wAvailable = wAvailable, wAvailable, let cost = wMileageCost, let seats = wRemainingSeats {
            return ("Premium Economy", cost, seats)
        }
        if let yAvailable = yAvailable, yAvailable, let cost = yMileageCost, let seats = yRemainingSeats {
            return ("Economy", cost, seats)
        }
        return nil
    }
}
