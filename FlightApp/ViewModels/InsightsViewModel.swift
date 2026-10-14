//
//  InsightsViewModel.swift
//  FlightApp
//
//  Manages Claude-powered insights with hybrid caching approach
//

import Foundation
import SwiftUI
import OSLog

@MainActor
class InsightsViewModel: ObservableObject {
    @Published var insight: String?
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private let generator: InsightGenerating
    private let cache: InsightCaching

    init(
        generator: InsightGenerating = ClaudeAPIService.shared,
        cache: InsightCaching = InsightsCacheService.shared
    ) {
        self.generator = generator
        self.cache = cache
    }

    /// Generate insight with hybrid approach:
    /// 1. Check cache first
    /// 2. If cached, show immediately
    /// 3. If not cached, load and cache result
    func loadInsight(type: InsightType, context: InsightContext, forceRefresh: Bool = false) async {
        // Check cache first unless force refresh
        if !forceRefresh, let cached = cache.getCachedInsight(type: type, context: context) {
            self.insight = cached
            return
        }

        // Generate new insight
        isLoading = true
        error = nil

        do {
            let generatedInsight = try await generator.generateInsight(type: type, context: context)

            // Cache the result
            cache.cacheInsight(generatedInsight, type: type, context: context)

            self.insight = generatedInsight
        } catch {
            self.error = error
            Logger.claude.error("Failed to generate insight: \(error.localizedDescription, privacy: .public)")
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
