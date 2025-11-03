# AmadeusAPIService Design

## Service Architecture

### File Location
`FlightApp/Services/AmadeusAPIService.swift`

### Class Structure

```swift
import Foundation

/// Service for interacting with Amadeus Self-Service API
/// Handles OAuth2 authentication, flight search, pricing, and analytics
class AmadeusAPIService {
    // MARK: - Singleton
    static let shared = AmadeusAPIService()

    // MARK: - Configuration
    private let testBaseURL = "https://test.api.amadeus.com"
    private let prodBaseURL = "https://api.amadeus.com"

    private var baseURL: String {
        FeatureFlags.shared.isAmadeusProduction ? prodBaseURL : testBaseURL
    }

    private var clientId: String {
        FeatureFlags.shared.isAmadeusProduction
            ? Config.amadeusProductionKey
            : Config.amadeusTestKey
    }

    private var clientSecret: String {
        FeatureFlags.shared.isAmadeusProduction
            ? Config.amadeusProductionSecret
            : Config.amadeusTestSecret
    }

    // MARK: - Authentication
    private var accessToken: String?
    private var tokenExpiresAt: Date?
    private let tokenLock = NSLock()

    // MARK: - Caching
    private let cache = NSCache<NSString, CachedResponse>()
    private let cacheExpirySeconds: TimeInterval = 3600 // 1 hour

    // MARK: - Networking
    private let session: URLSession
    private let decoder: JSONDecoder

    // MARK: - Rate Limiting
    private let requestQueue = DispatchQueue(label: "com.flightapp.amadeus", qos: .userInitiated)
    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 0.1 // 10 req/sec max

    private init() {
        // Configure URLSession with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)

        // Configure JSON decoder for Amadeus response format
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601

        // Configure cache
        self.cache.countLimit = 100 // Max 100 cached responses
        self.cache.totalCostLimit = 10 * 1024 * 1024 // 10MB
    }
}
```

## Authentication Flow

### OAuth2 Client Credentials

Amadeus uses OAuth2 client credentials grant for authentication:

```swift
// MARK: - Authentication Methods

extension AmadeusAPIService {

    /// Get valid access token, refreshing if necessary
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

    /// Request new OAuth2 token from Amadeus
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
}

// MARK: - Token Response Model

private struct TokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}
```

## Core API Methods

### Flight Offers Search

```swift
// MARK: - Flight Search

extension AmadeusAPIService {

    struct FlightSearchParams {
        let originLocationCode: String  // IATA code (e.g., "JFK")
        let destinationLocationCode: String
        let departureDate: String      // YYYY-MM-DD format
        let returnDate: String?        // Optional for round-trip
        let adults: Int                // 1-9
        let children: Int?             // 0-9
        let infants: Int?              // 0-9
        let travelClass: TravelClass?  // ECONOMY, PREMIUM_ECONOMY, BUSINESS, FIRST
        let currencyCode: String?      // Default: USD
        let max: Int?                  // Max results (1-250, default: 250)

        enum TravelClass: String, Codable {
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
        components.queryItems = params.toQueryItems()

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
        let cachedResponse = CachedResponse(offers: searchResponse.data, timestamp: Date())
        cache.setObject(cachedResponse, forKey: cacheKey)

        return searchResponse.data
    }
}

// MARK: - Helper Extensions

private extension AmadeusAPIService.FlightSearchParams {
    func toQueryItems() -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "originLocationCode", value: originLocationCode),
            URLQueryItem(name: "destinationLocationCode", value: destinationLocationCode),
            URLQueryItem(name: "departureDate", value: departureDate),
            URLQueryItem(name: "adults", value: "\(adults)")
        ]

        if let returnDate = returnDate {
            items.append(URLQueryItem(name: "returnDate", value: returnDate))
        }
        if let children = children {
            items.append(URLQueryItem(name: "children", value: "\(children)"))
        }
        if let infants = infants {
            items.append(URLQueryItem(name: "infants", value: "\(infants)"))
        }
        if let travelClass = travelClass {
            items.append(URLQueryItem(name: "travelClass", value: travelClass.rawValue))
        }
        if let currencyCode = currencyCode {
            items.append(URLQueryItem(name: "currencyCode", value: currencyCode))
        }
        if let max = max {
            items.append(URLQueryItem(name: "max", value: "\(max)"))
        }

        return items
    }
}

private struct FlightOffersResponse: Codable {
    let data: [FlightOffer]
    let meta: Meta?
    let dictionaries: Dictionaries?

    struct Meta: Codable {
        let count: Int
    }

    struct Dictionaries: Codable {
        let carriers: [String: String]?
        let aircraft: [String: String]?
    }
}
```

### Price Metrics

```swift
// MARK: - Price Analytics

extension AmadeusAPIService {

    struct PriceMetricsParams {
        let originIataCode: String
        let destinationIataCode: String
        let departureDate: String  // YYYY-MM-DD
        let currencyCode: String?  // Default: USD

        func toCacheKey() -> String {
            "metrics-\(originIataCode)-\(destinationIataCode)-\(departureDate)"
        }
    }

    /// Get historical price metrics for a route
    func getPriceMetrics(params: PriceMetricsParams) async throws -> PriceMetrics {
        // Check cache
        let cacheKey = params.toCacheKey() as NSString
        if let cached = cache.object(forKey: cacheKey) as? CachedMetrics,
           Date().timeIntervalSince(cached.timestamp) < cacheExpirySeconds {
            return cached.metrics
        }

        // Build request
        let token = try await getAccessToken()
        var components = URLComponents(string: "\(baseURL)/v1/analytics/itinerary-price-metrics")!
        components.queryItems = [
            URLQueryItem(name: "originIataCode", value: params.originIataCode),
            URLQueryItem(name: "destinationIataCode", value: params.destinationIataCode),
            URLQueryItem(name: "departureDate", value: params.departureDate)
        ]

        if let currencyCode = params.currencyCode {
            components.queryItems?.append(URLQueryItem(name: "currencyCode", value: currencyCode))
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        try await enforceRateLimit()

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AmadeusError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw try parseError(data: data, statusCode: httpResponse.statusCode)
        }

        let metricsResponse = try decoder.decode(PriceMetricsResponse.self, from: data)

        // Cache result
        let cached = CachedMetrics(metrics: metricsResponse.data.first!, timestamp: Date())
        cache.setObject(cached as AnyObject, forKey: cacheKey)

        return metricsResponse.data.first!
    }
}

private struct PriceMetricsResponse: Codable {
    let data: [PriceMetrics]
}
```

## Rate Limiting

```swift
// MARK: - Rate Limiting

extension AmadeusAPIService {

    private func enforceRateLimit() async throws {
        return try await withCheckedThrowingContinuation { continuation in
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
}
```

## Error Handling

```swift
// MARK: - Error Types

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

// MARK: - Error Parsing

extension AmadeusAPIService {

    private func parseError(data: Data, statusCode: Int) throws -> AmadeusError {
        // Try to parse Amadeus error response
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

        // Fallback to generic error
        return .serverError(statusCode: statusCode, message: nil)
    }
}

private struct AmadeusErrorResponse: Codable {
    let errors: [AmadeusErrorDetail]
}

private struct AmadeusErrorDetail: Codable {
    let status: Int?
    let code: Int?
    let title: String?
    let detail: String?
    let source: ErrorSource?

    struct ErrorSource: Codable {
        let parameter: String?
        let pointer: String?
    }
}
```

## Caching

```swift
// MARK: - Cache Models

private class CachedResponse: NSObject {
    let offers: [FlightOffer]
    let timestamp: Date

    init(offers: [FlightOffer], timestamp: Date) {
        self.offers = offers
        self.timestamp = timestamp
    }
}

private class CachedMetrics: NSObject {
    let metrics: PriceMetrics
    let timestamp: Date

    init(metrics: PriceMetrics, timestamp: Date) {
        self.metrics = metrics
        self.timestamp = timestamp
    }
}

// MARK: - Cache Management

extension AmadeusAPIService {

    /// Clear all cached responses
    func clearCache() {
        cache.removeAllObjects()
    }

    /// Clear cache for specific route
    func clearCache(for origin: String, destination: String) {
        let prefix = "\(origin)-\(destination)"
        cache.removeAllObjects() // NSCache doesn't support prefix removal
    }
}
```

## Testing Support

```swift
// MARK: - Testing

#if DEBUG
extension AmadeusAPIService {

    /// Force token refresh (for testing)
    func forceTokenRefresh() async throws {
        tokenLock.lock()
        accessToken = nil
        tokenExpiresAt = nil
        tokenLock.unlock()
        _ = try await getAccessToken()
    }

    /// Get current cache size (for debugging)
    var cacheCount: Int {
        // NSCache doesn't expose count directly
        return 0 // Would need custom tracking
    }
}
#endif
```

## Usage Examples

```swift
// Example 1: Simple one-way search
let params = AmadeusAPIService.FlightSearchParams(
    originLocationCode: "JFK",
    destinationLocationCode: "LAX",
    departureDate: "2025-06-15",
    returnDate: nil,
    adults: 1,
    children: nil,
    infants: nil,
    travelClass: .economy,
    currencyCode: "USD",
    max: 10
)

let offers = try await AmadeusAPIService.shared.searchFlightOffers(params: params)

// Example 2: Round-trip business class
let roundTripParams = AmadeusAPIService.FlightSearchParams(
    originLocationCode: "SFO",
    destinationLocationCode: "NRT",
    departureDate: "2025-07-01",
    returnDate: "2025-07-15",
    adults: 2,
    children: nil,
    infants: nil,
    travelClass: .business,
    currencyCode: "USD",
    max: 20
)

let businessOffers = try await AmadeusAPIService.shared.searchFlightOffers(params: roundTripParams)

// Example 3: Get price metrics
let metricsParams = AmadeusAPIService.PriceMetricsParams(
    originIataCode: "LAX",
    destinationIataCode: "SYD",
    departureDate: "2025-08-10",
    currencyCode: "USD"
)

let metrics = try await AmadeusAPIService.shared.getPriceMetrics(params: metricsParams)
print("Quartile ranking: \(metrics.quartileRanking)")
```

## Performance Considerations

### Memory Management
- NSCache automatically evicts under memory pressure
- LRU eviction for old entries
- 100 entry limit, 10MB total size limit

### Network Optimization
- Token cached for ~1 hour (until 1 min before expiry)
- Response caching reduces duplicate requests
- Rate limiting prevents API throttling

### Concurrency
- All methods are async/await compatible
- Thread-safe token management with NSLock
- Serial queue for rate limiting

## Future Enhancements

1. **Persistent Cache**: Save to disk for offline viewing
2. **Request Deduplication**: Prevent duplicate in-flight requests
3. **Retry Logic**: Exponential backoff for failed requests
4. **Analytics**: Track API usage and costs
5. **Mock Mode**: Testing without API calls
6. **Batch Requests**: Combine multiple searches efficiently
