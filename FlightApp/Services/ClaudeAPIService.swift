//
//  ClaudeAPIService.swift
//  FlightApp
//
//  Service for generating insights using Claude Haiku 4.5
//

import Foundation
import OSLog

final class ClaudeAPIService {
    /// Reads ANTHROPIC_KEY from Info.plist (populated by Config.xcconfig).
    /// A missing key doesn't crash the app; insight requests throw `.missingAPIKey` instead.
    static let shared = ClaudeAPIService(
        apiKey: Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_KEY") as? String
    )

    static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    static let apiVersion = "2023-06-01"

    private let apiKey: String?
    private let session: URLSession
    private let model: String
    private let maxTokens: Int

    init(
        apiKey: String?,
        session: URLSession = .shared,
        model: String = "claude-haiku-4-5",
        maxTokens: Int = 150 // Keep responses concise
    ) {
        let trimmed = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.apiKey = (trimmed?.isEmpty ?? true) ? nil : trimmed
        self.session = session
        self.model = model
        self.maxTokens = maxTokens
    }

    var isConfigured: Bool { apiKey != nil }

    /// Generate an insight using Claude
    func generateInsight(type: InsightType, context: InsightContext) async throws -> String {
        guard let apiKey else { throw ClaudeAPIError.missingAPIKey }

        let (systemPrompt, userPrompt) = ClaudePromptBuilder.buildPrompt(type: type, context: context)
        Logger.claude.debug("Generating \(String(describing: type), privacy: .public) insight")

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONEncoder().encode(ClaudeRequest(
            model: model,
            maxTokens: maxTokens,
            system: systemPrompt,
            messages: [.init(role: "user", content: userPrompt)]
        ))

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data)
            Logger.claude.error("HTTP \(httpResponse.statusCode, privacy: .public): \(body?.error.message ?? "no error body", privacy: .public)")
            throw ClaudeAPIError.http(statusCode: httpResponse.statusCode, message: body?.error.message)
        }

        let decoded: ClaudeResponse
        do {
            decoded = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        } catch {
            throw ClaudeAPIError.invalidResponse
        }

        if decoded.stopReason == "refusal" {
            throw ClaudeAPIError.refused
        }

        let text = decoded.content
            .filter { $0.type == "text" }
            .compactMap(\.text)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else { throw ClaudeAPIError.invalidResponse }
        return text
    }
}

// MARK: - Request / Response Models

struct ClaudeRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let maxTokens: Int
    let system: String
    let messages: [Message]

    enum CodingKeys: String, CodingKey {
        case model, system, messages
        case maxTokens = "max_tokens"
    }
}

struct ClaudeResponse: Decodable {
    let content: [ClaudeContent]
    let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case content
        case stopReason = "stop_reason"
    }
}

struct ClaudeContent: Decodable {
    let type: String
    let text: String?
}

struct ClaudeErrorResponse: Decodable {
    struct Detail: Decodable {
        let type: String
        let message: String
    }

    let error: Detail
}

enum ClaudeAPIError: Error, LocalizedError, Equatable {
    case missingAPIKey
    case http(statusCode: Int, message: String?)
    case invalidResponse
    case refused

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Anthropic API key not configured"
        case .http(429, _):
            return "Too many requests. Try again in a moment."
        case .http(let statusCode, _) where statusCode >= 500:
            return "Claude is temporarily unavailable. Try again later."
        case .http(let statusCode, let message):
            return message ?? "Claude request failed (\(statusCode))"
        case .invalidResponse:
            return "Received invalid response from Claude API"
        case .refused:
            return "Claude declined to generate this insight"
        }
    }
}
