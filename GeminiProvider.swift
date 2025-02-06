

import Foundation

/// Holds your LLM API key and model name
struct GeminiConfig: Codable {
    var apiKey: String
    var modelName: String
}

/// A simple class for calling the PaLM / generative language API
class GeminiProvider {
    private var config: GeminiConfig

    init(config: GeminiConfig) {
        self.config = config
    }

    /// Sends `userPrompt` to the LLM and returns the response text.
    func processText(userPrompt: String) async throws -> String {
        guard !config.apiKey.isEmpty else {
            throw NSError(domain: "GeminiAPI", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "API key is missing."])
        }

        guard let url = URL(string:
          "https://generativelanguage.googleapis.com/v1beta/models/\(config.modelName):generateContent?key=\(config.apiKey)"
        ) else {
            throw NSError(domain: "GeminiAPI", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid URL."])
        }

        // Build the JSON request body
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": userPrompt]
                    ]
                ]
            ]
        ]

        // Prepare request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: .fragmentsAllowed)

        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "GeminiAPI", code: statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Server error \(statusCode)"])
        }

        // Parse JSON
        guard
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            !candidates.isEmpty,
            let content = candidates.first?["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let text = parts.first?["text"] as? String
        else {
            throw NSError(domain: "GeminiAPI", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "No valid content in response."])
        }

        return text
    }
}

