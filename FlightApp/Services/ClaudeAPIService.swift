//
//  ClaudeAPIService.swift
//  FlightApp
//
//  Service for generating insights using Claude 4.5 Haiku
//

import Foundation

class ClaudeAPIService {
    static let shared = ClaudeAPIService()

    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-haiku-4-5-20251001"
    private let maxTokens = 150 // Keep responses concise

    private init() {
        // Load API key from Config.xcconfig
        guard let key = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_KEY") as? String,
              !key.isEmpty else {
            fatalError("ANTHROPIC_KEY not found in Config.xcconfig")
        }
        self.apiKey = key
    }

    /// Generate an insight using Claude
    func generateInsight(
        type: InsightType,
        context: InsightContext
    ) async throws -> String {
        let (systemPrompt, userPrompt) = ClaudePromptBuilder.buildPrompt(type: type, context: context)

        print("🤖 [Claude] Generating \(type) insight")
        print("📝 [Claude] System: \(systemPrompt.prefix(100))...")
        print("📝 [Claude] User: \(userPrompt.prefix(100))...")

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ]
        ]

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [Claude] No HTTP response")
            throw ClaudeAPIError.requestFailed
        }

        // Log response details for debugging
        print("📡 [Claude] HTTP Status: \(httpResponse.statusCode)")

        if !(200...299).contains(httpResponse.statusCode) {
            // Try to decode error response
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [Claude] Error response: \(errorString)")
            }
            throw ClaudeAPIError.requestFailed
        }

        let decoded = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let content = decoded.content.first,
              content.type == "text" else {
            throw ClaudeAPIError.invalidResponse
        }

        return content.text
    }
}

// MARK: - Response Models

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
    }
}

struct ClaudeContent: Codable {
    let type: String
    let text: String
}

enum ClaudeAPIError: Error, LocalizedError {
    case requestFailed
    case invalidResponse
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .requestFailed:
            return "Failed to get response from Claude API"
        case .invalidResponse:
            return "Received invalid response from Claude API"
        case .missingAPIKey:
            return "Anthropic API key not configured"
        }
    }
}
