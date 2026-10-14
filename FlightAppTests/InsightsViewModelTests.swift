//
//  InsightsViewModelTests.swift
//  FlightAppTests
//

import Testing
@testable import FlightApp

@MainActor
struct InsightsViewModelTests {
    let generator = FakeInsightGenerator()
    let cache = FakeInsightCache()
    let context = InsightContext(origin: "JFK", destination: "LHR")

    var viewModel: InsightsViewModel {
        InsightsViewModel(generator: generator, cache: cache)
    }

    @Test func usesCachedInsightWithoutCallingClaude() async {
        cache.cacheInsight("Cached", type: .routeContext, context: context)
        let viewModel = viewModel

        await viewModel.loadInsight(type: .routeContext, context: context)

        #expect(viewModel.insight == "Cached")
        #expect(generator.callCount == 0)
    }

    @Test func generatesAndCachesOnMiss() async {
        generator.result = .success("Fresh")
        let viewModel = viewModel

        await viewModel.loadInsight(type: .routeContext, context: context)

        #expect(viewModel.insight == "Fresh")
        #expect(!viewModel.isLoading)
        #expect(cache.getCachedInsight(type: .routeContext, context: context) == "Fresh")
    }

    @Test func refreshBypassesCache() async {
        cache.cacheInsight("Stale", type: .routeContext, context: context)
        generator.result = .success("Fresh")
        let viewModel = viewModel

        await viewModel.refresh(type: .routeContext, context: context)

        #expect(viewModel.insight == "Fresh")
        #expect(generator.callCount == 1)
    }

    @Test func recordsErrorsWithoutCaching() async {
        generator.result = .failure(ClaudeAPIError.missingAPIKey)
        let viewModel = viewModel

        await viewModel.loadInsight(type: .routeContext, context: context)

        #expect(viewModel.insight == nil)
        #expect(viewModel.error != nil)
        #expect(!viewModel.isLoading)
        #expect(cache.stored.isEmpty)
    }
}
