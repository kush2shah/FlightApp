//
//  AmadeusAPIService.swift
//  FlightApp
//
//  Service for interacting with Amadeus Self-Service API
//  Handles OAuth2 authentication, flight search, and pricing
//

import Foundation

/// Errors that can occur when using Amadeus API
enum AmadeusError: LocalizedError {
    case invalidResponse
    case authenticationFailed(statusCode: Int)
    case rateLimitExceeded
    case invalidRequest(message: String)
    case notFound
    case serverError(statusCode: Int, message: String?)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .authenticationFailed(let code):
            return "Authentication failed with status \(code)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .notFound:
            return "Resource not found"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        }
    }
}

/// Service for Amadeus API interactions
class AmadeusAPIService {
    static let shared = AmadeusAPIService()

    // MARK: - Configuration

    private let testBaseURL = "https://test.api.amadeus.com"
    private let prodBaseURL = "https://api.amadeus.com"

    private var baseURL: String {
        FeatureFlags.shared.isAmadeusProduction ? prodBaseURL : testBaseURL
    }

    private var clientId: String {
        if FeatureFlags.shared.isAmadeusProduction {
            return Bundle.main.object(forInfoDictionaryKey: "AMADEUS_PROD_KEY") as? String ?? ""
        } else {
            return Bundle.main.object(forInfoDictionaryKey: "AMADEUS_TEST_KEY") as? String ?? ""
        }
    }

    private var clientSecret: String {
        if FeatureFlags.shared.isAmadeusProduction {
            return Bundle.main.object(forInfoDictionaryKey: "AMADEUS_PROD_SECRET") as? String ?? ""
        } else {
            return Bundle.main.object(forInfoDictionaryKey: "AMADEUS_TEST_SECRET") as? String ?? ""
        }
    }

    // MARK: - Authentication

    private var accessToken: String?
    private var tokenExpiresAt: Date?
    private let tokenLock = NSLock()

    // MARK: - Caching

    private let cache = NSCache<NSString, AmadeusCachedResponse>()
    private let cacheExpirySeconds: TimeInterval = 3600 // 1 hour

    // MARK: - Networking

    private let session: URLSession
    private let decoder: JSONDecoder

    // MARK: - Rate Limiting

    private let requestQueue = DispatchQueue(label: "com.flightapp.amadeus", qos: .userInitiated)
    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 0.1 // 10 req/sec max

    private init() {
        // Configure URLSession
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)

        // Configure JSON decoder
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601

        // Configure cache
        self.cache.countLimit = 100
        self.cache.totalCostLimit = 10 * 1024 * 1024 // 10MB
    }

    // MARK: - Public API

    struct FlightSearchParams {
        let originLocationCode: String  // IATA code
        let destinationLocationCode: String
        let departureDate: String      // YYYY-MM-DD
        let adults: Int                // Default: 1
        let travelClass: TravelClass?  // Optional
        let max: Int?                  // Max results (default: 250)

        enum TravelClass: String {
            case economy = "ECONOMY"
            case premiumEconomy = "PREMIUM_ECONOMY"
            case business = "BUSINESS"
            case first = "FIRST"
        }

        func toCacheKey() -> String {
            "\(originLocationCode)-\(destinationLocationCode)-\(departureDate)-\(adults)-\(travelClass?.rawValue ?? "ANY")"
        }
    }

    /// Search for flight offers
    func searchFlightOffers(params: FlightSearchParams) async throws -> [FlightOffer] {
        // Check cache first
        let cacheKey = params.toCacheKey() as NSString
        if let cached = cache.object(forKey: cacheKey),
           Date().timeIntervalSince(cached.timestamp) < cacheExpirySeconds {
            return cached.offers
        }

        // Build request
        let token = try await getAccessToken()
        var components = URLComponents(string: "\(baseURL)/v2/shopping/flight-offers")!
        components.queryItems = [
            URLQueryItem(name: "originLocationCode", value: params.originLocationCode),
            URLQueryItem(name: "destinationLocationCode", value: params.destinationLocationCode),
            URLQueryItem(name: "departureDate", value: params.departureDate),
            URLQueryItem(name: "adults", value: "\(params.adults)"),
            URLQueryItem(name: "currencyCode", value: "USD"),
            URLQueryItem(name: "max", value: "\(params.max ?? 10)")
        ]

        if let travelClass = params.travelClass {
            components.queryItems?.append(URLQueryItem(name: "travelClass", value: travelClass.rawValue))
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Rate limiting
        try await enforceRateLimit()

        // Execute request
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AmadeusError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw try parseError(data: data, statusCode: httpResponse.statusCode)
        }

        // Parse response
        let searchResponse = try decoder.decode(FlightOffersResponse.self, from: data)

        // Cache result
        let cachedResponse = AmadeusCachedResponse(offers: searchResponse.data, timestamp: Date())
        cache.setObject(cachedResponse, forKey: cacheKey)

        return searchResponse.data
    }

    /// Clear all cached responses
    func clearCache() {
        cache.removeAllObjects()
    }

    // MARK: - Authentication Methods

    private func getAccessToken() async throws -> String {
        tokenLock.lock()
        defer { tokenLock.unlock() }

        // Return cached token if still valid
        if let token = accessToken,
           let expiresAt = tokenExpiresAt,
           Date() < expiresAt.addingTimeInterval(-60) { // Refresh 1 min early
            return token
        }

        // Request new token
        return try await requestNewToken()
    }

    private func requestNewToken() async throws -> String {
        let url = URL(string: "\(baseURL)/v1/security/oauth2/token")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = "grant_type=client_credentials&client_id=\(clientId)&client_secret=\(clientSecret)"
        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AmadeusError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw AmadeusError.authenticationFailed(statusCode: httpResponse.statusCode)
        }

        let tokenResponse = try decoder.decode(TokenResponse.self, from: data)

        // Cache token
        self.accessToken = tokenResponse.accessToken
        self.tokenExpiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))

        return tokenResponse.accessToken
    }

    // MARK: - Rate Limiting

    private func enforceRateLimit() async throws {
        try await withCheckedThrowingContinuation { continuation in
            requestQueue.async {
                if let lastRequest = self.lastRequestTime {
                    let elapsed = Date().timeIntervalSince(lastRequest)
                    if elapsed < self.minRequestInterval {
                        let delay = self.minRequestInterval - elapsed
                        Thread.sleep(forTimeInterval: delay)
                    }
                }

                self.lastRequestTime = Date()
                continuation.resume()
            }
        }
    }

    // MARK: - Error Parsing

    private func parseError(data: Data, statusCode: Int) throws -> AmadeusError {
        if let errorResponse = try? decoder.decode(AmadeusErrorResponse.self, from: data) {
            let message = errorResponse.errors.first?.detail ?? errorResponse.errors.first?.title

            switch statusCode {
            case 400:
                return .invalidRequest(message: message ?? "Bad request")
            case 401:
                return .authenticationFailed(statusCode: statusCode)
            case 404:
                return .notFound
            case 429:
                return .rateLimitExceeded
            case 500...599:
                return .serverError(statusCode: statusCode, message: message)
            default:
                return .serverError(statusCode: statusCode, message: message)
            }
        }

        return .serverError(statusCode: statusCode, message: nil)
    }
}

// MARK: - Response Models

private struct TokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String
    // No CodingKeys needed - decoder.keyDecodingStrategy = .convertFromSnakeCase handles it
}

private struct FlightOffersResponse: Codable {
    let data: [FlightOffer]
}

private struct AmadeusErrorResponse: Codable {
    let errors: [AmadeusErrorDetail]
}

private struct AmadeusErrorDetail: Codable {
    let status: Int?
    let code: Int?
    let title: String?
    let detail: String?
}

private class AmadeusCachedResponse: NSObject {
    let offers: [FlightOffer]
    let timestamp: Date

    init(offers: [FlightOffer], timestamp: Date) {
        self.offers = offers
        self.timestamp = timestamp
    }
}
