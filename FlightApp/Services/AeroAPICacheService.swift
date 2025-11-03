//
//  AeroAPICacheService.swift
//  FlightApp
//
//  Caching layer for AeroAPI responses to reduce API costs
//

import Foundation

/// Cached response with expiration time
struct CachedResponse<T: Codable>: Codable {
    let data: T
    let timestamp: Date
    let ttl: TimeInterval

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > ttl
    }
}

/// Cache service for AeroAPI responses
class AeroAPICacheService {
    static let shared = AeroAPICacheService()

    private init() {}

    // In-memory cache with automatic expiration
    private var cache: [String: Any] = [:]
    private let cacheQueue = DispatchQueue(label: "com.flightapp.aeroapicache", attributes: .concurrent)

    // Cache TTL configurations (in seconds)
    enum CacheTTL {
        static let flightInfo: TimeInterval = 60              // 1 minute ($0.005/call - cheap, keep fresh)
        static let flightRoute: TimeInterval = 30 * 60        // 30 minutes ($0.010/call)
        static let routeFlights: TimeInterval = 10 * 60       // 10 minutes ($0.050/call - EXPENSIVE)
        static let routeInfo: TimeInterval = 24 * 60 * 60     // 24 hours ($0.020/call - very static)
    }

    /// Get cached value if available and not expired
    func get<T: Codable>(_ key: String) -> T? {
        return cacheQueue.sync {
            guard let cached = cache[key] as? CachedResponse<T> else {
                return nil
            }

            if cached.isExpired {
                cache.removeValue(forKey: key)
                return nil
            }

            return cached.data
        }
    }

    /// Get the timestamp when cached data was last fetched
    func getTimestamp(_ key: String) -> Date? {
        return cacheQueue.sync {
            // Use Mirror to access timestamp without type constraints
            guard let cachedValue = cache[key] else {
                return nil
            }

            let mirror = Mirror(reflecting: cachedValue)
            guard let isExpiredField = mirror.children.first(where: { $0.label == "isExpired" }),
                  let isExpired = isExpiredField.value as? Bool,
                  !isExpired,
                  let timestampField = mirror.children.first(where: { $0.label == "timestamp" }),
                  let timestamp = timestampField.value as? Date else {
                return nil
            }

            return timestamp
        }
    }

    /// Store value in cache with TTL
    func set<T: Codable>(_ key: String, value: T, ttl: TimeInterval) {
        cacheQueue.async(flags: .barrier) {
            let cached = CachedResponse(data: value, timestamp: Date(), ttl: ttl)
            self.cache[key] = cached
        }
    }

    /// Remove specific cache entry
    func remove(_ key: String) {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeValue(forKey: key)
        }
    }

    /// Clear all cached data
    func clearAll() {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }

    /// Clear expired entries (call periodically)
    func clearExpired() {
        cacheQueue.async(flags: .barrier) {
            self.cache = self.cache.filter { key, value in
                guard let mirror = Mirror(reflecting: value).children.first(where: { $0.label == "isExpired" }),
                      let isExpired = mirror.value as? Bool else {
                    return true
                }
                return !isExpired
            }
        }
    }

    // MARK: - Cache Key Generators

    static func flightInfoKey(flightNumber: String, startDate: Date?) -> String {
        let dateStr = startDate.map { formatCacheDate($0) } ?? "today"
        return "flight:\(flightNumber.uppercased()):\(dateStr)"
    }

    static func flightRouteKey(faFlightId: String) -> String {
        return "route:\(faFlightId)"
    }

    static func routeFlightsKey(origin: String, destination: String, startDate: Date?, endDate: Date?) -> String {
        let start = startDate.map { formatCacheDate($0) } ?? "now"
        let end = endDate.map { formatCacheDate($0) } ?? "future"
        return "flights:\(origin.uppercased()):\(destination.uppercased()):\(start):\(end)"
    }

    static func routeInfoKey(origin: String, destination: String) -> String {
        return "routeinfo:\(origin.uppercased()):\(destination.uppercased())"
    }

    private static func formatCacheDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }
}
