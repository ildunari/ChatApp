// Providers/AnthropicProvider.swift
import Foundation

struct AnthropicProvider: AIProviderAdvanced {
    let id = "anthropic"
    let displayName = "Anthropic Claude"

    private let client = NetworkClient.shared
    private let apiKey: String
    private let apiBase = URL(string: "https://api.anthropic.com/v1")!

    init(apiKey: String) { self.apiKey = apiKey }

    func listModels() async throws -> [String] {
        // Use ProviderAPIs for consistency
        return try await ProviderAPIs.listModels(provider: .anthropic, apiKey: apiKey)
    }

    func sendChat(messages: [AIMessage], model: String) async throws -> String {
        try await sendChat(messages: messages, model: model, temperature: nil, topP: nil, topK: nil, maxOutputTokens: 1024, reasoningEffort: nil, verbosity: nil)
    }

    func sendChat(
        messages: [AIMessage],
        model: String,
        temperature: Double?,
        topP: Double?,
        topK: Int?,
        maxOutputTokens: Int?,
        reasoningEffort: String?,
        verbosity: String?
    ) async throws -> String {
        struct ContentBlock: Encodable {
            let type: String
            let text: String?
            let source: ImageSource?
            struct ImageSource: Encodable { let type: String = "base64"; let media_type: String; let data: String }
        }
        struct MessageItem: Encodable { let role: String; let content: [ContentBlock] }
        struct Req: Encodable {
            let model: String
            let messages: [MessageItem]
            let temperature: Double?
            let top_p: Double?
            let top_k: Int?
            let max_tokens: Int?
            let system: String?
        }
        struct Resp: Decodable {
            struct OutContent: Decodable { let type: String; let text: String? }
            let content: [OutContent]
        }

        // Split out system prompts
        let systemText = messages.filter { $0.role == .system }
            .flatMap { msg in msg.parts.compactMap { if case let .text(t) = $0 { return t } else { return nil } } }
            .joined(separator: "\n\n")

        // Map user/assistant messages
        func toBlocks(_ parts: [AIMessage.Part]) -> [ContentBlock] {
            parts.map { p in
                switch p {
                case .text(let t):
                    return ContentBlock(type: "text", text: t, source: nil)
                case .imageData(let data, let mime):
                    return ContentBlock(type: "input_image", text: nil, source: .init(media_type: mime, data: data.base64EncodedString()))
                }
            }
        }
        let seq: [MessageItem] = messages.compactMap { m in
            switch m.role {
            case .system:
                return nil // moved to top-level 'system'
            case .user:
                return MessageItem(role: "user", content: toBlocks(m.parts))
            case .assistant:
                return MessageItem(role: "assistant", content: toBlocks(m.parts))
            }
        }

        let req = Req(model: model,
                      messages: seq,
                      temperature: temperature,
                      top_p: topP,
                      top_k: topK,
                      max_tokens: maxOutputTokens,
                      system: systemText.isEmpty ? nil : systemText)

        var urlReq = URLRequest(url: apiBase.appendingPathComponent("messages"))
        urlReq.httpMethod = "POST"
        urlReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlReq.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlReq.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlReq.httpBody = try JSONEncoder().encode(req)

        let (data, resp) = try await client.session.data(for: urlReq)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let http = resp as? HTTPURLResponse
            let err = String(data: data, encoding: .utf8) ?? "Error"
            throw NSError(domain: "Anthropic", code: http?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: err])
        }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        let text = decoded.content.compactMap { $0.text }.joined(separator: "\n")
        return text
    }
}

