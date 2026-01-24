//
//  InsightsViewModel.swift
//  FlightApp
//
//  Manages Claude-powered insights with hybrid caching approach
//

import Foundation
import SwiftUI

@MainActor
class InsightsViewModel: ObservableObject {
    @Published var insight: String?
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private let apiService = ClaudeAPIService.shared
    private let cacheService = InsightsCacheService.shared

    /// Generate insight with hybrid approach:
    /// 1. Check cache first
    /// 2. If cached, show immediately
    /// 3. If not cached, load and cache result
    func loadInsight(type: InsightType, context: InsightContext, forceRefresh: Bool = false) async {
        // Check cache first unless force refresh
        if !forceRefresh, let cached = cacheService.getCachedInsight(type: type, context: context) {
            self.insight = cached
            return
        }

        // Generate new insight
        isLoading = true
        error = nil

        do {
            let generatedInsight = try await apiService.generateInsight(type: type, context: context)

            // Cache the result
            cacheService.cacheInsight(generatedInsight, type: type, context: context)

            self.insight = generatedInsight
        } catch {
            self.error = error
            print("Failed to generate insight: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Refresh the current insight
    func refresh(type: InsightType, context: InsightContext) async {
        await loadInsight(type: type, context: context, forceRefresh: true)
    }

    /// Clear the current insight
    func clear() {
        insight = nil
        error = nil
        isLoading = false
    }
}
