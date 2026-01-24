//
//  InsightsCacheService.swift
//  FlightApp
//
//  Caches Claude-generated insights for the hybrid approach
//

import Foundation

class InsightsCacheService {
    static let shared = InsightsCacheService()

    private let cache = NSCache<NSString, CachedInsight>()
    private let cacheDuration: TimeInterval = 3600 // 1 hour

    private init() {
        cache.countLimit = 100 // Limit to 100 insights
    }

    /// Generate a cache key from insight parameters
    private func cacheKey(type: InsightType, context: InsightContext) -> String {
        var components: [String] = ["\(type)"]

        // Add relevant context to key
        if let origin = context.origin { components.append(origin) }
        if let destination = context.destination { components.append(destination) }
        if let flight = context.flightNumber { components.append(flight) }
        if let aircraft = context.aircraftType { components.append(aircraft) }

        // For award analysis, include programs and miles
        if let awards = context.awardData {
            let awardSummary = awards
                .sorted { $0.miles < $1.miles }
                .map { "\($0.program)-\($0.miles)" }
                .joined(separator: "_")
            components.append(awardSummary)
        }

        return components.joined(separator: ":")
    }

    /// Retrieve cached insight if available and not expired
    func getCachedInsight(type: InsightType, context: InsightContext) -> String? {
        let key = cacheKey(type: type, context: context)

        guard let cached = cache.object(forKey: key as NSString) else {
            return nil
        }

        // Check if expired
        if Date().timeIntervalSince(cached.timestamp) > cacheDuration {
            cache.removeObject(forKey: key as NSString)
            return nil
        }

        return cached.insight
    }

    /// Cache an insight
    func cacheInsight(_ insight: String, type: InsightType, context: InsightContext) {
        let key = cacheKey(type: type, context: context)
        let cached = CachedInsight(insight: insight, timestamp: Date())
        cache.setObject(cached, forKey: key as NSString)
    }

    /// Clear all cached insights
    func clearCache() {
        cache.removeAllObjects()
    }

    /// Clear insights for a specific type
    func clearCache(for type: InsightType) {
        // Note: NSCache doesn't support filtering, so we'd need to track keys separately
        // For now, just clear all - can optimize later if needed
        clearCache()
    }
}

// MARK: - Cached Insight Model

private class CachedInsight {
    let insight: String
    let timestamp: Date

    init(insight: String, timestamp: Date) {
        self.insight = insight
        self.timestamp = timestamp
    }
}
