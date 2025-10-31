//
//  RequestDeduplicator.swift
//  FlightApp
//
//  Prevents duplicate API requests from being sent simultaneously
//

import Foundation

/// Deduplicates concurrent requests to the same endpoint
actor RequestDeduplicator {
    static let shared = RequestDeduplicator()

    private init() {}

    // Track in-flight requests by unique key
    private var inFlightRequests: [String: Task<Any, Error>] = [:]

    /// Execute a request, reusing in-flight request if one exists for the same key
    func deduplicate<T>(
        key: String,
        request: @escaping () async throws -> T
    ) async throws -> T {
        // Check if there's already an in-flight request for this key
        if let existingTask = inFlightRequests[key] {
            print("♻️ Deduplicating request: \(key)")
            // Wait for the existing request to complete
            let result = try await existingTask.value
            guard let typedResult = result as? T else {
                throw DeduplicationError.typeMismatch
            }
            return typedResult
        }

        // Create new task for this request
        let task = Task<Any, Error> {
            try await request()
        }

        inFlightRequests[key] = task

        // Execute the request
        do {
            let result = try await task.value
            inFlightRequests.removeValue(forKey: key)
            guard let typedResult = result as? T else {
                throw DeduplicationError.typeMismatch
            }
            return typedResult
        } catch {
            inFlightRequests.removeValue(forKey: key)
            throw error
        }
    }

    /// Cancel an in-flight request
    func cancel(key: String) {
        inFlightRequests.removeValue(forKey: key)?.cancel()
    }

    /// Cancel all in-flight requests
    func cancelAll() {
        for (_, task) in inFlightRequests {
            task.cancel()
        }
        inFlightRequests.removeAll()
    }
}

enum DeduplicationError: Error {
    case typeMismatch
}
