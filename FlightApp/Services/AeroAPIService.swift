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
    
    func getFlightInfo(_ flightNumber: String, startDate: Date? = nil) async throws -> [AeroFlight] {
        // Clean the flight number - remove all spaces and trim whitespace
        let cleanedNumber = flightNumber.uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")

        // Check cache first
        let cacheKey = AeroAPICacheService.flightInfoKey(flightNumber: cleanedNumber, startDate: startDate)
        if let cached: [AeroFlight] = AeroAPICacheService.shared.get(cacheKey) {
            print("💰 Cache HIT - Saved $0.005: \(cleanedNumber)")
            return cached
        }

        // Deduplicate concurrent requests
        return try await RequestDeduplicator.shared.deduplicate(key: cacheKey) {
            try await self.fetchFlightInfo(cleanedNumber, startDate: startDate, cacheKey: cacheKey)
        }
    }

    private func fetchFlightInfo(_ cleanedNumber: String, startDate: Date?, cacheKey: String) async throws -> [AeroFlight] {
        // Construct URL for the specific flight endpoint
        guard var urlComponents = URLComponents(string: "\(baseURL)/flights/\(cleanedNumber)") else {
            throw AeroAPIError.invalidURL
        }

        // Add parameters for recent flights (today and upcoming, or specific date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let searchDate = formatter.string(from: startDate ?? Date())

        // OPTIMIZATION: Limit to only 3 results to reduce data transfer
        urlComponents.queryItems = [
            URLQueryItem(name: "ident_type", value: "designator"),
            URLQueryItem(name: "max_pages", value: "1"),
            URLQueryItem(name: "start", value: searchDate)
        ]

        guard let url = urlComponents.url else {
            throw AeroAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-apikey")

        print("🔍 API CALL ($0.005) - Fetching flight: \(url)")

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

            // Sort flights by scheduled departure time
            let sortedFlights = flightResponse.flights.sorted { first, second in
                let firstDate = first.scheduledOut.flatMap { ISO8601DateFormatter().date(from: $0) } ?? .distantFuture
                let secondDate = second.scheduledOut.flatMap { ISO8601DateFormatter().date(from: $0) } ?? .distantFuture
                return firstDate < secondDate
            }

            // Find the current/next flight
            let now = Date()
            let currentFlightIndex = sortedFlights.firstIndex { flight in
                guard let scheduledOut = flight.scheduledOut.flatMap({ ISO8601DateFormatter().date(from: $0) }) else {
                    return false
                }

                // If flight is in progress, it's current
                if flight.isInProgress {
                    return true
                }

                // If flight hasn't departed and is within next 6 hours, it's current
                if scheduledOut > now && scheduledOut.timeIntervalSince(now) < 6 * 3600 {
                    return true
                }

                return false
            } ?? 0

            // Get a window of 3 flights centered on the current flight
            let startIndex = max(0, currentFlightIndex - 1)
            let endIndex = min(sortedFlights.count, startIndex + 3)

            let relevantFlights = Array(sortedFlights[startIndex..<endIndex])

            if relevantFlights.isEmpty {
                throw AeroAPIError.noFlightsFound
            }

            // Cache the result
            AeroAPICacheService.shared.set(cacheKey, value: relevantFlights, ttl: AeroAPICacheService.CacheTTL.flightInfo)

            return relevantFlights
        }
    }
    
    func getFlightRoute(_ faFlightId: String) async throws -> AeroRouteResponse {
        // Check cache first
        let cacheKey = AeroAPICacheService.flightRouteKey(faFlightId: faFlightId)
        if let cached: AeroRouteResponse = AeroAPICacheService.shared.get(cacheKey) {
            print("💰 Cache HIT - Saved $0.010: route \(faFlightId)")
            return cached
        }

        // Deduplicate concurrent requests
        return try await RequestDeduplicator.shared.deduplicate(key: cacheKey) {
            try await self.fetchFlightRoute(faFlightId, cacheKey: cacheKey)
        }
    }

    private func fetchFlightRoute(_ faFlightId: String, cacheKey: String) async throws -> AeroRouteResponse {
        // Construct URL for the route endpoint
        guard let url = URL(string: "\(baseURL)/flights/\(faFlightId)/route") else {
            throw AeroAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-apikey")

        print("🗺️ API CALL ($0.010) - Fetching route for flight: \(faFlightId)")

        do {
            let (data, urlResponse) = try await URLSession.shared.data(for: request)

            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                throw AeroAPIError.invalidResponse
            }

            print("📡 Route Response Status Code: \(httpResponse.statusCode)")

            // Handle error responses
            guard (200...299).contains(httpResponse.statusCode) else {
                switch httpResponse.statusCode {
                case 404:
                    print("⚠️ No route available for this flight")
                    // Return empty route response for flights without route data
                    let emptyResponse = AeroRouteResponse(routeDistance: nil, fixes: [])
                    // Cache empty response too (shorter TTL)
                    AeroAPICacheService.shared.set(cacheKey, value: emptyResponse, ttl: 30 * 60)
                    return emptyResponse
                case 429:
                    throw AeroAPIError.rateLimitExceeded
                default:
                    throw AeroAPIError.serverError(httpResponse.statusCode)
                }
            }

            let decoder = JSONDecoder()
            let routeResponse = try decoder.decode(AeroRouteResponse.self, from: data)

            print("🛣️ Successfully decoded route with \(routeResponse.fixes.count) fixes")

            // Cache the result
            AeroAPICacheService.shared.set(cacheKey, value: routeResponse, ttl: AeroAPICacheService.CacheTTL.flightRoute)

            return routeResponse
        }
        catch let error as AeroAPIError {
            throw error
        }
        catch {
            print("❌ Route decoding error: \(error)")
            throw AeroAPIError.decodingError
        }
    }
    
    // MARK: - Route Endpoints

    /// Get flights between two airports
    func getFlightsBetweenAirports(
        origin: String,
        destination: String,
        startDate: Date? = nil,
        endDate: Date? = nil,
        connection: String? = "nonstop"
    ) async throws -> [AeroFlight] {
        let cleanOrigin = origin.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDest = destination.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Check cache first - THIS IS THE MOST EXPENSIVE CALL ($0.050)
        let cacheKey = AeroAPICacheService.routeFlightsKey(
            origin: cleanOrigin,
            destination: cleanDest,
            startDate: startDate,
            endDate: endDate
        )
        if let cached: [AeroFlight] = AeroAPICacheService.shared.get(cacheKey) {
            print("💰 Cache HIT - Saved $0.050 (EXPENSIVE!): \(cleanOrigin)→\(cleanDest)")
            return cached
        }

        // Deduplicate concurrent requests
        return try await RequestDeduplicator.shared.deduplicate(key: cacheKey) {
            try await self.fetchFlightsBetweenAirports(
                cleanOrigin: cleanOrigin,
                cleanDest: cleanDest,
                startDate: startDate,
                endDate: endDate,
                connection: connection,
                cacheKey: cacheKey
            )
        }
    }

    private func fetchFlightsBetweenAirports(
        cleanOrigin: String,
        cleanDest: String,
        startDate: Date?,
        endDate: Date?,
        connection: String?,
        cacheKey: String
    ) async throws -> [AeroFlight] {
        guard var urlComponents = URLComponents(string: "\(baseURL)/airports/\(cleanOrigin)/flights/to/\(cleanDest)") else {
            throw AeroAPIError.invalidURL
        }

        let formatter = ISO8601DateFormatter()
        var queryItems: [URLQueryItem] = []

        if let startDate = startDate {
            queryItems.append(URLQueryItem(name: "start", value: formatter.string(from: startDate)))
        }

        if let endDate = endDate {
            queryItems.append(URLQueryItem(name: "end", value: formatter.string(from: endDate)))
        }

        if let connection = connection {
            queryItems.append(URLQueryItem(name: "connection", value: connection))
        }

        // OPTIMIZATION: Limit to 1 page to reduce costs
        queryItems.append(URLQueryItem(name: "max_pages", value: "1"))

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw AeroAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-apikey")

        print("🛫 API CALL ($0.050 - EXPENSIVE!) - Fetching flights: \(cleanOrigin) → \(cleanDest)")

        do {
            let (data, urlResponse) = try await URLSession.shared.data(for: request)

            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                throw AeroAPIError.invalidResponse
            }

            print("📡 Route Flights Response Status: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                switch httpResponse.statusCode {
                case 429:
                    throw AeroAPIError.rateLimitExceeded
                case 400, 404:
                    throw AeroAPIError.noFlightsFound
                default:
                    throw AeroAPIError.serverError(httpResponse.statusCode)
                }
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let response = try decoder.decode(AeroRouteFlightsResponse.self, from: data)

            // Flatten segments into individual flights
            var allFlights: [AeroFlight] = []
            for flight in response.flights {
                allFlights.append(contentsOf: flight.segments)
            }

            print("✅ Found \(allFlights.count) flights on route")

            // Cache the result - CRITICAL for cost savings on this expensive endpoint
            AeroAPICacheService.shared.set(cacheKey, value: allFlights, ttl: AeroAPICacheService.CacheTTL.routeFlights)

            return allFlights
        } catch let error as AeroAPIError {
            throw error
        } catch {
            print("❌ Route flights error: \(error)")
            throw AeroAPIError.decodingError
        }
    }

    /// Get IFR route information between two airports
    func getRouteInfo(
        origin: String,
        destination: String
    ) async throws -> [IFRRouteInfo] {
        let cleanOrigin = origin.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDest = destination.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Check cache first - Route info is very static, so long TTL
        let cacheKey = AeroAPICacheService.routeInfoKey(origin: cleanOrigin, destination: cleanDest)
        if let cached: [IFRRouteInfo] = AeroAPICacheService.shared.get(cacheKey) {
            print("💰 Cache HIT - Saved $0.020: route info \(cleanOrigin)→\(cleanDest)")
            return cached
        }

        // Deduplicate concurrent requests
        return try await RequestDeduplicator.shared.deduplicate(key: cacheKey) {
            try await self.fetchRouteInfo(cleanOrigin: cleanOrigin, cleanDest: cleanDest, cacheKey: cacheKey)
        }
    }

    private func fetchRouteInfo(cleanOrigin: String, cleanDest: String, cacheKey: String) async throws -> [IFRRouteInfo] {
        guard var urlComponents = URLComponents(string: "\(baseURL)/airports/\(cleanOrigin)/routes/\(cleanDest)") else {
            throw AeroAPIError.invalidURL
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "max_pages", value: "1"),
            URLQueryItem(name: "sort_by", value: "count")
        ]

        guard let url = urlComponents.url else {
            throw AeroAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-apikey")

        print("🗺️ API CALL ($0.020) - Fetching route info: \(cleanOrigin) → \(cleanDest)")

        do {
            let (data, urlResponse) = try await URLSession.shared.data(for: request)

            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                throw AeroAPIError.invalidResponse
            }

            print("📡 Route Info Response Status: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                switch httpResponse.statusCode {
                case 429:
                    throw AeroAPIError.rateLimitExceeded
                case 400, 404:
                    // No route info available, cache empty result
                    let emptyResult: [IFRRouteInfo] = []
                    AeroAPICacheService.shared.set(cacheKey, value: emptyResult, ttl: AeroAPICacheService.CacheTTL.routeInfo)
                    return emptyResult
                default:
                    throw AeroAPIError.serverError(httpResponse.statusCode)
                }
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let response = try decoder.decode(AeroRouteInfoResponse.self, from: data)

            print("✅ Found \(response.routes.count) IFR routes")

            // Cache the result - very static data, long TTL
            AeroAPICacheService.shared.set(cacheKey, value: response.routes, ttl: AeroAPICacheService.CacheTTL.routeInfo)

            return response.routes
        } catch let error as AeroAPIError {
            throw error
        } catch {
            print("❌ Route info error: \(error)")
            throw AeroAPIError.decodingError
        }
    }

    // The search strategy methods remain the same
    private func createPreciseIdentSearch(_ flightNumber: String) -> URLComponents? {
        let urlComponents = URLComponents(string: "\(baseURL)/flights/\(flightNumber)")
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

// MARK: - Route Response Models

struct AeroRouteFlightsResponse: Codable {
    let flights: [RouteFullFlight]
}

struct RouteFullFlight: Codable {
    let segments: [AeroFlight]
}

struct AeroRouteInfoResponse: Codable {
    let routes: [IFRRouteInfo]
}

struct IFRRouteInfo: Codable, Identifiable {
    let route: String
    let count: Int
    let aircraftTypes: [String]
    let filedAltitudeMin: Int
    let filedAltitudeMax: Int
    let lastDepartureTime: String
    let routeDistance: String

    var id: String { route }

    enum CodingKeys: String, CodingKey {
        case route
        case count
        case aircraftTypes = "aircraft_types"
        case filedAltitudeMin = "filed_altitude_min"
        case filedAltitudeMax = "filed_altitude_max"
        case lastDepartureTime = "last_departure_time"
        case routeDistance = "route_distance"
    }
}
