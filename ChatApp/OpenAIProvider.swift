// Providers/OpenAIProvider.swift
import Foundation

struct OpenAIProvider: AIProviderAdvanced, AIStreamingProvider {
    let id = "openai"
    let displayName = "OpenAI"

    private let client = NetworkClient.shared
    private let apiBase = URL(string: "https://api.openai.com/v1")!
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func listModels() async throws -> [String] {
        // Keep it simple; you can implement /models later.
        // Provide a common set of useful defaults.
        return [
            "gpt-5",
            "gpt-5-mini",
            "gpt-5-nano",
            "gpt-4o-mini",
            "gpt-4o",
            "gpt-4.1-mini"
        ]
    }

    // Backwards-compatible entry point delegates to Responses API implementation
    func sendChat(messages: [AIMessage], model: String) async throws -> String {
        try await sendChat(messages: messages, model: model, temperature: nil, maxOutputTokens: nil, reasoningEffort: nil, verbosity: nil)
    }

    // Responses API with multimodal support
    func sendChat(
        messages: [AIMessage],
        model: String,
        temperature: Double?,
        maxOutputTokens: Int?,
        reasoningEffort: String?,
        verbosity: String?
    ) async throws -> String {
        struct InputItem: Encodable {
            let role: String
            let content: [Content]
        }
        struct Content: Encodable {
            let type: String
            let text: String?
            let image_url: ImageURL?
            init(text: String) { self.type = "input_text"; self.text = text; self.image_url = nil }
            init(imageDataURL: String) { self.type = "input_image"; self.text = nil; self.image_url = ImageURL(url: imageDataURL) }
            struct ImageURL: Encodable { let url: String }
        }
        struct Req: Encodable {
            let model: String
            let input: [InputItem]
            let temperature: Double?
            let max_output_tokens: Int?
            let reasoning: Reasoning?
            let verbosity: String?
            struct Reasoning: Encodable { let effort: String }
        }
        struct Resp: Decodable { let output: Output?; let response: Output? }
        struct Output: Decodable { let content: [OutPart]? }
        struct OutPart: Decodable { let type: String; let text: String? }

        func dataURL(from data: Data, mime: String) -> String {
            let b64 = data.base64EncodedString()
            return "data:\(mime);base64,\(b64)"
        }

        let inputItems: [InputItem] = messages.map { msg in
            var parts: [Content] = []
            for p in msg.parts {
                switch p {
                case .text(let t): parts.append(.init(text: t))
                case .imageData(let data, let mime): parts.append(.init(imageDataURL: dataURL(from: data, mime: mime)))
                }
            }
            return InputItem(role: msg.role.rawValue, content: parts)
        }

        let req = Req(model: model,
                      input: inputItems,
                      temperature: temperature,
                      max_output_tokens: maxOutputTokens,
                      reasoning: reasoningEffort.map { .init(effort: $0) },
                      verbosity: verbosity)

        let url = apiBase.appendingPathComponent("responses")
        let (data, http) = try await client.postJSON(url: url, body: req, headers: [
            "Authorization": "Bearer \(apiKey)"
        ])
        guard (200..<300).contains(http.statusCode) else {
            let err = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: err])
        }

        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        let content = (decoded.output ?? decoded.response)?.content?.compactMap { $0.text }.joined(separator: "\n")
        guard let text = content, !text.isEmpty else {
            throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty response"])
        }
        return text
    }

    // Streaming via Responses SSE
    func streamChat(
        messages: [AIMessage],
        model: String,
        temperature: Double?,
        maxOutputTokens: Int?,
        reasoningEffort: String?,
        verbosity: String?,
        onDelta: @escaping (String) -> Void
    ) async throws -> String {
        struct InputItem: Encodable { let role: String; let content: [Content] }
        struct Content: Encodable {
            let type: String
            let text: String?
            let image_url: ImageURL?
            init(text: String) { self.type = "input_text"; self.text = text; self.image_url = nil }
            init(imageDataURL: String) { self.type = "input_image"; self.text = nil; self.image_url = ImageURL(url: imageDataURL) }
            struct ImageURL: Encodable { let url: String }
        }
        struct Req: Encodable {
            let model: String
            let input: [InputItem]
            let temperature: Double?
            let max_output_tokens: Int?
            let reasoning: Reasoning?
            let verbosity: String?
            let stream: Bool
            struct Reasoning: Encodable { let effort: String }
        }

        func dataURL(from data: Data, mime: String) -> String { "data:\(mime);base64,\(data.base64EncodedString())" }

        let inputItems: [InputItem] = messages.map { msg in
            var parts: [Content] = []
            for p in msg.parts {
                switch p {
                case .text(let t): parts.append(.init(text: t))
                case .imageData(let data, let mime): parts.append(.init(imageDataURL: dataURL(from: data, mime: mime)))
                }
            }
            return InputItem(role: msg.role.rawValue, content: parts)
        }

        let reqBody = Req(model: model,
                          input: inputItems,
                          temperature: temperature,
                          max_output_tokens: maxOutputTokens,
                          reasoning: reasoningEffort.map { .init(effort: $0) },
                          verbosity: verbosity,
                          stream: true)

        var request = URLRequest(url: apiBase.appendingPathComponent("responses"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(reqBody)

        var full = ""
        let (bytes, response) = try await client.session.bytes(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        for try await line in bytes.lines {
            // SSE format: lines starting with "data: {json}"
            guard line.hasPrefix("data:") else { continue }
            let jsonString = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            if jsonString == "[DONE]" { break }
            guard let data = jsonString.data(using: .utf8) else { continue }
            // Try to decode OpenAI Responses streaming events
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let t = obj["type"] as? String {
                    if t == "response.output_text.delta", let d = obj["delta"] as? String {
                        full += d
                        onDelta(d)
                    } else if t == "response.output_text", let text = obj["text"] as? String {
                        full += text
                        onDelta(text)
                    } else if t == "response.completed" {
                        break
                    } else if t == "error", let err = obj["error"] as? [String: Any], let msg = err["message"] as? String {
                        throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
                    }
                }
            }
        }
        return full
    }
}
