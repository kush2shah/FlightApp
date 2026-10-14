//
//  ClaudeAPIServiceTests.swift
//  FlightAppTests
//

import Foundation
import Testing
@testable import FlightApp

@Suite(.serialized)
struct ClaudeAPIServiceTests {
    let context = InsightContext(origin: "JFK", destination: "LHR")

    func makeService(apiKey: String? = "test-key") -> ClaudeAPIService {
        ClaudeAPIService(apiKey: apiKey, session: StubURLProtocol.makeSession())
    }

    @Test(arguments: [nil, "", "   \n"])
    func missingKeyThrowsInsteadOfCrashing(apiKey: String?) async {
        StubURLProtocol.handler = { _, _ in
            Issue.record("Should not hit the network without a key")
            throw URLError(.badURL)
        }
        let service = makeService(apiKey: apiKey)

        #expect(!service.isConfigured)
        await #expect(throws: ClaudeAPIError.missingAPIKey) {
            try await service.generateInsight(type: .routeContext, context: context)
        }
    }

    @Test func sendsWellFormedRequestAndReturnsText() async throws {
        nonisolated(unsafe) var captured: (request: URLRequest, body: [String: Any])?
        StubURLProtocol.handler = { request, body in
            captured = (request, try JSONSerialization.jsonObject(with: body ?? Data()) as! [String: Any])
            return try StubURLProtocol.respond(status: 200, json: """
            {"content": [{"type": "text", "text": "Great route. "}, {"type": "text", "text": "Book early."}],
             "stop_reason": "end_turn"}
            """)(request, body)
        }

        let text = try await makeService().generateInsight(type: .routeContext, context: context)

        #expect(text == "Great route. Book early.")
        let (request, body) = try #require(captured)
        #expect(request.url == ClaudeAPIService.endpoint)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "test-key")
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == ClaudeAPIService.apiVersion)
        #expect(body["model"] as? String == "claude-haiku-4-5")
        #expect(body["max_tokens"] as? Int == 150)
        #expect((body["system"] as? String)?.isEmpty == false)
        let messages = try #require(body["messages"] as? [[String: Any]])
        #expect(messages.first?["role"] as? String == "user")
    }

    @Test func surfacesAPIErrorMessage() async throws {
        StubURLProtocol.handler = StubURLProtocol.respond(status: 400, json: """
        {"type": "error", "error": {"type": "invalid_request_error", "message": "max_tokens: too large"}}
        """)

        let error = await #expect(throws: ClaudeAPIError.self) {
            try await makeService().generateInsight(type: .routeContext, context: context)
        }
        #expect(error == .http(statusCode: 400, message: "max_tokens: too large"))
        #expect(error?.errorDescription == "max_tokens: too large")
    }

    @Test(arguments: [429, 500, 529])
    func givesFriendlyMessagesForTransientFailures(status: Int) async throws {
        StubURLProtocol.handler = StubURLProtocol.respond(status: status, json: "upstream exploded")

        let error = await #expect(throws: ClaudeAPIError.self) {
            try await makeService().generateInsight(type: .routeContext, context: context)
        }
        #expect(error == .http(statusCode: status, message: nil))
        #expect(error?.errorDescription?.contains("\(status)") == false)
    }

    @Test func treatsRefusalAsError() async {
        StubURLProtocol.handler = StubURLProtocol.respond(status: 200, json: """
        {"content": [], "stop_reason": "refusal"}
        """)

        await #expect(throws: ClaudeAPIError.refused) {
            try await makeService().generateInsight(type: .routeContext, context: context)
        }
    }

    @Test(arguments: [
        #"{"content": [], "stop_reason": "end_turn"}"#,
        #"{"content": [{"type": "text", "text": "   "}]}"#,
        "not json"
    ])
    func rejectsEmptyOrMalformedResponses(json: String) async {
        StubURLProtocol.handler = StubURLProtocol.respond(status: 200, json: json)

        await #expect(throws: ClaudeAPIError.invalidResponse) {
            try await makeService().generateInsight(type: .routeContext, context: context)
        }
    }
}
