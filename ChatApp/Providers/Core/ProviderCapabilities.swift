// Providers/Core/ProviderCapabilities.swift
// Capability protocols for optional advanced features
import Foundation

public protocol AIVoiceSessionProvider: AnyObject {
    func startVoiceSession(model: String, language: String?, format: String?) async throws
    func sendAudioChunk(_ data: Data) async throws
    func endVoiceSession() async throws
}

public extension AIVoiceSessionProvider {
    func startVoiceSession(model: String, language: String? = nil, format: String? = nil) async throws {}
    func sendAudioChunk(_ data: Data) async throws {}
    func endVoiceSession() async throws {}
}

public enum AIToolCall: Equatable, Codable {
    case function(name: String, argumentsJSON: String)
}

public protocol AIToolCallingProvider {
    func sendWithTools(messages: [AIMessage], model: String, tools: [String]) async throws -> (finalText: String, calls: [AIToolCall])
}

public extension AIToolCallingProvider {
    func sendWithTools(messages: [AIMessage], model: String, tools: [String]) async throws -> (String, [AIToolCall]) {
        throw NSError(domain: "Provider", code: -2, userInfo: [NSLocalizedDescriptionKey: "Tool calling not supported by this provider."])
    }
}

public protocol AIDocumentIngestProvider {
    func analyzeDocuments(_ items: [(data: Data, mime: String)], model: String, prompt: String?) async throws -> String
}

public extension AIDocumentIngestProvider {
    func analyzeDocuments(_ items: [(data: Data, mime: String)], model: String, prompt: String? = nil) async throws -> String {
        throw NSError(domain: "Provider", code: -3, userInfo: [NSLocalizedDescriptionKey: "Document analysis not supported by this provider."])
    }
}
