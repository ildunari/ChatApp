// Services/ProviderAPIs.swift
import Foundation

enum ProviderID: String, CaseIterable {
    case openai
    case anthropic
    case google
    case xai

    var displayName: String {
        switch self {
        case .openai: return "OpenAI ChatGPT"
        case .anthropic: return "Anthropic Claude"
        case .google: return "Google Gemini"
        case .xai: return "XAI Grok"
        }
    }
}

struct ProviderAPIs {
    static let client = NetworkClient.shared

    static func listModels(provider: ProviderID, apiKey: String) async throws -> [String] {
        switch provider {
        case .openai:
            let (data, http) = try await client.get(url: URL(string: "https://api.openai.com/v1/models")!, headers: [
                "Authorization": "Bearer \(apiKey)"
            ])
            guard (200..<300).contains(http.statusCode) else {
                throw NSError(domain: "OpenAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Error"])
            }
            struct ModelList: Decodable { struct Item: Decodable { let id: String }
                let data: [Item] }
            let decoded = try JSONDecoder().decode(ModelList.self, from: data)
            return decoded.data.map { $0.id }.sorted()

        case .anthropic:
            var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/models")!)
            req.httpMethod = "GET"
            req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            let (data, resp) = try await client.session.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                let http = resp as? HTTPURLResponse
                throw NSError(domain: "Anthropic", code: http?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Error"])
            }
            struct ModelList: Decodable { struct Item: Decodable { let id: String }
                let data: [Item] }
            let decoded = try JSONDecoder().decode(ModelList.self, from: data)
            return decoded.data.map { $0.id }.sorted()

        case .google:
            let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)")!
            let (data, http) = try await client.get(url: url)
            guard (200..<300).contains(http.statusCode) else {
                throw NSError(domain: "Google", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Error"])
            }
            struct ModelList: Decodable { struct Item: Decodable { let name: String }
                let models: [Item]? }
            let decoded = try JSONDecoder().decode(ModelList.self, from: data)
            return (decoded.models ?? []).map { $0.name }

        case .xai:
            let (data, http) = try await client.get(url: URL(string: "https://api.x.ai/v1/models")!, headers: [
                "Authorization": "Bearer \(apiKey)"
            ])
            guard (200..<300).contains(http.statusCode) else {
                throw NSError(domain: "XAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Error"])
            }
            struct ModelList: Decodable { struct Item: Decodable { let id: String }
                let data: [Item] }
            let decoded = try JSONDecoder().decode(ModelList.self, from: data)
            return decoded.data.map { $0.id }.sorted()
        }
    }

    static func verifyKey(provider: ProviderID, apiKey: String) async -> Bool {
        do {
            _ = try await listModels(provider: provider, apiKey: apiKey)
            return true
        } catch {
            return false
        }
    }
}

