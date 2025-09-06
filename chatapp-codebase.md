This file is a merged representation of a subset of the codebase, containing specifically included files and files not matching ignore patterns, combined into a single document by Repomix.

# File Summary

## Purpose
This file contains a packed representation of the entire repository's contents.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.
- Pay special attention to the Repository Description. These contain important context and guidelines specific to this project.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Only files matching these patterns are included: **/*.swift, **/*.h, **/Info.plist, **/Localizable.strings, **/*.xcconfig, **/project.pbxproj, **/Package.swift, **/Package.resolved, **/*.xctestplan, **/README.md, **/CLAUDE.md, **/.gitignore, **/repomix.config.json, **/ChatApp.entitlements, **/*.xcscheme
- Files matching these patterns are excluded: **/*.xcuserstate, **/xcuserdata/**, **/DerivedData/**, **/Build/**, **/BuildLogs/**, **/.build/**, **/.swiftpm/**, **/docs/**, **/*.dSYM/**, **/*.xcodeproj/xcuserdata/**, **/*.xcodeproj/project.xcworkspace/xcuserdata/**, **/webcanvas/node_modules/**, **/webcanvas/.next/**, **/webcanvas/dist/**, **/*.log, **/*.tmp, **/*.bak, **/Vendor/iosMath/**/*.h, **/Vendor/iosMath/**/*.m, **/*_GUIDE.md, **/*_STRATEGY.md, **/*_PLAN.md, **/ChatApp/WebCanvas/**, **/.DS_Store, **/.vscode/**, **/.idea/**, **/Env/.env, **/Env/*.env
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded

## Additional Info
### User Provided Header
ChatApp iOS Project Codebase

# Directory Structure
```
ChatApp/
  AIProvider.swift
  AIResponseView.swift
  AnthropicProvider.swift
  ChatApp.entitlements
  ChatAppApp.swift
  ChatCanvasView.swift
  ChatStyles.swift
  ChatUI.swift
  ChatView.swift
  ContentView.swift
  EnvLoader.swift
  FlowLayout.swift
  GoogleProvider.swift
  ImageProvider.swift
  Info.plist
  Item.swift
  KeychainService.swift
  MathWebView.swift
  ModelCapabilities.swift
  Models.swift
  NetworkClient.swift
  OpenAIImageProvider.swift
  OpenAIProvider.swift
  ProviderAPIs.swift
  SettingsStore.swift
  SettingsView.swift
  SystemPrompt.swift
  XAIProvider.swift
ChatApp.xcodeproj/
  xcshareddata/
    xcschemes/
      ChatApp.xcscheme
  project.pbxproj
  SwiftMathSmokeTest.swift
ChatAppTests/
  ChatAppTests.swift
ChatAppUITests/
  ChatAppUITests.swift
  ChatAppUITestsLaunchTests.swift
.gitignore
ChatApp.xctestplan
CLAUDE.md
repomix.config.json
```

# Files

## File: ChatApp/AIProvider.swift
````swift
// Providers/AIProvider.swift
import Foundation

struct AIMessage {
    enum Role: String, Codable { case system, user, assistant }
    enum Part: Codable, Hashable {
        case text(String)
        case imageData(Data, mime: String)
    }
    var role: Role
    var parts: [Part]

    init(role: Role, content: String) {
        self.role = role
        self.parts = [.text(content)]
    }

    init(role: Role, parts: [Part]) {
        self.role = role
        self.parts = parts
    }
}

protocol AIProvider {
    var id: String { get }
    var displayName: String { get }
    func listModels() async throws -> [String]
    func sendChat(messages: [AIMessage], model: String) async throws -> String
}

// Optional advanced API with extra parameters supported by modern models (Responses API)
protocol AIProviderAdvanced: AIProvider {
    func sendChat(
        messages: [AIMessage],
        model: String,
        temperature: Double?,
        topP: Double?,
        topK: Int?,
        maxOutputTokens: Int?,
        reasoningEffort: String?, // e.g. minimal|medium|high
        verbosity: String?        // e.g. low|medium|high
    ) async throws -> String
}

protocol AIStreamingProvider {
    func streamChat(
        messages: [AIMessage],
        model: String,
        temperature: Double?,
        topP: Double?,
        topK: Int?,
        maxOutputTokens: Int?,
        reasoningEffort: String?,
        verbosity: String?,
        onDelta: @escaping (String) -> Void
    ) async throws -> String
}
````

## File: ChatApp/AIResponseView.swift
````swift
// Views/AIResponseView.swift
import SwiftUI

#if canImport(MarkdownUI)
import MarkdownUI
#endif

#if canImport(Highlightr)
import Highlightr
#endif

#if canImport(SwiftMath)
import SwiftMath
#endif
#if canImport(iosMath)
import iosMath
#endif

struct AIResponseView: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(parseBlocks(from: content)) { block in
                switch block.kind {
                case .markdown(let text):
                    MarkdownSegment(text: text)
                case .code(let lang, let code):
                    CodeBlockSegment(language: lang, code: code)
                case .math(let latex):
                    MathBlockSegment(latex: latex)
                }
            }
        }
        .padding(.vertical, 2) // no bubble; let canvas show
    }
}

// MARK: - Parsing

private enum BlockKind { case markdown(String), code(lang: String?, code: String), math(String) }
private struct Block: Identifiable { let id = UUID(); let kind: BlockKind }

private func parseBlocks(from text: String) -> [Block] {
    // Recognize triple‑backtick code blocks and $$ math blocks as top‑level segments.
    // Simple, linear parser; leaves inline $...$ to the Markdown engine.
    enum Token { case code(lang: String?, body: String), math(body: String), text(String) }
    var tokens: [Token] = []
    var remainder = text[...]

    func takeUntil(_ marker: String, in s: Substring) -> (Substring, Substring)? {
        guard let range = s.range(of: marker) else { return nil }
        return (s[..<range.lowerBound], s[range.upperBound...])
    }

    while !remainder.isEmpty {
        if remainder.hasPrefix("```") {
            // code block
            let afterTicks = remainder.dropFirst(3)
            let firstLineEnd = afterTicks.firstIndex(of: "\n") ?? afterTicks.endIndex
            let langStr = afterTicks[..<firstLineEnd]
            let lang = langStr.isEmpty ? nil : String(langStr)
            let afterLang = afterTicks.dropFirst(langStr.count)
            if let (body, rest) = takeUntil("```", in: afterLang) {
                tokens.append(.code(lang: lang, body: String(body.dropFirst())))
                remainder = rest
                continue
            } else {
                tokens.append(.text(String(remainder)))
                break
            }
        } else if remainder.hasPrefix("$$") {
            // math block
            let after = remainder.dropFirst(2)
            if let (body, rest) = takeUntil("$$", in: after) {
                tokens.append(.math(body: String(body)))
                remainder = rest
                continue
            } else {
                tokens.append(.text(String(remainder)))
                break
            }
        } else {
            // capture until next special block
            if let codeRange = remainder.range(of: "```"), let mathRange = remainder.range(of: "$$") {
                let next = min(codeRange.lowerBound, mathRange.lowerBound)
                tokens.append(.text(String(remainder[..<next])))
                remainder = remainder[next...]
            } else if let range = remainder.range(of: "```") ?? remainder.range(of: "$$") {
                tokens.append(.text(String(remainder[..<range.lowerBound])))
                remainder = remainder[range.lowerBound...]
            } else {
                tokens.append(.text(String(remainder)))
                break
            }
        }
    }

    return tokens.map { token in
        switch token {
        case .text(let t): return Block(kind: .markdown(t))
        case .code(let lang, let body): return Block(kind: .code(lang: lang, code: body.trimmingCharacters(in: .whitespacesAndNewlines)))
        case .math(let body): return Block(kind: .math(body.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
    }.filter { block in
        switch block.kind { case .markdown(let t): return t.isEmpty == false; default: return true }
    }
}

// MARK: - Segments

private struct MarkdownSegment: View {
    let text: String

    // Lightweight detector for Markdown tables (header and pipes present)
    private var containsTable: Bool {
        text.contains("|") && text.contains("---")
    }

    var body: some View {
        Group {
            #if canImport(MarkdownUI)
            if text.contains("$") {
                // Use our inline math renderer when inline $...$ detected
                InlineMathParagraph(text: text)
            } else {
                // Prefer GitHub-like theme; horizontally scroll tables to avoid crushing
                let md = Markdown(text)
                    .markdownTheme(.chatApp)
                if containsTable {
                    ScrollView(.horizontal, showsIndicators: true) {
                        md
                    }
                } else {
                    md
                }
            }
            #else
            // Fallback: still render inline math tokens; plain Text otherwise
            InlineMathParagraph(text: text)
            #endif
        }
    }
}

private struct CodeBlockSegment: View {
    let language: String?
    let code: String
    var body: some View {
        Group {
            #if canImport(Highlightr) || canImport(HighlighterSwift)
            HighlightedCodeView(code: code, language: language)
                .padding(6)
                .background(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(UIColor.separator).opacity(0.25), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            #else
            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .padding(12)
            }
            .background(Color(UIColor.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(UIColor.separator).opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            #endif
        }
    }
}

private struct MathBlockSegment: View {
    let latex: String
    var body: some View {
        Group {
            #if canImport(SwiftMath) || canImport(iosMath)
            SwiftOrIOSMathLabel(latex: latex)
                .padding(.vertical, 4)
            #else
            // Web-based KaTeX fallback (auto-sizes; allows horizontal scroll)
            MathWebView(latex: latex, displayMode: true)
                .frame(minHeight: 28)
            #endif
        }
    }
}

#if canImport(Highlightr)
private struct HighlightedCodeView: UIViewRepresentable {
    let code: String
    let language: String?
    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        tv.backgroundColor = UIColor.clear
        return tv
    }
    func updateUIView(_ uiView: UITextView, context: Context) {
        if let highlightr = Highlightr(), let theme = highlightr.setTheme(to: "xcode") {
            highlightr.theme = theme
            let highlighted = highlightr.highlight(code, as: language)
            uiView.attributedText = highlighted
            uiView.textColor = UIColor.label
        } else {
            uiView.text = code
        }
    }
}
#elseif canImport(HighlighterSwift)
import HighlighterSwift
private struct HighlightedCodeView: UIViewRepresentable {
    let code: String
    let language: String?
    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        tv.backgroundColor = UIColor.clear
        return tv
    }
    func updateUIView(_ uiView: UITextView, context: Context) {
        let highlighter = HighlighterSwift()
        // Attempt a common theme; fall back gracefully
        let highlighted = highlighter.highlight(code: code, as: language ?? "") ?? NSAttributedString(string: code)
        uiView.attributedText = highlighted
        uiView.textColor = UIColor.label
    }
}
#endif

#if canImport(SwiftMath) || canImport(iosMath)
private struct SwiftOrIOSMathLabel: UIViewRepresentable {
    let latex: String
    func makeUIView(context: Context) -> MTMathUILabel {
        let v = MTMathUILabel()
        v.labelMode = .text
        v.textAlignment = .center
        v.latex = latex
        return v
    }
    func updateUIView(_ uiView: MTMathUILabel, context: Context) {
        uiView.latex = latex
    }
}
#endif

// MARK: Inline math paragraph rendering

private struct InlineMathParagraph: View {
    let text: String

    var pieces: [InlinePiece] {
        parseInlineMath(text)
    }

    var body: some View {
        FlowLayout(spacing: 4) {
            ForEach(Array(pieces.enumerated()), id: \.offset) { _, p in
                switch p {
                case .text(let t):
                    Text(t)
                case .math(let ltx):
                    #if canImport(SwiftMath) || canImport(iosMath)
                    SwiftOrIOSMathLabel(latex: ltx)
                    #else
                    MathWebView(latex: ltx, displayMode: false)
                        .frame(minHeight: 22)
                    #endif
                }
            }
        }
    }
}

private enum InlinePiece { case text(String), math(String) }

private func parseInlineMath(_ s: String) -> [InlinePiece] {
    var out: [InlinePiece] = []
    var buffer = ""
    var i = s.startIndex
    var inMath = false
    while i < s.endIndex {
        let ch = s[i]
        if ch == "$" {
            // toggle math mode (ignore $$ which are handled as blocks earlier)
            // If next is '$', treat as literal and skip
            let nextIndex = s.index(after: i)
            if nextIndex < s.endIndex, s[nextIndex] == "$" {
                buffer.append("$$")
                i = s.index(after: nextIndex)
                continue
            }
            if inMath {
                out.append(.math(buffer))
                buffer.removeAll()
                inMath = false
            } else {
                if buffer.isEmpty == false { out.append(.text(buffer)); buffer.removeAll() }
                inMath = true
            }
            i = s.index(after: i)
            continue
        }
        buffer.append(ch)
        i = s.index(after: i)
    }
    if buffer.isEmpty == false {
        out.append(inMath ? .math(buffer) : .text(buffer))
    }
    return out
}
````

## File: ChatApp/AnthropicProvider.swift
````swift
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
            let cache_control: CacheControl?
            struct ImageSource: Encodable { let type: String = "base64"; let media_type: String; let data: String }
            struct CacheControl: Encodable { let type: String } // e.g., "ephemeral"
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
            let thinking: Thinking?
            struct Thinking: Encodable { let type: String; let budget_tokens: Int }
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
        let caps = ModelCapabilitiesStore.get(provider: id, model: model)
        let cacheFlag = (caps?.enablePromptCaching ?? false)
        func toBlocks(_ parts: [AIMessage.Part]) -> [ContentBlock] {
            parts.map { p in
                switch p {
                case .text(let t):
                    return ContentBlock(type: "text", text: t, source: nil, cache_control: cacheFlag ? .init(type: "ephemeral") : nil)
                case .imageData(let data, let mime):
                    return ContentBlock(type: "input_image", text: nil, source: .init(media_type: mime, data: data.base64EncodedString()), cache_control: nil)
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

        let thinking: Req.Thinking? = (caps?.anthropicThinkingEnabled ?? false) ? .init(type: "enabled", budget_tokens: caps?.anthropicThinkingBudget ?? 0) : nil
        let req = Req(model: model,
                      messages: seq,
                      temperature: temperature,
                      top_p: topP,
                      top_k: topK,
                      max_tokens: maxOutputTokens,
                      system: systemText.isEmpty ? nil : systemText,
                      thinking: thinking)

        var urlReq = URLRequest(url: apiBase.appendingPathComponent("messages"))
        urlReq.httpMethod = "POST"
        urlReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlReq.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlReq.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        if cacheFlag { urlReq.setValue("prompt-caching-2024-07-31, thinking-2024-07-31", forHTTPHeaderField: "anthropic-beta") }
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
````

## File: ChatApp/ChatApp.entitlements
````
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>development</string>
	<key>com.apple.developer.icloud-container-identifiers</key>
	<array/>
	<key>com.apple.developer.icloud-services</key>
	<array>
		<string>CloudKit</string>
	</array>
</dict>
</plist>
````

## File: ChatApp/ChatAppApp.swift
````swift
//
//  ChatAppApp.swift
//  ChatApp
//
//  Created by Kosta Milovanovic on 9/4/25.
//

import SwiftUI
import SwiftData

@main
struct ChatAppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Chat.self,
            Message.self,
            AppSettings.self
        ])
        // Persist to Application Support with a stable file name so we can recover from corruption
        let fm = FileManager.default
        let baseDir = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let storeURL = baseDir.appendingPathComponent("ChatApp.sqlite")
        let config = ModelConfiguration("Default", schema: schema, url: storeURL, allowsSave: true)

        func makeContainer() throws -> ModelContainer {
            try ModelContainer(for: schema, configurations: [config])
        }

        do {
            return try makeContainer()
        } catch {
            // Attempt a one-time recovery by removing the SQLite store (and sidecars) and recreating
            let sidecars = ["", "-wal", "-shm"].map { storeURL.appendingPathExtension("sqlite").deletingPathExtension().appendingPathExtension("sqlite\($0)") }
            // Our storeURL already ends with .sqlite; remove it and common sidecars just in case
            let candidates = [storeURL, storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal"), storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")]
            for url in candidates + sidecars {
                try? fm.removeItem(at: url)
            }
            do {
                return try makeContainer()
            } catch {
                fatalError("Could not create ModelContainer after recovery: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
````

## File: ChatApp/ChatCanvasView.swift
````swift
import SwiftUI
import WebKit

// Controller object used to send commands into the WebCanvas once ready.
@MainActor
final class ChatCanvasController: ObservableObject {
    fileprivate weak var webView: WKWebView?
    fileprivate var isReady: Bool = false
    fileprivate var pending: [() -> Void] = []

    func attach(_ webView: WKWebView) {
        self.webView = webView
    }

    func markReady() {
        isReady = true
        let ops = pending
        pending.removeAll()
        for op in ops { op() }
    }

    private func callJS(_ script: String) {
        if isReady, let web = webView {
            web.evaluateJavaScript(script, completionHandler: nil)
        } else {
            pending.append { [weak self] in self?.webView?.evaluateJavaScript(script, completionHandler: nil) }
        }
    }

    func loadTranscript(_ messages: [CanvasMessage]) {
        guard let data = try? JSONEncoder().encode(messages), let json = String(data: data, encoding: .utf8) else { return }
        callJS("window.ChatCanvas && window.ChatCanvas.loadTranscript(\(json));")
    }

    func startStream(id: String) { callJS("window.ChatCanvas && window.ChatCanvas.startStream(\"\(escape(id))\");") }
    func appendDelta(id: String, delta: String) { callJS("window.ChatCanvas && window.ChatCanvas.appendDelta(\"\(escape(id))\", \"\(escape(delta))\");") }
    func endStream(id: String) { callJS("window.ChatCanvas && window.ChatCanvas.endStream(\"\(escape(id))\");") }
    func setTheme(_ theme: CanvasTheme) { callJS("window.ChatCanvas && window.ChatCanvas.setTheme(\"\(theme.rawValue)\");") }
    func scrollToBottom() { callJS("window.ChatCanvas && window.ChatCanvas.scrollToBottom();") }

    private func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
         .replacingOccurrences(of: "\n", with: "\\n")
    }
}

struct CanvasMessage: Codable {
    let id: String
    let role: String // "user" | "assistant"
    let content: String
    let createdAt: TimeInterval
}

enum CanvasTheme: String, Codable { case light, dark }

struct ChatCanvasView: UIViewRepresentable {
    @ObservedObject var controller: ChatCanvasController
    var theme: CanvasTheme

    func makeCoordinator() -> Coordinator { Coordinator(controller: controller) }

    func makeUIView(context: Context) -> WKWebView {
        let conf = WKWebViewConfiguration()
        conf.defaultWebpagePreferences.allowsContentJavaScript = true
        conf.allowsInlineMediaPlayback = true
        let userContent = WKUserContentController()
        // JS → Swift bridge
        userContent.add(context.coordinator, contentWorld: WKContentWorld.page, name: "bridge")
        conf.userContentController = userContent

        let web = WKWebView(frame: .zero, configuration: conf)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        controller.attach(web)

        // Load local bundle HTML
        if let base = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "WebCanvas/dist") {
            // Allow read access to the whole app bundle so we can reference sibling assets like ../KaTeX/*
            let bundleRoot = Bundle.main.bundleURL
            web.loadFileURL(base, allowingReadAccessTo: bundleRoot)
        } else if let alt = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "ChatApp/WebCanvas/dist") {
            let bundleRoot = Bundle.main.bundleURL
            web.loadFileURL(alt, allowingReadAccessTo: bundleRoot)
        }

        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Keep theme in sync once ready
        controller.setTheme(theme)
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let controller: ChatCanvasController
        init(controller: ChatCanvasController) { self.controller = controller }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "bridge" else { return }
            guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
            switch type {
            case "ready":
                controller.markReady()
            case "error":
                // Optionally log errors coming from the WebCanvas
                // print("WebCanvas error: \(body)")
                break
            case "height":
                // could adjust container height if needed in future
                break
            default:
                break
            }
        }
    }
}
````

## File: ChatApp/ChatStyles.swift
````swift
import SwiftUI
#if canImport(MarkdownUI)
import MarkdownUI
#endif

enum ChatStyle {
    static let bubbleCorner: CGFloat = 16
    static let bubbleBG = Color.secondary.opacity(0.06)
    static let codeBG = Color.secondary.opacity(0.08)
    static let divider = Color.secondary.opacity(0.12)
}

#if canImport(MarkdownUI)
extension Theme {
    static var chatApp: Theme {
        // Start from GitHub for sensible defaults; tighten spacing and code look.
        Theme.gitHub
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.95))
                BackgroundColor(ChatStyle.codeBG)
            }
            .strong {
                FontWeight(.semibold)
            }
            .link {
                // Slightly stronger link color; rely on system tint
                ForegroundColor(.accentColor)
            }
            .paragraph { configuration in
                configuration.label
                    .relativeLineSpacing(.em(0.18))
                    .markdownMargin(top: 0, bottom: 8)
            }
            .listItem { configuration in
                configuration.label
                    .markdownMargin(top: .em(0.1))
            }
    }
}
#endif
````

## File: ChatApp/ChatUI.swift
````swift
// Views/ChatUI.swift
import SwiftUI

struct SuggestionChipItem: Identifiable, Hashable { let id = UUID(); let title: String; let subtitle: String }

struct SuggestionChips: View {
    let suggestions: [SuggestionChipItem]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(suggestions) { s in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.title)
                            .font(.subheadline.weight(.semibold))
                        Text(s.subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.secondary.opacity(0.15))
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .frame(height: 60) // fixed height so it never collides with input bar
    }
}

private enum InputMetrics { // precise sizing
    static let edgePadding: CGFloat = 16
    static let rowSpacing: CGFloat = 10
    static let plusSize: CGFloat = 40
    static let fieldHeight: CGFloat = 40
    static let fieldCorner: CGFloat = 18
    static let sendSize: CGFloat = 40 // match plusSize for visual consistency
}

struct InputBar: View {
    @Binding var text: String
    var onSend: () -> Void
    var onMic: (() -> Void)? = nil
    var onLive: (() -> Void)? = nil
    var onPlus: (() -> Void)? = nil
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: InputMetrics.rowSpacing) {
            Button(action: { onPlus?() }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
            }
            .frame(width: InputMetrics.plusSize, height: InputMetrics.plusSize)
            .background(Circle().fill(Color.secondary.opacity(0.15)))

            HStack(spacing: 8) {
                // Expanding text field
                TextField("Ask anything", text: $text, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .lineLimit(1...6)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { onSend() }
                    }
                    .submitLabel(.send)

                // Trailing controls (mutually exclusive)
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // Voice controls when input is empty (match '+' button style)
                    Button(action: { onMic?() }) {
                        Image(systemName: "mic")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: InputMetrics.plusSize, height: InputMetrics.plusSize)
                            .background(Circle().fill(Color.secondary.opacity(0.15)))
                    }
                    Button(action: { onLive?() }) {
                        Image(systemName: "waveform")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.blue)
                            .frame(width: InputMetrics.plusSize, height: InputMetrics.plusSize)
                            .background(Circle().fill(Color.secondary.opacity(0.15)))
                    }
                } else {
                    // Send button only when there is text, styled like a small circle
                    Button(action: onSend) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.blue)
                            .frame(width: InputMetrics.sendSize, height: InputMetrics.sendSize)
                            .background(Circle().fill(Color.secondary.opacity(0.15)))
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .frame(minHeight: InputMetrics.fieldHeight) // compact baseline size
            .padding(.horizontal, 12)
            .padding(.vertical, 6) // slight vertical padding so text never looks cut off
            .background(
                RoundedRectangle(cornerRadius: InputMetrics.fieldCorner, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
        .padding(.horizontal, InputMetrics.edgePadding)
        .padding(.bottom, 8)
    }
}
````

## File: ChatApp/ChatView.swift
````swift
// Views/ChatView.swift
import SwiftUI
import PhotosUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [AppSettings]

    let chat: Chat

    @State private var inputText: String = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var showSuggestions = true
    @State private var showPhotoPicker = false
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var attachments: [Data] = []
    @State private var streamingText: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            if useWebCanvasFlag {
                WebCanvasContainer(chat: chat,
                                   messages: sortedMessages,
                                   streamingText: streamingText,
                                   isSending: isSending)
            } else {
                MessageListView(messages: sortedMessages,
                                 streamingText: streamingText,
                                 isSending: isSending,
                                 aiDisplayName: providerDisplayName,
                                 aiModel: currentModel)
            }
            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 12) { // pins bottom controls and prevents overlap
            VStack(spacing: 12) {
                if showSuggestions {
                    SuggestionChips(suggestions: defaultSuggestions)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                InputBar(text: $inputText, onSend: { Task { await send() } }, onMic: nil, onLive: nil, onPlus: { showPhotoPicker = true })
                    .disabled(isSending)
            }
            .background(
                Rectangle()
                    .fill(Color(.systemBackground))
                    .ignoresSafeArea()
            )
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showModelEditor) {
            let providerID = settingsQuery.first?.defaultProvider ?? "openai"
            let modelID = settingsQuery.first?.defaultModel ?? ""
            ModelSettingsView(providerID: providerID, modelID: modelID)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $pickerItems, maxSelectionCount: 4, matching: .images)
        .onChange(of: pickerItems) { _, newItems in
            Task {
                var datas: [Data] = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        datas.append(data)
                    }
                }
                attachments = datas
            }
        }
        .toolbar { toolbarContent }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if isDefaultTitle, let first = sortedMessages.first {
                updateChatTitle(from: first.content)
            }
            showSuggestions = chat.messages.isEmpty
        }
    }

    // MARK: - WebCanvas integration
    private var useWebCanvasFlag: Bool {
        settingsQuery.first?.useWebCanvas ?? true
    }

    private var currentThemeForCanvas: CanvasTheme {
        // Simple mapping: defer to system for now
        if let pref = settingsQuery.first?.interfaceTheme, pref == "dark" { return .dark }
        if let pref = settingsQuery.first?.interfaceTheme, pref == "light" { return .light }
        // Fall back to light; SwiftUI color scheme not available here without @Environment
        return .light
    }

    private struct WebCanvasContainer: View {
        let chat: Chat
        let messages: [Message]
        let streamingText: String?
        let isSending: Bool
        @StateObject private var controller = ChatCanvasController()
        @Environment(\.colorScheme) private var colorScheme
        @State private var didStartStream = false
        var body: some View {
            ChatCanvasView(controller: controller, theme: (colorScheme == .dark ? .dark : .light))
                .onAppear { loadAll() }
                .onChange(of: messages.count) { _, _ in loadAll() }
                .onChange(of: streamingText) { _, newVal in
                    guard let partial = newVal else { return }
                    // Start stream lazily only once
                    if !didStartStream {
                        controller.startStream(id: "current")
                        didStartStream = true
                    }
                    controller.appendDelta(id: "current", delta: partial)
                    controller.scrollToBottom()
                }
                .onChange(of: isSending) { _, sending in
                    if sending == false {
                        controller.endStream(id: "current")
                        controller.scrollToBottom()
                        didStartStream = false
                    }
                }
        }
        private func loadAll() {
            let items: [CanvasMessage] = messages.map { m in
                CanvasMessage(id: m.id.uuidString, role: m.role, content: m.content, createdAt: m.createdAt.timeIntervalSince1970)
            }
            controller.loadTranscript(items)
            controller.scrollToBottom()
        }
    }

    // Split out heavy view builder to speed up type checking
    private struct MessageListView: View {
        let messages: [Message]
        let streamingText: String?
        let isSending: Bool
        var aiDisplayName: String
        var aiModel: String
        var body: some View {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            if message.role == "assistant" {
                                MessageRow(message: message,
                                           aiDisplayName: aiDisplayName,
                                           aiModel: aiModel)
                            } else {
                                MessageRow(message: message)
                            }
                        }
                        if let partial = streamingText {
                            StreamingRow(partial: partial)
                        } else if isSending {
                            HStack { ProgressView(); Text("Thinking…").foregroundStyle(.secondary) }
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 72)
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
        }
    }

    private struct MessageRow: View {
        let message: Message
        // For assistant header
        var aiDisplayName: String = "AI"
        var aiModel: String = ""
        var body: some View {
            Group {
                if message.role == "assistant" {
                    // Full-bleed AI response (no bubble), with header
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.secondary)
                            Text("\(aiDisplayName) \(aiModel)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        AIResponseView(content: message.content)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                } else {
                    // User message with a subtle bubble
                    HStack(alignment: .top, spacing: 8) {
                        Text("You")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 32, alignment: .leading)
                        Text(message.content)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private struct StreamingRow: View {
        let partial: String
        var aiDisplayName: String = "AI"
        var aiModel: String = ""
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.secondary)
                    Text("\(aiDisplayName) \(aiModel)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                AIResponseView(content: partial)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Default back button preserved; no custom leading item
        ToolbarItem(placement: .principal) {
            Menu {
                // Model picker populated from AppSettings enabled lists
                ForEach(availableModelsForCurrentProvider(), id: \.self) { m in
                    Button(action: { setDefaultModel(m) }) {
                        HStack {
                            Text(m)
                            if m == (settingsQuery.first?.defaultModel ?? "") { Image(systemName: "checkmark") }
                        }
                    }
                }
                Divider()
                Button {
                    showModelEditor = true
                } label: {
                    Label("Model Info", systemImage: "info.circle")
                }
            } label: {
                HStack(spacing: 4) {
                    Text(currentModelDisplay()).font(.headline)
                    Image(systemName: "chevron.right").font(.caption)
                }
                .contentShape(Rectangle())
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { } label: { Image(systemName: "viewfinder.circle") }
        }
    }

    private func currentModelDisplay() -> String {
        let s = settingsQuery.first
        return s?.defaultModel.isEmpty == false ? (s?.defaultModel ?? "Model") : "Model"
    }

    private func availableModelsForCurrentProvider() -> [String] {
        let s = settingsQuery.first
        switch s?.defaultProvider ?? "openai" {
        case "openai": return s?.openAIEnabledModels ?? []
        case "anthropic": return s?.anthropicEnabledModels ?? []
        case "google": return s?.googleEnabledModels ?? []
        case "xai": return s?.xaiEnabledModels ?? []
        default: return []
        }
    }

    private func setDefaultModel(_ m: String) {
        guard let s = settingsQuery.first else { return }
        s.defaultModel = m
        try? modelContext.save()
    }

    private var defaultSuggestions: [SuggestionChipItem] {
        [
            .init(title: "Identify the best", subtitle: "high-performance pre-workouts"),
            .init(title: "Explore the latest", subtitle: "AI-powered research"),
            .init(title: "Plan a trip", subtitle: "2-day foodie itinerary"),
            .init(title: "Summarize a PDF", subtitle: "key points + action items"),
            .init(title: "Improve writing", subtitle: "tone and clarity suggestions"),
            .init(title: "Code review", subtitle: "spot bugs and edge cases")
        ]
    }

    private var contentBottomPadding: CGFloat {
        // Ensure chat content never collides with inset UI.
        let input: CGFloat = 44 + 24 // field height + margins
        let chips: CGFloat = showSuggestions ? (60 + 16) : 0
        return input + chips
    }

    private var sortedMessages: [Message] {
        chat.messages.sorted(by: { $0.createdAt < $1.createdAt })
    }

    private var isDefaultTitle: Bool {
        chat.title.isEmpty || chat.title == "New Chat"
    }

    @MainActor
    private func send() async {
        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }
        inputText = ""
        errorMessage = nil
        withAnimation { showSuggestions = false }

        // Add user message
        let userMsg = Message(role: "user", content: userText, chat: chat)
        modelContext.insert(userMsg)
        try? modelContext.save()

        isSending = true
        defer { isSending = false }

        do {
            // Resolve provider from settings
            let settings = settingsQuery.first ?? AppSettings()
            let providerID = settings.defaultProvider
            let model = settings.defaultModel

            let provider = try makeProvider(id: providerID)
            var aiMessages: [AIMessage] = []
            // Master system prompt first, then user-provided system prompt
            aiMessages.append(AIMessage(role: .system, content: MASTER_SYSTEM_PROMPT))
            let sys = settings.defaultSystemPrompt
            if sys.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                aiMessages.append(AIMessage(role: .system, content: sys))
            }

            // Use all previous messages except the just-inserted user message
            var previous = chat.messages.sorted(by: { $0.createdAt < $1.createdAt })
            if let last = previous.last, last.content == userText { previous.removeLast() }
            aiMessages.append(contentsOf: previous.map { m in
                AIMessage(role: m.role == "user" ? .user : .assistant, content: m.content)
            })

            // Compose the current user message with optional image parts
            let mime = "image/jpeg" // heuristic; data URL works for common types
            let imageParts = attachments.map { AIMessage.Part.imageData($0, mime: mime) }
            aiMessages.append(AIMessage(role: .user, parts: [.text(userText)] + imageParts))

            // Apply per-model overrides from ModelCapabilitiesStore
            let caps = ModelCapabilitiesStore.get(provider: providerID, model: model) // effective (user over default)
            let tempEff = caps?.preferredTemperature ?? settings.defaultTemperature
            let topPEff = caps?.preferredTopP
            let topKEff = caps?.preferredTopK
            let maxOutEff = min(settings.defaultMaxTokens, caps?.outputTokenLimit ?? settings.defaultMaxTokens)
            let userMaxOut = caps?.preferredMaxOutputTokens
            let finalMaxOut = userMaxOut.map { min($0, maxOutEff) } ?? maxOutEff
            let reasoningEff = caps?.preferredReasoningEffort
            let verbosityEff = caps?.preferredVerbosity

            let reply: String
            if let streaming = provider as? AIStreamingProvider {
                streamingText = ""
                reply = try await streaming.streamChat(
                    messages: aiMessages,
                    model: model,
                    temperature: tempEff,
                    topP: topPEff,
                    topK: topKEff,
                    maxOutputTokens: finalMaxOut,
                    reasoningEffort: reasoningEff,
                    verbosity: verbosityEff
                ) { delta in
                    Task { @MainActor in
                        self.streamingText = (self.streamingText ?? "") + delta
                    }
                }
            } else if let adv = provider as? AIProviderAdvanced {
                reply = try await adv.sendChat(
                    messages: aiMessages,
                    model: model,
                    temperature: tempEff,
                    topP: topPEff,
                    topK: topKEff,
                    maxOutputTokens: finalMaxOut,
                    reasoningEffort: reasoningEff,
                    verbosity: verbosityEff
                )
            } else {
                reply = try await provider.sendChat(messages: aiMessages, model: model)
            }

            // Add assistant message
            streamingText = nil
            let aiMsg = Message(role: "assistant", content: reply, chat: chat)
            modelContext.insert(aiMsg)

            // Update title if still default
            if isDefaultTitle {
                updateChatTitle(from: userText)
            }

            try? modelContext.save()
            attachments.removeAll()
        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    // MARK: - Provider header helpers
    private var providerDisplayName: String {
        let p = settingsQuery.first?.defaultProvider ?? "openai"
        return ProviderID(rawValue: p)?.displayName ?? "AI"
    }
    private var currentModel: String {
        settingsQuery.first?.defaultModel ?? ""
    }

    @State private var showModelEditor: Bool = false

    private func updateChatTitle(from text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        chat.title = String(trimmed.prefix(40))
        try? modelContext.save()
    }

    private func makeProvider(id: String) throws -> AIProvider {
        switch id {
        case "openai":
            let key = (try? KeychainService.read(key: "openai_api_key")) ?? ""
            guard !key.isEmpty else {
                throw NSError(domain: "Settings", code: -1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not set. Open Settings to add your key."])
            }
            return OpenAIProvider(apiKey: key)
        case "anthropic":
            let key = (try? KeychainService.read(key: "anthropic_api_key")) ?? ""
            guard !key.isEmpty else {
                throw NSError(domain: "Settings", code: -1, userInfo: [NSLocalizedDescriptionKey: "Anthropic API key not set. Open Settings to add your key."])
            }
            return AnthropicProvider(apiKey: key)
        case "google":
            let key = (try? KeychainService.read(key: "google_api_key")) ?? ""
            guard !key.isEmpty else {
                throw NSError(domain: "Settings", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google API key not set. Open Settings to add your key."])
            }
            return GoogleProvider(apiKey: key)
        case "xai":
            let key = (try? KeychainService.read(key: "xai_api_key")) ?? ""
            guard !key.isEmpty else {
                throw NSError(domain: "Settings", code: -1, userInfo: [NSLocalizedDescriptionKey: "XAI API key not set. Open Settings to add your key."])
            }
            return XAIProvider(apiKey: key)
        default:
            throw NSError(domain: "Provider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported provider: \(id)"])
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Chat.self, Message.self, AppSettings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    let chat = Chat(title: "Preview Chat")
    context.insert(chat)
    context.insert(Message(role: "user", content: "Hello!", chat: chat))
    return NavigationStack {
        ChatView(chat: chat)
    }
    .modelContainer(container)
}
````

## File: ChatApp/ContentView.swift
````swift
//
//  ContentView.swift
//  ChatApp
//
//  Created by Kosta Milovanovic on 9/4/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Chat.createdAt, order: .reverse) private var chats: [Chat]
    @State private var showingSettings = false
    @State private var initialChat: Chat? = nil
    @State private var showInitialChat = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(chats) { chat in
                    NavigationLink {
                        ChatView(chat: chat)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chat.title.isEmpty ? "New Chat" : chat.title)
                                .font(.headline)
                            if let last = chat.messages.sorted(by: { $0.createdAt < $1.createdAt }).last {
                                Text("\(last.role.capitalized): \(last.content)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteChat(chat)
                        } label: {
                            Label("Delete Chat", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: deleteChats)
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        addChat()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New Chat")
                }
                ToolbarItem(placement: .automatic) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(context: modelContext)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled(false)
            }
            .onAppear { ensureInitialChatIfNeeded() }
        }
        .navigationDestination(isPresented: $showInitialChat) {
            if let chat = initialChat {
                ChatView(chat: chat)
            } else {
                EmptyView()
            }
        }
    }

    private func addChat() {
        withAnimation {
            let chat = Chat(title: "")
            modelContext.insert(chat)
        }
    }

    private func deleteChats(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(chats[index])
            }
        }
    }

    private func deleteChat(_ chat: Chat) {
        withAnimation {
            modelContext.delete(chat)
        }
    }

    private func ensureInitialChatIfNeeded() {
        guard chats.isEmpty, initialChat == nil else { return }
        let chat = Chat(title: "")
        modelContext.insert(chat)
        try? modelContext.save()
        initialChat = chat
        showInitialChat = true
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Chat.self, Message.self, AppSettings.self], inMemory: true)
}
````

## File: ChatApp/EnvLoader.swift
````swift
import Foundation

/// Development-only .env loader. The app copies Env/.env into the app bundle at build time (Debug only)
/// via a Run Script build phase. We parse it at runtime to prime the Keychain on first run so you don't
/// have to paste keys repeatedly while iterating.
struct EnvLoader {
    static func loadFromBundle() -> [String: String] {
        guard let url = Bundle.main.url(forResource: "DevSecrets", withExtension: "env") else {
            return [:]
        }
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [:] }
        var dict: [String: String] = [:]
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            let parts = trimmed.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            var value = parts[1].trimmingCharacters(in: .whitespaces)
            if value.hasPrefix("\"") && value.hasSuffix("\"") && value.count >= 2 {
                value = String(value.dropFirst().dropLast())
            }
            dict[key] = value
        }
        return dict
    }
}
````

## File: ChatApp/FlowLayout.swift
````swift
// UI/FlowLayout.swift
import SwiftUI

// Simple flow layout for inline elements that need wrapping (e.g., inline math + text)
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: width, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.width {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            view.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
````

## File: ChatApp/GoogleProvider.swift
````swift
// Providers/GoogleProvider.swift
import Foundation

struct GoogleProvider: AIProviderAdvanced {
    let id = "google"
    let displayName = "Google Gemini"

    private let client = NetworkClient.shared
    private let apiKey: String
    private let apiBase = URL(string: "https://generativelanguage.googleapis.com/v1beta")!

    init(apiKey: String) { self.apiKey = apiKey }

    func listModels() async throws -> [String] {
        return try await ProviderAPIs.listModels(provider: .google, apiKey: apiKey)
    }

    func sendChat(messages: [AIMessage], model: String) async throws -> String {
        try await sendChat(messages: messages, model: model, temperature: nil, topP: nil, topK: nil, maxOutputTokens: nil, reasoningEffort: nil, verbosity: nil)
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
        struct Part: Encodable {
            let text: String?
            let inlineData: InlineData?
            struct InlineData: Encodable { let mimeType: String; let data: String }
        }
        struct Content: Encodable { let role: String; let parts: [Part] }
        struct GenerationConfig: Encodable { let temperature: Double?; let topP: Double?; let topK: Int?; let maxOutputTokens: Int?; let stopSequences: [String]? }
        struct Safety: Encodable { let category: String; let threshold: String }
        struct SystemInstruction: Encodable { let role: String = "system"; let parts: [Part] }
        struct Req: Encodable {
            let contents: [Content]
            let systemInstruction: SystemInstruction?
            let generationConfig: GenerationConfig?
            let safetySettings: [Safety]?
        }
        struct Resp: Decodable {
            struct Candidate: Decodable { struct CContent: Decodable { struct P: Decodable { let text: String? }
                    let parts: [P]? }
                let content: CContent? }
            let candidates: [Candidate]?
        }

        // System prompt
        let systemText = messages.filter { $0.role == .system }
            .flatMap { msg in msg.parts.compactMap { if case let .text(t) = $0 { return t } else { return nil } } }
            .joined(separator: "\n\n")
        let sys = systemText.isEmpty ? nil : SystemInstruction(parts: [Part(text: systemText, inlineData: nil)])

        func parts(from p: [AIMessage.Part]) -> [Part] {
            p.map { item in
                switch item {
                case .text(let t): return Part(text: t, inlineData: nil)
                case .imageData(let data, let mime): return Part(text: nil, inlineData: .init(mimeType: mime, data: data.base64EncodedString()))
                }
            }
        }

        let contents: [Content] = messages.compactMap { m in
            switch m.role {
            case .system: return nil
            case .user: return Content(role: "user", parts: parts(from: m.parts))
            case .assistant: return Content(role: "model", parts: parts(from: m.parts))
            }
        }

        let stops = ModelCapabilitiesStore.get(provider: id, model: model)?.stopSequences
        let gen = GenerationConfig(temperature: temperature, topP: topP, topK: topK, maxOutputTokens: maxOutputTokens, stopSequences: stops)
        let safetyOff: [Safety] = ["HARM_CATEGORY_HARASSMENT",
                                    "HARM_CATEGORY_HATE_SPEECH",
                                    "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                                    "HARM_CATEGORY_DANGEROUS_CONTENT"].map { Safety(category: $0, threshold: "BLOCK_NONE") }

        let url = apiBase.appendingPathComponent("models/\(model):generateContent")
        var urlReq = URLRequest(url: URL(string: url.absoluteString + "?key=\(apiKey)")!)
        urlReq.httpMethod = "POST"
        urlReq.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Inspect stored preference for safety off
        let caps = ModelCapabilitiesStore.get(provider: id, model: model)
        let disableSafety = caps?.disableSafetyFilters ?? true
        let req = Req(contents: contents,
                      systemInstruction: sys,
                      generationConfig: gen,
                      safetySettings: disableSafety ? safetyOff : nil)
        urlReq.httpBody = try JSONEncoder().encode(req)

        let (data, resp) = try await client.session.data(for: urlReq)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let http = resp as? HTTPURLResponse
            let err = String(data: data, encoding: .utf8) ?? "Error"
            throw NSError(domain: "Google", code: http?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: err])
        }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        let text = decoded.candidates?.first?.content?.parts?.compactMap { $0.text }.joined(separator: "\n") ?? ""
        return text
    }
}
````

## File: ChatApp/ImageProvider.swift
````swift
// Providers/ImageProvider.swift
import Foundation

protocol ImageProvider {
    var id: String { get }
    var displayName: String { get }
    func listModels() async throws -> [String]
    func generateImage(prompt: String, model: String) async throws -> Data
}
````

## File: ChatApp/Info.plist
````
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>UIBackgroundModes</key>
	<array>
		<string>remote-notification</string>
	</array>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>Allow selecting images to include in AI prompts.</string>
</dict>
</plist>
````

## File: ChatApp/Item.swift
````swift
//
//  Item.swift
//  ChatApp
//
//  Created by Kosta Milovanovic on 9/4/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
````

## File: ChatApp/KeychainService.swift
````swift
// Services/KeychainService.swift
import Foundation
import Security

enum KeychainService {
    static func save(key: String, value: String) throws {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrAccount as String:      key,
            kSecValueData as String:        data,
            kSecAttrAccessible as String:   kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "Keychain", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to save keychain item: \(status)"])
        }
    }

    static func read(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrAccount as String:      key,
            kSecReturnData as String:       true,
            kSecMatchLimit as String:       kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw NSError(domain: "Keychain", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to read keychain item: \(status)"])
        }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
````

## File: ChatApp/MathWebView.swift
````swift
import SwiftUI
import WebKit

// Lightweight KaTeX-based math renderer using WKWebView.
// - No network required if you later bundle local KaTeX assets.
// - For now, it pulls from jsDelivr CDN as a stopgap.
// - Height auto-sizes to fit rendered content.

struct MathWebView: UIViewRepresentable {
    let latex: String
    var displayMode: Bool = true // true = block, false = inline

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let conf = WKWebViewConfiguration()
        conf.defaultWebpagePreferences.allowsContentJavaScript = true
        conf.limitsNavigationsToAppBoundDomains = false
        let web = WKWebView(frame: .zero, configuration: conf)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.isScrollEnabled = true // allow horizontal scroll if needed
        web.navigationDelegate = context.coordinator

        // Prefer local KaTeX assets if bundled: ChatApp.app/KaTeX/{katex.min.js, auto-render.min.js, katex.min.css}
        let assetsURL = Bundle.main.url(forResource: "KaTeX", withExtension: nil)
        let html = Self.htmlTemplate(forLatex: latex, displayMode: displayMode, useLocalAssets: assetsURL != nil)
        web.loadHTMLString(html, baseURL: assetsURL)
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Re-render when latex changes
        let js = "renderLatex(\"\(Self.escapeForJS(latex))\", \(displayMode ? "true" : "false"));"
        uiView.evaluateJavaScript(js, completionHandler: nil)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Resize after initial render
            webView.evaluateJavaScript("document.body.scrollHeight") { result, _ in
                if let h = result as? CGFloat, h > 0 {
                    var f = webView.frame
                    f.size.height = h
                    webView.frame = f
                }
            }
        }
    }
}

private extension MathWebView {
    static func escapeForJS(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
         .replacingOccurrences(of: "\n", with: "\\n")
    }

    static func htmlTemplate(forLatex latex: String, displayMode: Bool, useLocalAssets: Bool) -> String {
        // If local assets exist, we reference relative paths and load with baseURL = KaTeX bundle path.
        // Otherwise, we fall back to CDN URLs.
        let css = useLocalAssets ? "katex.min.css" : "https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css"
        let js  = useLocalAssets ? "katex.min.js" : "https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"
        let auto = useLocalAssets ? "auto-render.min.js" : "https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js"
        let escaped = escapeForJS(latex)
        let dm = displayMode ? "true" : "false"
        return """
        <!DOCTYPE html>
        <html>
        <head>
          <meta name=\"viewport\" content=\"width=device-width, initial-scale=1, maximum-scale=1\">
          <link rel=\"stylesheet\" href=\"\(css)\">
          <style>
            body { margin: 0; padding: 0; background: transparent; color: inherit; }
            #math { padding: 4px 0; font-size: 16px; }
          </style>
        </head>
        <body>
          <div id=\"math\"></div>
          <script src=\"\(js)\"></script>
          <script src=\"\(auto)\"></script>
          <script>
            function renderLatex(lx, disp) {
              try {
                const el = document.getElementById('math');
                el.innerHTML = '';
                katex.render(lx, el, { throwOnError: false, displayMode: disp });
                setTimeout(function(){ if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.size) { try { window.webkit.messageHandlers.size.postMessage(document.body.scrollHeight); } catch(e){} } }, 0);
              } catch (e) { console.error(e); }
            }
            renderLatex(\"\(escaped)\", \(dm));
          </script>
        </body>
        </html>
        """
    }
}
````

## File: ChatApp/ModelCapabilities.swift
````swift
// Services/ModelCapabilities.swift
import Foundation

// Lightweight, codable model capability snapshot used for UI defaults and validation
struct ProviderModelInfo: Codable, Equatable {
    let id: String
    var displayName: String?
    var inputTokenLimit: Int?
    var outputTokenLimit: Int?
    var maxTemperature: Double?
    var supportsPromptCaching: Bool?

    // Preferred request-time defaults (user overrides live here; provider defaults may populate some)
    var preferredTemperature: Double?
    var preferredTopP: Double?
    var preferredTopK: Int?
    var preferredMaxOutputTokens: Int?
    var preferredReasoningEffort: String?   // e.g., minimal|low|medium|high
    var preferredVerbosity: String?         // e.g., low|medium|high
    var disableSafetyFilters: Bool?         // Google safety off
    var preferredPresencePenalty: Double?
    var preferredFrequencyPenalty: Double?
    var stopSequences: [String]?
    // Anthropic-specific
    var anthropicThinkingEnabled: Bool?
    var anthropicThinkingBudget: Int?
    var enablePromptCaching: Bool?

    // Convenience defaults
    static func fallback(id: String) -> ProviderModelInfo {
        ProviderModelInfo(id: id,
                          displayName: nil,
                          inputTokenLimit: nil,
                          outputTokenLimit: nil,
                          maxTemperature: 2.0,
                          supportsPromptCaching: false,
                          preferredTemperature: nil,
                          preferredTopP: nil,
                          preferredTopK: nil,
                          preferredMaxOutputTokens: nil,
                          preferredReasoningEffort: nil,
                          preferredVerbosity: nil,
                          disableSafetyFilters: nil,
                          preferredPresencePenalty: nil,
                          preferredFrequencyPenalty: nil,
                          stopSequences: nil,
                          anthropicThinkingEnabled: nil,
                          anthropicThinkingBudget: nil,
                          enablePromptCaching: nil)
    }
}

// Entry that keeps both remote‑derived defaults and user overrides.
private struct ModelCapsEntry: Codable, Equatable {
    var `default`: ProviderModelInfo
    var user: ProviderModelInfo?
}

// Persistent cache in UserDefaults keyed by provider → model, storing defaults+overrides.
enum ModelCapabilitiesStore {
    private static let keyV2 = "ModelCaps.v2"
    private static let keyV1 = "ModelCaps.v1" // migration from older single-layer store

    // v2 payload
    private static func loadAllV2() -> [String: [String: ModelCapsEntry]]? {
        guard let data = UserDefaults.standard.data(forKey: keyV2) else { return nil }
        return try? JSONDecoder().decode([String: [String: ModelCapsEntry]].self, from: data)
    }

    private static func saveAllV2(_ map: [String: [String: ModelCapsEntry]]) {
        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: keyV2)
        }
    }

    // Migration from v1 → v2 (defaults only)
    private static func migrateIfNeeded() -> [String: [String: ModelCapsEntry]] {
        if let v2 = loadAllV2() { return v2 }
        guard let data = UserDefaults.standard.data(forKey: keyV1),
              let old = try? JSONDecoder().decode([String: [String: ProviderModelInfo]].self, from: data) else {
            return [:]
        }
        var map: [String: [String: ModelCapsEntry]] = [:]
        for (provider, items) in old {
            var per: [String: ModelCapsEntry] = [:]
            for (model, info) in items { per[model] = ModelCapsEntry(default: info, user: nil) }
            map[provider] = per
        }
        saveAllV2(map)
        return map
    }

    // Public API
    static func get(provider: String, model: String) -> ProviderModelInfo? {
        let all = migrateIfNeeded()
        guard let entry = all[provider]?[model] else { return nil }
        return entry.user ?? entry.default
    }

    static func getPair(provider: String, model: String) -> (defaults: ProviderModelInfo?, user: ProviderModelInfo?) {
        let all = migrateIfNeeded()
        guard let entry = all[provider]?[model] else { return (nil, nil) }
        return (entry.default, entry.user)
    }

    static func putDefault(provider: String, infos: [ProviderModelInfo]) {
        var all = migrateIfNeeded()
        var per = all[provider] ?? [:]
        for info in infos {
            if let existing = per[info.id] {
                per[info.id] = ModelCapsEntry(default: info, user: existing.user) // keep user override
            } else {
                per[info.id] = ModelCapsEntry(default: info, user: nil)
            }
        }
        all[provider] = per
        saveAllV2(all)
    }

    static func putUser(provider: String, model: String, info: ProviderModelInfo?) {
        var all = migrateIfNeeded()
        var per = all[provider] ?? [:]
        if var entry = per[model] {
            entry.user = info
            per[model] = entry
        } else {
            // no defaults yet; store user override independently
            per[model] = ModelCapsEntry(default: ProviderModelInfo.fallback(id: model), user: info)
        }
        all[provider] = per
        saveAllV2(all)
    }

    static func clearUser(provider: String, model: String) {
        var all = migrateIfNeeded()
        guard var entry = all[provider]?[model] else { return }
        entry.user = nil
        all[provider]?[model] = entry
        saveAllV2(all)
    }
}
````

## File: ChatApp/Models.swift
````swift
// Models.swift
import Foundation
import SwiftData

@Model
final class Chat: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Message.chat) var messages: [Message]

    init(id: UUID = UUID(), title: String, createdAt: Date = Date(), messages: [Message] = []) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.messages = messages
    }
}

@Model
final class Message: Identifiable {
    @Attribute(.unique) var id: UUID
    // "user" or "assistant"
    var role: String
    var content: String
    var createdAt: Date
    var chat: Chat?

    init(id: UUID = UUID(), role: String, content: String, createdAt: Date = Date(), chat: Chat? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.chat = chat
    }
}

@Model
final class AppSettings: Identifiable {
    @Attribute(.unique) var id: UUID
    // Provider identifier, e.g., "openai"
    var defaultProvider: String
    // Model identifier for the provider
    var defaultModel: String
    // Default chat system prompt
    var defaultSystemPrompt: String
    // Sampling controls
    var defaultTemperature: Double
    var defaultMaxTokens: Int

    // Enabled models per provider (controls which appear in picker)
    var openAIEnabledModels: [String]
    var anthropicEnabledModels: [String]
    var googleEnabledModels: [String]
    var xaiEnabledModels: [String]

    // Interface preferences
    // theme: system | light | dark
    var interfaceTheme: String
    // font style: system | serif | rounded | mono
    var interfaceFontStyle: String
    // discrete text size index 0...4 (XS..XL)
    var interfaceTextSizeIndex: Int
    // chat bubble color palette id (one of predefined ids)
    var chatBubbleColorID: String
    // Prefer prompt caching when supported by the selected provider/model
    var promptCachingEnabled: Bool
    // Feature flag: use WKWebView WebCanvas for transcript rendering
    var useWebCanvas: Bool

    init(
        id: UUID = UUID(),
        defaultProvider: String = "openai",
        defaultModel: String = "gpt-4o-mini",
        defaultSystemPrompt: String = "You are a helpful AI assistant.",
        defaultTemperature: Double = 1.0,
        defaultMaxTokens: Int = 1024,
        openAIEnabledModels: [String] = ["gpt-4o-mini", "gpt-4o", "gpt-4.1-mini"],
        anthropicEnabledModels: [String] = ["claude-3-5-sonnet", "claude-3-opus", "claude-3-haiku"],
        googleEnabledModels: [String] = ["gemini-1.5-pro", "gemini-1.5-flash"],
        xaiEnabledModels: [String] = ["grok-beta"],
        interfaceTheme: String = "system",
        interfaceFontStyle: String = "system",
        interfaceTextSizeIndex: Int = 2,
        chatBubbleColorID: String = "teal",
        promptCachingEnabled: Bool = false,
        useWebCanvas: Bool = true
    ) {
        self.id = id
        self.defaultProvider = defaultProvider
        self.defaultModel = defaultModel
        self.defaultSystemPrompt = defaultSystemPrompt
        self.defaultTemperature = defaultTemperature
        self.defaultMaxTokens = defaultMaxTokens
        self.openAIEnabledModels = openAIEnabledModels
        self.anthropicEnabledModels = anthropicEnabledModels
        self.googleEnabledModels = googleEnabledModels
        self.xaiEnabledModels = xaiEnabledModels
        self.interfaceTheme = interfaceTheme
        self.interfaceFontStyle = interfaceFontStyle
        self.interfaceTextSizeIndex = interfaceTextSizeIndex
        self.chatBubbleColorID = chatBubbleColorID
        self.promptCachingEnabled = promptCachingEnabled
        self.useWebCanvas = useWebCanvas
    }
}
````

## File: ChatApp/NetworkClient.swift
````swift
// Networking/NetworkClient.swift
import Foundation

struct NetworkClient {
    let session: URLSession

    static let shared = NetworkClient(session: {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        return URLSession(configuration: config)
    }())

    func postJSON<T: Encodable>(url: URL, body: T, headers: [String: String]) async throws -> (Data, HTTPURLResponse) {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (k, v) in headers {
            req.setValue(v, forHTTPHeaderField: k)
        }
        req.httpBody = try JSONEncoder().encode(body)
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, http)
    }

    func get(url: URL, headers: [String: String] = [:]) async throws -> (Data, HTTPURLResponse) {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        for (k, v) in headers {
            req.setValue(v, forHTTPHeaderField: k)
        }
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, http)
    }
}
````

## File: ChatApp/OpenAIImageProvider.swift
````swift
// Providers/OpenAIImageProvider.swift
import Foundation

struct OpenAIImageProvider: ImageProvider {
    let id = "openai-images"
    let displayName = "OpenAI Images"

    private let client = NetworkClient.shared
    private let apiBase = URL(string: "https://api.openai.com/v1")!
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func listModels() async throws -> [String] {
        // Defaults
        return ["gpt-image-1"]
    }

    func generateImage(prompt: String, model: String) async throws -> Data {
        struct Req: Encodable {
            let model: String
            let prompt: String
            let size: String
            let response_format: String
        }
        struct Resp: Decodable {
            struct DataItem: Decodable { let b64_json: String }
            let data: [DataItem]
        }

        let url = apiBase.appendingPathComponent("images/generations")
        let body = Req(model: model, prompt: prompt, size: "1024x1024", response_format: "b64_json")
        let (data, http) = try await client.postJSON(url: url, body: body, headers: [
            "Authorization": "Bearer \(apiKey)"
        ])
        guard (200..<300).contains(http.statusCode) else {
            let err = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAIImages", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: err])
        }

        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        guard let first = decoded.data.first?.b64_json, let imgData = Data(base64Encoded: first) else {
            throw NSError(domain: "OpenAIImages", code: -1, userInfo: [NSLocalizedDescriptionKey: "No image data"])
        }
        return imgData
    }
}
````

## File: ChatApp/OpenAIProvider.swift
````swift
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
        try await sendChat(messages: messages, model: model, temperature: nil, topP: nil, topK: nil, maxOutputTokens: nil, reasoningEffort: nil, verbosity: nil)
    }

    // Responses API with multimodal support
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
            let top_p: Double?
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
                      top_p: topP,
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
        topP: Double?,
        topK: Int?,
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
            let top_p: Double?
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
                          top_p: topP,
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
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            // Surface a helpful, user-facing error instead of NSURLError -1011
            let message: String
            switch http.statusCode {
            case 400: message = "OpenAI: 400 Bad Request — check model name and payload."
            case 401: message = "OpenAI: 401 Unauthorized — check API key in Settings."
            case 403: message = "OpenAI: 403 Forbidden — key lacks access to this model."
            case 404: message = "OpenAI: 404 Not Found — endpoint or resource not found."
            case 429: message = "OpenAI: 429 Rate limited — slow down or try later."
            case 500...599: message = "OpenAI: Server error (\(http.statusCode)). Try again."
            default: message = "OpenAI: HTTP \(http.statusCode)."
            }
            throw NSError(domain: "OpenAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
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
````

## File: ChatApp/ProviderAPIs.swift
````swift
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

    // Fetch detailed model info where the provider exposes it; otherwise return best‑effort defaults
    static func listModelInfos(provider: ProviderID, apiKey: String) async throws -> [ProviderModelInfo] {
        switch provider {
        case .google:
            // Google Generative Language API exposes token limits + temperature in the model resource
            let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)")!
            let (data, http) = try await client.get(url: url)
            guard (200..<300).contains(http.statusCode) else {
                throw NSError(domain: "Google", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Error"])
            }
            struct ModelList: Decodable {
                struct Item: Decodable {
                    let name: String
                    let displayName: String?
                    let inputTokenLimit: Int?
                    let outputTokenLimit: Int?
                    let temperature: Double?
                    let topP: Double?
                    let topK: Int?
                    let thinking: Bool?
                }
                let models: [Item]?
            }
            let decoded = try JSONDecoder().decode(ModelList.self, from: data)
            let infos = (decoded.models ?? []).map { item in
                ProviderModelInfo(id: item.name,
                                  displayName: item.displayName,
                                  inputTokenLimit: item.inputTokenLimit,
                                  outputTokenLimit: item.outputTokenLimit,
                                  maxTemperature: item.temperature ?? 2.0,
                                  supportsPromptCaching: item.thinking ?? false, // treat thinking support as caching-like flag
                                  preferredTemperature: item.temperature,
                                  preferredTopP: item.topP,
                                  preferredTopK: item.topK,
                                  preferredMaxOutputTokens: item.outputTokenLimit,
                                  preferredReasoningEffort: nil,
                                  preferredVerbosity: nil,
                                  disableSafetyFilters: true)
            }
            // Update defaults layer immediately
            ModelCapabilitiesStore.putDefault(provider: provider.rawValue, infos: infos)
            return infos

        case .openai:
            // OpenAI /v1/models lists models but does not currently return token limits via API.
            // Return conservative defaults; UI will still become dynamic based on these values.
            let (data, http) = try await client.get(url: URL(string: "https://api.openai.com/v1/models")!, headers: [
                "Authorization": "Bearer \(apiKey)"
            ])
            guard (200..<300).contains(http.statusCode) else {
                throw NSError(domain: "OpenAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Error"])
            }
            struct ModelList: Decodable { struct Item: Decodable { let id: String }
                let data: [Item] }
            let decoded = try JSONDecoder().decode(ModelList.self, from: data)
            let infos = decoded.data.map { item in
                // Heuristic defaults. Adjust as needed when OpenAI exposes richer metadata.
                ProviderModelInfo(id: item.id,
                                  displayName: nil,
                                  inputTokenLimit: nil,
                                  outputTokenLimit: 8192,
                                  maxTemperature: 2.0,
                                  supportsPromptCaching: false)
            }
            ModelCapabilitiesStore.putDefault(provider: provider.rawValue, infos: infos)
            return infos

        case .anthropic:
            // Anthropic models endpoint lists IDs; public per‑model limits are documented, not returned here.
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
            // Conservative, well‑known defaults by common family name. Values are a best‑effort guide.
            func defaults(for id: String) -> (input: Int?, output: Int?, temp: Double, caching: Bool) {
                // Anthropic does not return limits from /v1/models; use safe, generic defaults.
                // Values here are conservative placeholders for UI bounds only.
                return (input: nil, output: 8_192, temp: 2.0, caching: true)
            }
            let infos = decoded.data.map { item in
                let d = defaults(for: item.id)
                return ProviderModelInfo(id: item.id,
                                         displayName: nil,
                                         inputTokenLimit: d.input,
                                         outputTokenLimit: d.output,
                                         maxTemperature: d.temp,
                                         supportsPromptCaching: d.caching)
            }
            ModelCapabilitiesStore.putDefault(provider: provider.rawValue, infos: infos)
            return infos

        case .xai:
            // xAI currently documents models and limits; model listing endpoint may vary by account.
            // Fallback to the generic list and provide broadly safe defaults.
            let (data, http) = try await client.get(url: URL(string: "https://api.x.ai/v1/models")!, headers: [
                "Authorization": "Bearer \(apiKey)"
            ])
            guard (200..<300).contains(http.statusCode) else {
                // if listing fails, synthesize common IDs to seed UI
                let common = ["grok-3-mini", "grok-3-mini-high", "grok-2", "grok-beta"]
                return common.map { ProviderModelInfo(id: $0, displayName: nil, inputTokenLimit: 131_072, outputTokenLimit: 8_192, maxTemperature: 2.0, supportsPromptCaching: true) }
            }
            struct ModelList: Decodable { struct Item: Decodable { let id: String }
                let data: [Item] }
            let decoded = try JSONDecoder().decode(ModelList.self, from: data)
            let infos = decoded.data.map { item in
                ProviderModelInfo(id: item.id, displayName: nil, inputTokenLimit: 131_072, outputTokenLimit: 8_192, maxTemperature: 2.0, supportsPromptCaching: true)
            }
            ModelCapabilitiesStore.putDefault(provider: provider.rawValue, infos: infos)
            return infos
        }
    }
}
````

## File: ChatApp/SettingsStore.swift
````swift
// Services/SettingsStore.swift
import Foundation
import SwiftData

@MainActor
final class SettingsStore: ObservableObject {
    @Published var defaultProvider: String
    @Published var defaultModel: String
    @Published var openAIAPIKey: String
    @Published var anthropicAPIKey: String
    @Published var googleAPIKey: String
    @Published var xaiAPIKey: String

    // Default chat controls
    @Published var systemPrompt: String
    @Published var temperature: Double
    @Published var maxTokens: Int

    // Enabled model lists per provider
    @Published var openAIEnabled: Set<String>
    @Published var anthropicEnabled: Set<String>
    @Published var googleEnabled: Set<String>
    @Published var xaiEnabled: Set<String>

    // Interface preferences
    @Published var interfaceTheme: String // system | light | dark
    @Published var interfaceFontStyle: String // system | serif | rounded | mono
    @Published var interfaceTextSizeIndex: Int // 0...4
    @Published var chatBubbleColorID: String // palette id
    @Published var promptCachingEnabled: Bool
    @Published var useWebCanvas: Bool

    private let OPENAI_KEY_KEYCHAIN = "openai_api_key"
    private let ANTHROPIC_KEY_KEYCHAIN = "anthropic_api_key"
    private let GOOGLE_KEY_KEYCHAIN = "google_api_key"
    private let XAI_KEY_KEYCHAIN = "xai_api_key"

    private let context: ModelContext
    private var settings: AppSettings

    init(context: ModelContext) {
        self.context = context

        // Fetch or create AppSettings
        let fetch = FetchDescriptor<AppSettings>()
        if let existing = try? context.fetch(fetch).first {
            self.settings = existing
        } else {
            let s = AppSettings()
            context.insert(s)
            self.settings = s
            try? context.save()
        }

        // Prepare API keys using locals first (avoid touching self before full init)
        var openAIKeyLocal = (try? KeychainService.read(key: OPENAI_KEY_KEYCHAIN)) ?? ""
        var anthropicKeyLocal = (try? KeychainService.read(key: ANTHROPIC_KEY_KEYCHAIN)) ?? ""
        var googleKeyLocal = (try? KeychainService.read(key: GOOGLE_KEY_KEYCHAIN)) ?? ""
        var xaiKeyLocal = (try? KeychainService.read(key: XAI_KEY_KEYCHAIN)) ?? ""

        #if DEBUG
        // Prime from DevSecrets.env (copied to bundle in Debug) if Keychain slots are empty
        if openAIKeyLocal.isEmpty || anthropicKeyLocal.isEmpty || googleKeyLocal.isEmpty || xaiKeyLocal.isEmpty {
            let env = EnvLoader.loadFromBundle()
            func prime(_ key: String, _ storageKey: String, current: inout String) {
                if current.isEmpty, let v = env[key], v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    current = v
                    try? KeychainService.save(key: storageKey, value: v)
                }
            }
            prime("OPENAI_API_KEY", OPENAI_KEY_KEYCHAIN, current: &openAIKeyLocal)
            prime("ANTHROPIC_API_KEY", ANTHROPIC_KEY_KEYCHAIN, current: &anthropicKeyLocal)
            prime("GOOGLE_API_KEY", GOOGLE_KEY_KEYCHAIN, current: &googleKeyLocal)
            prime("XAI_API_KEY", XAI_KEY_KEYCHAIN, current: &xaiKeyLocal)
        }
        #endif

        // Now assign all @Published stored properties
        self.defaultProvider = settings.defaultProvider
        self.defaultModel = settings.defaultModel

        self.openAIAPIKey = openAIKeyLocal
        self.anthropicAPIKey = anthropicKeyLocal
        self.googleAPIKey = googleKeyLocal
        self.xaiAPIKey = xaiKeyLocal

        self.systemPrompt = settings.defaultSystemPrompt
        self.temperature = settings.defaultTemperature
        self.maxTokens = settings.defaultMaxTokens

        self.openAIEnabled = Set(settings.openAIEnabledModels)
        self.anthropicEnabled = Set(settings.anthropicEnabledModels)
        self.googleEnabled = Set(settings.googleEnabledModels)
        self.xaiEnabled = Set(settings.xaiEnabledModels)

        self.interfaceTheme = settings.interfaceTheme
        self.interfaceFontStyle = settings.interfaceFontStyle
        self.interfaceTextSizeIndex = settings.interfaceTextSizeIndex
        self.chatBubbleColorID = settings.chatBubbleColorID
        self.promptCachingEnabled = settings.promptCachingEnabled
        self.useWebCanvas = settings.useWebCanvas
    }

    func save() {
        settings.defaultProvider = defaultProvider
        settings.defaultModel = defaultModel
        settings.defaultSystemPrompt = systemPrompt
        settings.defaultTemperature = temperature
        settings.defaultMaxTokens = maxTokens
        settings.openAIEnabledModels = Array(openAIEnabled).sorted()
        settings.anthropicEnabledModels = Array(anthropicEnabled).sorted()
        settings.googleEnabledModels = Array(googleEnabled).sorted()
        settings.xaiEnabledModels = Array(xaiEnabled).sorted()
        settings.interfaceTheme = interfaceTheme
        settings.interfaceFontStyle = interfaceFontStyle
        settings.interfaceTextSizeIndex = interfaceTextSizeIndex
        settings.chatBubbleColorID = chatBubbleColorID
        settings.promptCachingEnabled = promptCachingEnabled
        settings.useWebCanvas = useWebCanvas
        try? context.save()

        saveKeychain(key: OPENAI_KEY_KEYCHAIN, value: openAIAPIKey)
        saveKeychain(key: ANTHROPIC_KEY_KEYCHAIN, value: anthropicAPIKey)
        saveKeychain(key: GOOGLE_KEY_KEYCHAIN, value: googleAPIKey)
        saveKeychain(key: XAI_KEY_KEYCHAIN, value: xaiAPIKey)
    }

    func apiKey(for provider: String) -> String? {
        switch provider {
        case "openai":
            return (try? KeychainService.read(key: OPENAI_KEY_KEYCHAIN)) ?? nil
        case "anthropic":
            return (try? KeychainService.read(key: ANTHROPIC_KEY_KEYCHAIN)) ?? nil
        case "google":
            return (try? KeychainService.read(key: GOOGLE_KEY_KEYCHAIN)) ?? nil
        case "xai":
            return (try? KeychainService.read(key: XAI_KEY_KEYCHAIN)) ?? nil
        default:
            return nil
        }
    }

    private func saveKeychain(key: String, value: String) {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try? KeychainService.delete(key: key)
        } else {
            try? KeychainService.save(key: key, value: value)
        }
    }
}
````

## File: ChatApp/SettingsView.swift
````swift
// Views/SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store: SettingsStore

    init(context: ModelContext) {
        _store = StateObject(wrappedValue: SettingsStore(context: context))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ProvidersSettingsView(store: store)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bolt.horizontal.circle.fill").foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text("Providers")
                                Text("Manage API keys and models").font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }
                    NavigationLink {
                        DefaultChatSettingsView(store: store)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "slider.horizontal.3").foregroundStyle(.purple)
                            VStack(alignment: .leading) {
                                Text("Default Chat")
                                Text("System prompt, temperature, tokens").font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Interface") {
                    NavigationLink {
                        InterfaceSettingsView(store: store)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "paintpalette.fill").foregroundStyle(.orange)
                            VStack(alignment: .leading) {
                                Text("Appearance")
                                Text("Theme, font, text size, bubble colors").font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Toggle(isOn: $store.useWebCanvas) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Use Web Canvas")
                            Text("Faster rendering with streaming, math, tables, code, artifacts slot").font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Defaults") {
                    Picker("Default Provider", selection: $store.defaultProvider) {
                        Text("OpenAI").tag("openai")
                        Text("Anthropic").tag("anthropic")
                        Text("Google").tag("google")
                        Text("XAI").tag("xai")
                    }

                    // Model picker based on enabled models for the selected provider
                    Picker("Default Model", selection: $store.defaultModel) {
                        ForEach(modelsForSelectedProvider(), id: \.self) { m in
                            Text(m).tag(m)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(modelsForSelectedProvider().isEmpty)
                    .onAppear { ensureValidDefaultModel() }
                    .onChange(of: store.defaultProvider) { _, _ in ensureValidDefaultModel() }
                    .onChange(of: store.openAIEnabled) { _, _ in if store.defaultProvider == "openai" { ensureValidDefaultModel() } }
                    .onChange(of: store.anthropicEnabled) { _, _ in if store.defaultProvider == "anthropic" { ensureValidDefaultModel() } }
                    .onChange(of: store.googleEnabled) { _, _ in if store.defaultProvider == "google" { ensureValidDefaultModel() } }
                    .onChange(of: store.xaiEnabled) { _, _ in if store.defaultProvider == "xai" { ensureValidDefaultModel() } }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { store.save(); dismiss() } }
            }
        }
    }
}

// MARK: - SettingsView helpers
private extension SettingsView {
    func modelsForSelectedProvider() -> [String] {
        switch store.defaultProvider {
        case "openai": return Array(store.openAIEnabled).sorted()
        case "anthropic": return Array(store.anthropicEnabled).sorted()
        case "google": return Array(store.googleEnabled).sorted()
        case "xai": return Array(store.xaiEnabled).sorted()
        default: return []
        }
    }

    func ensureValidDefaultModel() {
        let models = modelsForSelectedProvider()
        if models.contains(store.defaultModel) == false {
            store.defaultModel = models.first ?? ""
        }
    }
}

private struct ProvidersSettingsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        List {
            ProviderRow(title: ProviderID.openai.displayName, symbol: "bolt.horizontal.circle.fill") {
                ProviderDetailView(provider: .openai, store: store)
            }
            ProviderRow(title: ProviderID.anthropic.displayName, symbol: "a.circle.fill") {
                ProviderDetailView(provider: .anthropic, store: store)
            }
            ProviderRow(title: ProviderID.google.displayName, symbol: "g.circle.fill") {
                ProviderDetailView(provider: .google, store: store)
            }
            ProviderRow(title: ProviderID.xai.displayName, symbol: "x.circle.fill") {
                ProviderDetailView(provider: .xai, store: store)
            }
        }
        .navigationTitle("Providers")
    }
}

private struct ProviderRow<Destination: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink { destination() } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .foregroundStyle(.teal)
                Text(title)
            }
        }
    }
}

private struct ProviderDetailView: View {
    let provider: ProviderID
    @ObservedObject var store: SettingsStore
    @State private var apiKey: String = ""
    @State private var available: [String] = []
    @State private var verifying = false
    @State private var verified: Bool? = nil
    @State private var loadingModels = false
    private struct SelectedModel: Identifiable { let id: String }
    @State private var activeModelForEdit: SelectedModel? = nil

    var body: some View {
        Form {
            Section(header: Text(provider.displayName)) {
                SecureField("API Key", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                VerificationBar(verifying: verifying, verified: verified)
                HStack {
                    Button {
                        Task { await verify() }
                    } label: {
                        Label("Verify", systemImage: "arrow.clockwise.circle")
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button {
                        Task { await reloadModels() }
                    } label: {
                        Label("Refresh Models", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || loadingModels)
                }
            }

            Section("Select Models (shown in picker)") {
                if loadingModels {
                    HStack { ProgressView(); Text("Loading…") }
                } else if available.isEmpty {
                    Text("No models. Verify API key and refresh.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(available, id: \.self) { m in
                        ModelRowWithInfo(title: m,
                                         isOn: bindingForModel(m),
                                         onInfo: { activeModelForEdit = SelectedModel(id: m) })
                    }
                }
            }
        }
        .navigationTitle(provider.displayName)
        .sheet(item: $activeModelForEdit) { selected in
            ModelSettingsView(providerID: provider.rawValue, modelID: selected.id)
        }
        .onAppear {
            apiKey = readAPIKey()
            available = enabledModelsAll()
        }
        .onDisappear {
            writeAPIKey(apiKey)
            store.save()
        }
    }

    private func bindingForModel(_ m: String) -> Binding<Bool> {
        switch provider {
        case .openai:
            return Binding(
                get: { store.openAIEnabled.contains(m) },
                set: { v in if v { _ = store.openAIEnabled.insert(m) } else { _ = store.openAIEnabled.remove(m) } }
            )
        case .anthropic:
            return Binding(
                get: { store.anthropicEnabled.contains(m) },
                set: { v in if v { _ = store.anthropicEnabled.insert(m) } else { _ = store.anthropicEnabled.remove(m) } }
            )
        case .google:
            return Binding(
                get: { store.googleEnabled.contains(m) },
                set: { v in if v { _ = store.googleEnabled.insert(m) } else { _ = store.googleEnabled.remove(m) } }
            )
        case .xai:
            return Binding(
                get: { store.xaiEnabled.contains(m) },
                set: { v in if v { _ = store.xaiEnabled.insert(m) } else { _ = store.xaiEnabled.remove(m) } }
            )
        }
    }

    private func enabledModelsAll() -> [String] {
        switch provider {
        case .openai: return Array(store.openAIEnabled).sorted()
        case .anthropic: return Array(store.anthropicEnabled).sorted()
        case .google: return Array(store.googleEnabled).sorted()
        case .xai: return Array(store.xaiEnabled).sorted()
        }
    }

    private func readAPIKey() -> String {
        switch provider {
        case .openai: return store.openAIAPIKey
        case .anthropic: return store.anthropicAPIKey
        case .google: return store.googleAPIKey
        case .xai: return store.xaiAPIKey
        }
    }

    private func writeAPIKey(_ value: String) {
        switch provider {
        case .openai: store.openAIAPIKey = value
        case .anthropic: store.anthropicAPIKey = value
        case .google: store.googleAPIKey = value
        case .xai: store.xaiAPIKey = value
        }
    }

    private func verify() async {
        verified = nil
        verifying = true
        let ok = await ProviderAPIs.verifyKey(provider: provider, apiKey: apiKey)
        if ok {
            // Populate model info on successful verify
            do {
                let infos = try await ProviderAPIs.listModelInfos(provider: provider, apiKey: apiKey)
                await MainActor.run {
                    ModelCapabilitiesStore.putDefault(provider: provider.rawValue, infos: infos)
                    self.available = infos.map { $0.id }
                    // If defaults target this provider, clamp tokens to model limit when possible
                    if store.defaultProvider == provider.rawValue,
                       let cap = infos.first(where: { $0.id == store.defaultModel }),
                       let out = cap.outputTokenLimit {
                        store.maxTokens = min(store.maxTokens, out)
                    }
                }
            } catch {
                // ignore; keep simple list population as fallback
            }
        }
        await MainActor.run { verified = ok; verifying = false }
    }

    private func reloadModels() async {
        loadingModels = true
        do {
            let infos = try await ProviderAPIs.listModelInfos(provider: provider, apiKey: apiKey)
            await MainActor.run {
                ModelCapabilitiesStore.putDefault(provider: provider.rawValue, infos: infos)
                let models = infos.map { $0.id }
                self.available = models
                if models.isEmpty == false { // seed enabled set if empty
                    switch provider {
                    case .openai: if store.openAIEnabled.isEmpty { store.openAIEnabled = Set(models.prefix(5)) }
                    case .anthropic: if store.anthropicEnabled.isEmpty { store.anthropicEnabled = Set(models.prefix(5)) }
                    case .google: if store.googleEnabled.isEmpty { store.googleEnabled = Set(models.prefix(5)) }
                    case .xai: if store.xaiEnabled.isEmpty { store.xaiEnabled = Set(models.prefix(5)) }
                    }
                }
                if store.defaultProvider == provider.rawValue,
                   let cap = infos.first(where: { $0.id == store.defaultModel }),
                   let out = cap.outputTokenLimit {
                    store.maxTokens = min(store.maxTokens, out)
                }
            }
        } catch {
            // Fallback to simple list
            do {
                let models = try await ProviderAPIs.listModels(provider: provider, apiKey: apiKey)
                await MainActor.run { self.available = models }
            } catch {
                await MainActor.run { self.available = [] }
            }
        }
        loadingModels = false
    }
}

private struct ModelRowWithInfo: View {
    let title: String
    @Binding var isOn: Bool
    var onInfo: () -> Void
    var body: some View {
        HStack {
            Button(action: { isOn.toggle() }) {
                HStack {
                    Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isOn ? .blue : .secondary)
                    Text(title)
                        .foregroundStyle(.primary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            Button(action: onInfo) {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Model Info")
        }
    }
}

private struct VerificationBar: View {
    let verifying: Bool
    let verified: Bool?
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.secondary.opacity(0.2)).frame(height: 6)
            if verifying {
                Capsule().fill(Color.green).frame(width: 60).opacity(0.8)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: verifying)
            } else if let ok = verified {
                Capsule().fill(ok ? Color.green : Color.red).frame(maxWidth: .infinity).opacity(0.6)
            }
        }
        .padding(.top, 4)
    }
}

private struct DefaultChatSettingsView: View {
    @ObservedObject var store: SettingsStore
    @State private var tempLocal: Double = 1.0
    @State private var tokensLocal: Double = 1024

    var body: some View {
        Form {
            Section("System Prompt") {
                TextEditor(text: $store.systemPrompt)
                    .frame(minHeight: 120)
            }
            Section("Sampling") {
                VStack(alignment: .leading) {
                    HStack { Text("Temperature"); Spacer(); Text(String(format: "%.2f", store.temperature)).foregroundStyle(.secondary) }
                    Slider(value: $store.temperature, in: 0...maxTemperature, step: 0.05)
                }
                VStack(alignment: .leading) {
                    HStack { Text("Max Tokens"); Spacer(); Text("\(store.maxTokens)").foregroundStyle(.secondary) }
                    Slider(value: Binding(get: { Double(store.maxTokens) }, set: { store.maxTokens = Int($0) }), in: 64...maxTokens, step: 32)
                }
                if supportsPromptCaching {
                    Toggle(isOn: $store.promptCachingEnabled) {
                        Label("Enable prompt caching (if supported)", systemImage: "bolt.horizontal.circle")
                    }
                }
            }
        }
        .navigationTitle("Default Chat")
    }

    // Dynamic limits derived from Provider→Model capability cache
    private var caps: ProviderModelInfo? {
        ModelCapabilitiesStore.get(provider: store.defaultProvider, model: store.defaultModel)
    }
    private var maxTemperature: Double { caps?.maxTemperature ?? 2.0 }
    private var maxTokens: Double { Double(caps?.outputTokenLimit ?? 8192) }
    private var supportsPromptCaching: Bool { caps?.supportsPromptCaching ?? false }
}

// MARK: - Model Settings Editor

struct ModelSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    let providerID: String
    let modelID: String

    // Working copy
    @State private var displayName: String = ""
    @State private var inputTokenLimit: String = "" // use text to allow empty
    @State private var outputTokenLimit: String = ""
    @State private var maxTemperature: Double = 2.0
    @State private var supportsPromptCaching: Bool = false
    // Advanced prefs
    @State private var preferredTemperature: Double? = nil
    @State private var preferredTopP: Double? = nil
    @State private var preferredTopK: String = "" // text field
    @State private var preferredMaxOutputTokens: String = ""
    @State private var preferredReasoningEffort: String? = nil // none|low|medium|high
    @State private var preferredVerbosity: String? = nil // none|low|medium|high
    @State private var disableSafetyFilters: Bool = true
    @State private var preferredPresencePenalty: Double = 0
    @State private var preferredFrequencyPenalty: Double = 0
    @State private var stopSequences: String = "" // comma-separated
    // Anthropic specifics
    @State private var anthropicThinkingEnabled: Bool = false
    @State private var anthropicThinkingBudget: String = ""
    @State private var enablePromptCaching: Bool = false

    // Originals for discard detection
    @State private var original: ProviderModelInfo = .fallback(id: "")
    @State private var defaults: ProviderModelInfo = .fallback(id: "")
    @State private var showingDiscard: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button("Restore Default") { restoreDefault() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                }

                Section("Model") {
                    HStack { Text("ID"); Spacer(); Text(modelID).foregroundStyle(.secondary) }
                    TextField("Display Name", text: $displayName)
                }

                Section("Limits") {
                    TextField("Input Token Limit", text: $inputTokenLimit)
                        .keyboardType(.numberPad)
                    TextField("Output Token Limit", text: $outputTokenLimit)
                        .keyboardType(.numberPad)
                    VStack(alignment: .leading) {
                        HStack { Text("Max Temperature"); Spacer(); Text(String(format: "%.2f", maxTemperature)).foregroundStyle(.secondary) }
                        Slider(value: $maxTemperature, in: 0...4, step: 0.05)
                    }
                    Toggle("Supports Prompt Caching", isOn: $supportsPromptCaching)
                }

                Section("Advanced Defaults (Applied on Send)") {
                    VStack(alignment: .leading) {
                        HStack { Text("Preferred Temperature"); Spacer(); Text(String(format: "%.2f", (preferredTemperature ?? maxTemperature))).foregroundStyle(.secondary) }
                        Slider(value: Binding(get: { preferredTemperature ?? maxTemperature }, set: { preferredTemperature = $0 }), in: 0...maxTemperature, step: 0.05)
                    }
                    VStack(alignment: .leading) {
                        HStack { Text("Top P"); Spacer(); Text(String(format: "%.2f", preferredTopP ?? 1.0)).foregroundStyle(.secondary) }
                        Slider(value: Binding(get: { preferredTopP ?? 1.0 }, set: { preferredTopP = $0 }), in: 0...1, step: 0.01)
                    }
                    TextField("Top K", text: $preferredTopK)
                        .keyboardType(.numberPad)
                    TextField("Preferred Max Output Tokens", text: $preferredMaxOutputTokens)
                        .keyboardType(.numberPad)
                    // Penalties (OpenAI/XAI style)
                    VStack(alignment: .leading) {
                        HStack { Text("Presence Penalty"); Spacer(); Text(String(format: "%.2f", preferredPresencePenalty)).foregroundStyle(.secondary) }
                        Slider(value: $preferredPresencePenalty, in: -2...2, step: 0.1)
                    }
                    VStack(alignment: .leading) {
                        HStack { Text("Frequency Penalty"); Spacer(); Text(String(format: "%.2f", preferredFrequencyPenalty)).foregroundStyle(.secondary) }
                        Slider(value: $preferredFrequencyPenalty, in: -2...2, step: 0.1)
                    }
                    TextField("Stop Sequences (comma-separated)", text: $stopSequences)
                    Picker("Reasoning Effort", selection: Binding(get: { preferredReasoningEffort ?? "none" }, set: { preferredReasoningEffort = ($0 == "none" ? nil : $0) })) {
                        Text("None").tag("none")
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                    }
                    Picker("Verbosity", selection: Binding(get: { preferredVerbosity ?? "none" }, set: { preferredVerbosity = ($0 == "none" ? nil : $0) })) {
                        Text("None").tag("none")
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                    }
                    Toggle("Disable Google Safety Filters", isOn: $disableSafetyFilters)
                    // Anthropic extras
                    Toggle("Anthropic Thinking Enabled", isOn: $anthropicThinkingEnabled)
                    TextField("Anthropic Thinking Budget (tokens)", text: $anthropicThinkingBudget)
                        .keyboardType(.numberPad)
                    Toggle("Enable Prompt Caching (Anthropic)", isOn: $enablePromptCaching)
                }

                if let defText = defaultSummary() {
                    Section("Current Defaults (from API)") {
                        Text(defText).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Model Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { attemptDismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndDismiss() }
                }
            }
            .confirmationDialog("Discard changes?", isPresented: $showingDiscard, titleVisibility: .visible) {
                Button("Discard Changes", role: .destructive) { dismiss() }
                Button("Cancel", role: .cancel) { }
            }
            .onAppear { load() }
        }
    }

    private func load() {
        let pair = ModelCapabilitiesStore.getPair(provider: providerID, model: modelID)
        let effective = ModelCapabilitiesStore.get(provider: providerID, model: modelID) ?? .fallback(id: modelID)
        defaults = pair.defaults ?? .fallback(id: modelID)
        original = effective

        displayName = effective.displayName ?? ""
        inputTokenLimit = effective.inputTokenLimit.map { String($0) } ?? ""
        outputTokenLimit = effective.outputTokenLimit.map { String($0) } ?? ""
        maxTemperature = effective.maxTemperature ?? 2.0
        supportsPromptCaching = effective.supportsPromptCaching ?? false
        preferredTemperature = effective.preferredTemperature
        preferredTopP = effective.preferredTopP
        preferredTopK = effective.preferredTopK.map { String($0) } ?? ""
        preferredMaxOutputTokens = effective.preferredMaxOutputTokens.map { String($0) } ?? ""
        preferredReasoningEffort = effective.preferredReasoningEffort
        preferredVerbosity = effective.preferredVerbosity
        disableSafetyFilters = effective.disableSafetyFilters ?? true
        preferredPresencePenalty = effective.preferredPresencePenalty ?? 0
        preferredFrequencyPenalty = effective.preferredFrequencyPenalty ?? 0
        stopSequences = (effective.stopSequences ?? []).joined(separator: ", ")
        anthropicThinkingEnabled = effective.anthropicThinkingEnabled ?? false
        anthropicThinkingBudget = effective.anthropicThinkingBudget.map { String($0) } ?? ""
        enablePromptCaching = effective.enablePromptCaching ?? false
    }

    private func currentInfo() -> ProviderModelInfo {
        ProviderModelInfo(
            id: modelID,
            displayName: displayName.isEmpty ? nil : displayName,
            inputTokenLimit: Int(inputTokenLimit),
            outputTokenLimit: Int(outputTokenLimit),
            maxTemperature: maxTemperature,
            supportsPromptCaching: supportsPromptCaching,
            preferredTemperature: preferredTemperature,
            preferredTopP: preferredTopP,
            preferredTopK: Int(preferredTopK),
            preferredMaxOutputTokens: Int(preferredMaxOutputTokens),
            preferredReasoningEffort: preferredReasoningEffort,
            preferredVerbosity: preferredVerbosity,
            disableSafetyFilters: disableSafetyFilters,
            preferredPresencePenalty: preferredPresencePenalty,
            preferredFrequencyPenalty: preferredFrequencyPenalty,
            stopSequences: stopSequences.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter{ !$0.isEmpty },
            anthropicThinkingEnabled: anthropicThinkingEnabled,
            anthropicThinkingBudget: Int(anthropicThinkingBudget),
            enablePromptCaching: enablePromptCaching
        )
    }

    private func hasUnsavedChanges() -> Bool {
        currentInfo() != original
    }

    private func attemptDismiss() {
        if hasUnsavedChanges() { showingDiscard = true } else { dismiss() }
    }

    private func saveAndDismiss() {
        let info = currentInfo()
        ModelCapabilitiesStore.putUser(provider: providerID, model: modelID, info: info)
        dismiss()
    }

    private func restoreDefault() {
        ModelCapabilitiesStore.clearUser(provider: providerID, model: modelID)
        load()
    }

    private func defaultSummary() -> String? {
        guard let d = ModelCapabilitiesStore.getPair(provider: providerID, model: modelID).defaults else { return nil }
        let input = d.inputTokenLimit.map(String.init) ?? "—"
        let output = d.outputTokenLimit.map(String.init) ?? "—"
        let temp = String(format: "%.2f", d.maxTemperature ?? 2.0)
        let caching = (d.supportsPromptCaching ?? false) ? "Yes" : "No"
        let tp = d.preferredTopP.map { String(format: "%.2f", $0) } ?? "—"
        let tk = d.preferredTopK.map(String.init) ?? "—"
        return "Input: \(input) • Output: \(output) • Max Temp: \(temp) • TopP: \(tp) • TopK: \(tk) • Caching: \(caching)"
    }
}

// MARK: - Interface Settings

private struct InterfaceSettingsView: View {
    @ObservedObject var store: SettingsStore
    @State private var sizeIndex: Double = 2

    private let sizeLabels = ["XS", "S", "M", "L", "XL"]
    @Environment(\.colorScheme) private var colorScheme

    private var previewFont: Font {
        switch store.interfaceFontStyle {
        case "serif": return .system(.body, design: .serif)
        case "rounded": return .system(.body, design: .rounded)
        case "mono": return .system(.body, design: .monospaced)
        default: return .system(.body, design: .default)
        }
    }

    private func fontForIndex(_ idx: Int) -> Font {
        let base: Font
        switch store.interfaceFontStyle {
        case "serif": base = .system(.body, design: .serif)
        case "rounded": base = .system(.body, design: .rounded)
        case "mono": base = .system(.body, design: .monospaced)
        default: base = .system(.body, design: .default)
        }
        // Map to discrete sizes
        switch idx {
        case 0: return base.smallCaps().weight(.regular)
        case 1: return base
        case 2: return .system(size: 17, weight: .regular, design: baseDesign())
        case 3: return .system(size: 20, weight: .regular, design: baseDesign())
        default: return .system(size: 24, weight: .regular, design: baseDesign())
        }
    }

    private func baseDesign() -> Font.Design {
        switch store.interfaceFontStyle {
        case "serif": return .serif
        case "rounded": return .rounded
        case "mono": return .monospaced
        default: return .default
        }
    }

    private let bubblePalettes: [(id: String, color: Color)] = [
        ("teal", Color(red: 0.46, green: 0.72, blue: 0.71)),     // muted teal
        ("blue", Color(red: 0.42, green: 0.58, blue: 0.69)),     // slate blue
        ("sage", Color(red: 0.49, green: 0.68, blue: 0.56)),     // sage
        ("rose", Color(red: 0.79, green: 0.56, blue: 0.65)),     // dusty rose
        ("lavender", Color(red: 0.62, green: 0.56, blue: 0.77)), // lavender
        ("mushroom", Color(red: 0.72, green: 0.70, blue: 0.65))  // warm gray
    ]

    var body: some View {
        Form {
            Section("Theme") {
                Picker("Color Scheme", selection: $store.interfaceTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                Text("Choose whether the app follows system appearance or forces light/dark.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Font") {
                // Fancy two-column card grid for font choices
                let options: [(id: String, label: String)] = [
                    ("system", "System"), ("serif", "Serif"), ("rounded", "Rounded"), ("mono", "Monospaced")
                ]
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(options, id: \.id) { opt in
                        let titleF = cardTitleFont(for: opt.id)
                        let bodyF = cardBodyFont(for: opt.id)
                        let bg = cardBackground(for: opt.id)
                        FontOptionCard(
                            label: opt.label,
                            titleFont: titleF,
                            bodyFont: bodyF,
                            background: bg,
                            selected: store.interfaceFontStyle == opt.id,
                            onSelect: { store.interfaceFontStyle = opt.id }
                        )
                        .accessibilityLabel("\(opt.label) font")
                        .accessibilityAddTraits(store.interfaceFontStyle == opt.id ? .isSelected : [])
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack { Text("Text Size"); Spacer(); Text(sizeLabels[Int(store.interfaceTextSizeIndex)]) }
                    Slider(value: Binding(get: { Double(store.interfaceTextSizeIndex) }, set: { store.interfaceTextSizeIndex = Int($0.rounded()) }), in: 0...4, step: 1)
                    // Previews under the slider positions
                    HStack(spacing: 12) {
                        ForEach(0..<5) { i in
                            VStack {
                                Text("Aa")
                                    .font(fontForIndex(i))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(i == store.interfaceTextSizeIndex ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(i == store.interfaceTextSizeIndex ? Color.accentColor : Color.clear, lineWidth: 1)
                            )
                            .onTapGesture { store.interfaceTextSizeIndex = i }
                        }
                    }
                }
            }

            Section("Chat Bubble Color") {
                HStack(spacing: 12) {
                    ForEach(bubblePalettes, id: \.id) { p in
                        Button(action: { store.chatBubbleColorID = p.id }) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(p.color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(store.chatBubbleColorID == p.id ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text("Six muted palettes designed to be easy on the eyes.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Appearance")
        .onAppear {
            sizeIndex = Double(store.interfaceTextSizeIndex)
        }
    }

    // MARK: - Helpers (Fonts & Backgrounds)
    private func cardTitleFont(for id: String) -> Font {
        switch id {
        case "serif": return .system(size: 22, weight: .semibold, design: .serif)
        case "rounded": return .system(size: 22, weight: .semibold, design: .rounded)
        case "mono": return .system(size: 22, weight: .semibold, design: .monospaced)
        default: return .system(size: 22, weight: .semibold, design: .default)
        }
    }

    private func cardBodyFont(for id: String) -> Font {
        switch id {
        case "serif": return .system(size: 14, weight: .regular, design: .serif)
        case "rounded": return .system(size: 14, weight: .regular, design: .rounded)
        case "mono": return .system(size: 14, weight: .regular, design: .monospaced)
        default: return .system(size: 14, weight: .regular, design: .default)
        }
    }

    private func sampleSnippet(for id: String) -> String {
        switch id {
        case "serif": return "Readable, classic body text"
        case "rounded": return "Friendly, soft headings"
        case "mono": return "Code & technical content"
        default: return "Balanced, native UI style"
        }
    }

    private func cardBackground(for id: String) -> Color {
        // Muted, per-font tones; adjusted for dark/light
        let isDark = (colorScheme == .dark)
        switch id {
        case "serif": return isDark ? Color(red: 0.18, green: 0.17, blue: 0.15) : Color(red: 0.97, green: 0.96, blue: 0.93)
        case "rounded": return isDark ? Color(red: 0.12, green: 0.16, blue: 0.20) : Color(red: 0.93, green: 0.96, blue: 0.98)
        case "mono": return isDark ? Color(red: 0.16, green: 0.16, blue: 0.22) : Color(red: 0.94, green: 0.94, blue: 0.98)
        default: return isDark ? Color.white.opacity(0.06) : Color.secondary.opacity(0.12)
        }
    }
}

// Split out to keep the parent body simple for the compiler
private struct FontOptionCard: View {
    let label: String
    let titleFont: Font
    let bodyFont: Font
    let background: Color
    let selected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(background)
                VStack(alignment: .center, spacing: 6) {
                    Text(label)
                        .font(titleFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    Text(sample)
                        .font(bodyFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    Spacer(minLength: 0)
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                        .padding(8)
                }
            }
            .frame(height: 92)
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(selected ? Color.accentColor : Color.clear, lineWidth: 1)
        )
    }

    private var sample: String { "Aa • Readable preview" }
}

#Preview {
    let container = try! ModelContainer(for: Chat.self, Message.self, AppSettings.self)
    let context = ModelContext(container)
    return SettingsView(context: context)
        .modelContainer(container)
}
````

## File: ChatApp/SystemPrompt.swift
````swift
// Services/SystemPrompt.swift
import Foundation

let MASTER_SYSTEM_PROMPT = """
You are ChatApp’s AI assistant. Always format responses using GitHub‑flavored Markdown.

Rules:
- Use headings, lists, tables, and links where helpful.
- For code, use fenced blocks with a language tag (```swift, ```python, etc.). Prefer short, focused snippets. Do not wrap code in HTML.
- For math:
  - Block math: wrap LaTeX in $$ ... $$.
  - Inline math: wrap LaTeX in $ ... $.
  - Use standard LaTeX syntax compatible with iosMath (no HTML/MathML).
- When including both code and prose, separate sections clearly.
- Do not include screenshots or images in output; describe them in text.

Assume the client renders Markdown with syntax highlighting and LaTeX support.
"""
````

## File: ChatApp/XAIProvider.swift
````swift
// Providers/XAIProvider.swift
import Foundation

struct XAIProvider: AIProviderAdvanced {
    let id = "xai"
    let displayName = "XAI Grok"

    private let client = NetworkClient.shared
    private let apiKey: String
    private let apiBase = URL(string: "https://api.x.ai/v1")!

    init(apiKey: String) { self.apiKey = apiKey }

    func listModels() async throws -> [String] {
        return try await ProviderAPIs.listModels(provider: .xai, apiKey: apiKey)
    }

    func sendChat(messages: [AIMessage], model: String) async throws -> String {
        try await sendChat(messages: messages, model: model, temperature: nil, topP: nil, topK: nil, maxOutputTokens: nil, reasoningEffort: nil, verbosity: nil)
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
        struct Msg: Encodable { let role: String; let content: String }
        struct Req: Encodable {
            let model: String
            let messages: [Msg]
            let temperature: Double?
            let top_p: Double?
            let max_tokens: Int?
            let stream: Bool
            let presence_penalty: Double?
            let frequency_penalty: Double?
            let stop: [String]?
        }
        struct Resp: Decodable { struct Choice: Decodable { struct Message: Decodable { let content: String }
                let message: Message }
            let choices: [Choice] }

        // Basic text-only mapping (images not yet supported in this minimal client)
        func flatten(_ parts: [AIMessage.Part]) -> String {
            parts.compactMap { p in
                if case let .text(t) = p { return t } else { return nil }
            }.joined(separator: "\n")
        }
        let mapped: [Msg] = messages.map { m in
            switch m.role {
            case .system: return Msg(role: "system", content: flatten(m.parts))
            case .user: return Msg(role: "user", content: flatten(m.parts))
            case .assistant: return Msg(role: "assistant", content: flatten(m.parts))
            }
        }

        let caps = ModelCapabilitiesStore.get(provider: id, model: model)
        let req = Req(model: model,
                      messages: mapped,
                      temperature: temperature,
                      top_p: topP,
                      max_tokens: maxOutputTokens,
                      stream: false,
                      presence_penalty: caps?.preferredPresencePenalty,
                      frequency_penalty: caps?.preferredFrequencyPenalty,
                      stop: caps?.stopSequences)

        let url = apiBase.appendingPathComponent("chat/completions")
        var urlReq = URLRequest(url: url)
        urlReq.httpMethod = "POST"
        urlReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlReq.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlReq.httpBody = try JSONEncoder().encode(req)

        let (data, resp) = try await client.session.data(for: urlReq)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let http = resp as? HTTPURLResponse
            let err = String(data: data, encoding: .utf8) ?? "Error"
            throw NSError(domain: "XAI", code: http?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: err])
        }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        let text = decoded.choices.first?.message.content ?? ""
        return text
    }
}
````

## File: ChatApp.xcodeproj/xcshareddata/xcschemes/ChatApp.xcscheme
````
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES"
      buildArchitectures = "Automatic">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "0A60D2382E6A6DCF00623E77"
               BuildableName = "ChatApp.app"
               BlueprintName = "ChatApp"
               ReferencedContainer = "container:ChatApp.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <TestPlans>
         <TestPlanReference
            reference = "container:ChatApp.xctestplan"
            default = "YES">
         </TestPlanReference>
      </TestPlans>
      <Testables>
         <TestableReference
            skipped = "NO"
            parallelizable = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "0A60D2492E6A6DD100623E77"
               BuildableName = "ChatAppTests.xctest"
               BlueprintName = "ChatAppTests"
               ReferencedContainer = "container:ChatApp.xcodeproj">
            </BuildableReference>
         </TestableReference>
         <TestableReference
            skipped = "NO"
            parallelizable = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "0A60D2532E6A6DD100623E77"
               BuildableName = "ChatAppUITests.xctest"
               BlueprintName = "ChatAppUITests"
               ReferencedContainer = "container:ChatApp.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "0A60D2382E6A6DCF00623E77"
            BuildableName = "ChatApp.app"
            BlueprintName = "ChatApp"
            ReferencedContainer = "container:ChatApp.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "0A60D2382E6A6DCF00623E77"
            BuildableName = "ChatApp.app"
            BlueprintName = "ChatApp"
            ReferencedContainer = "container:ChatApp.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
````

## File: ChatApp.xcodeproj/project.pbxproj
````
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 77;
	objects = {

/* Begin PBXBuildFile section */
		0A65CBED2E6B664D001DC08D /* MarkdownUI in Frameworks */ = {isa = PBXBuildFile; productRef = 0A65CBEC2E6B664D001DC08D /* MarkdownUI */; };
		0A65CBF02E6B6664001DC08D /* Highlighter in Frameworks */ = {isa = PBXBuildFile; productRef = 0A65CBEF2E6B6664001DC08D /* Highlighter */; };
		0A65D0802E6B9E0F001DC08D /* SwiftMath in Frameworks */ = {isa = PBXBuildFile; productRef = 0A65D07F2E6B9E0F001DC08D /* SwiftMath */; };
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
		0A60D24B2E6A6DD100623E77 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = 0A60D2312E6A6DCF00623E77 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 0A60D2382E6A6DCF00623E77;
			remoteInfo = ChatApp;
		};
		0A60D2552E6A6DD100623E77 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = 0A60D2312E6A6DCF00623E77 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 0A60D2382E6A6DCF00623E77;
			remoteInfo = ChatApp;
		};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
		0A60D2392E6A6DCF00623E77 /* ChatApp.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = ChatApp.app; sourceTree = BUILT_PRODUCTS_DIR; };
		0A60D24A2E6A6DD100623E77 /* ChatAppTests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = ChatAppTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
		0A60D2542E6A6DD100623E77 /* ChatAppUITests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = ChatAppUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
		0A6FFD642E6A86B600ABE516 /* ChatApp.xctestplan */ = {isa = PBXFileReference; lastKnownFileType = text; path = ChatApp.xctestplan; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */
		0A60D25C2E6A6DD100623E77 /* Exceptions for "ChatApp" folder in "ChatApp" target */ = {
			isa = PBXFileSystemSynchronizedBuildFileExceptionSet;
			membershipExceptions = (
				Info.plist,
			);
			target = 0A60D2382E6A6DCF00623E77 /* ChatApp */;
		};
/* End PBXFileSystemSynchronizedBuildFileExceptionSet section */

/* Begin PBXFileSystemSynchronizedRootGroup section */
		0A60D23B2E6A6DCF00623E77 /* ChatApp */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			exceptions = (
				0A60D25C2E6A6DD100623E77 /* Exceptions for "ChatApp" folder in "ChatApp" target */,
			);
			path = ChatApp;
			sourceTree = "<group>";
		};
		0A60D24D2E6A6DD100623E77 /* ChatAppTests */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			path = ChatAppTests;
			sourceTree = "<group>";
		};
		0A60D2572E6A6DD100623E77 /* ChatAppUITests */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			path = ChatAppUITests;
			sourceTree = "<group>";
		};
/* End PBXFileSystemSynchronizedRootGroup section */

/* Begin PBXFrameworksBuildPhase section */
		0A60D2362E6A6DCF00623E77 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				0A65CBF02E6B6664001DC08D /* Highlighter in Frameworks */,
				0A65CBED2E6B664D001DC08D /* MarkdownUI in Frameworks */,
				0A65D0802E6B9E0F001DC08D /* SwiftMath in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		0A60D2472E6A6DD100623E77 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		0A60D2512E6A6DD100623E77 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		0A60D2302E6A6DCF00623E77 = {
			isa = PBXGroup;
			children = (
				0A6FFD642E6A86B600ABE516 /* ChatApp.xctestplan */,
				0A60D23B2E6A6DCF00623E77 /* ChatApp */,
				0A60D24D2E6A6DD100623E77 /* ChatAppTests */,
				0A60D2572E6A6DD100623E77 /* ChatAppUITests */,
				0A60D23A2E6A6DCF00623E77 /* Products */,
			);
			sourceTree = "<group>";
		};
		0A60D23A2E6A6DCF00623E77 /* Products */ = {
			isa = PBXGroup;
			children = (
				0A60D2392E6A6DCF00623E77 /* ChatApp.app */,
				0A60D24A2E6A6DD100623E77 /* ChatAppTests.xctest */,
				0A60D2542E6A6DD100623E77 /* ChatAppUITests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		0A60D2382E6A6DCF00623E77 /* ChatApp */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 0A60D25D2E6A6DD100623E77 /* Build configuration list for PBXNativeTarget "ChatApp" */;
			buildPhases = (
				0A60D2352E6A6DCF00623E77 /* Sources */,
				0A65CBF52E6B90A5001DC08D /* Inject Dev .env */,
				0A60D2362E6A6DCF00623E77 /* Frameworks */,
				0A60D2372E6A6DCF00623E77 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			fileSystemSynchronizedGroups = (
				0A60D23B2E6A6DCF00623E77 /* ChatApp */,
			);
			name = ChatApp;
			packageProductDependencies = (
				0A65CBEC2E6B664D001DC08D /* MarkdownUI */,
				0A65CBEF2E6B6664001DC08D /* Highlighter */,
				0A65D07F2E6B9E0F001DC08D /* SwiftMath */,
			);
			productName = ChatApp;
			productReference = 0A60D2392E6A6DCF00623E77 /* ChatApp.app */;
			productType = "com.apple.product-type.application";
		};
		0A60D2492E6A6DD100623E77 /* ChatAppTests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 0A60D2622E6A6DD100623E77 /* Build configuration list for PBXNativeTarget "ChatAppTests" */;
			buildPhases = (
				0A60D2462E6A6DD100623E77 /* Sources */,
				0A60D2472E6A6DD100623E77 /* Frameworks */,
				0A60D2482E6A6DD100623E77 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				0A60D24C2E6A6DD100623E77 /* PBXTargetDependency */,
			);
			fileSystemSynchronizedGroups = (
				0A60D24D2E6A6DD100623E77 /* ChatAppTests */,
			);
			name = ChatAppTests;
			packageProductDependencies = (
			);
			productName = ChatAppTests;
			productReference = 0A60D24A2E6A6DD100623E77 /* ChatAppTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		};
		0A60D2532E6A6DD100623E77 /* ChatAppUITests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 0A60D2652E6A6DD100623E77 /* Build configuration list for PBXNativeTarget "ChatAppUITests" */;
			buildPhases = (
				0A60D2502E6A6DD100623E77 /* Sources */,
				0A60D2512E6A6DD100623E77 /* Frameworks */,
				0A60D2522E6A6DD100623E77 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				0A60D2562E6A6DD100623E77 /* PBXTargetDependency */,
			);
			fileSystemSynchronizedGroups = (
				0A60D2572E6A6DD100623E77 /* ChatAppUITests */,
			);
			name = ChatAppUITests;
			packageProductDependencies = (
			);
			productName = ChatAppUITests;
			productReference = 0A60D2542E6A6DD100623E77 /* ChatAppUITests.xctest */;
			productType = "com.apple.product-type.bundle.ui-testing";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		0A60D2312E6A6DCF00623E77 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1640;
				LastUpgradeCheck = 2600;
				TargetAttributes = {
					0A60D2382E6A6DCF00623E77 = {
						CreatedOnToolsVersion = 16.4;
					};
					0A60D2492E6A6DD100623E77 = {
						CreatedOnToolsVersion = 16.4;
						TestTargetID = 0A60D2382E6A6DCF00623E77;
					};
					0A60D2532E6A6DD100623E77 = {
						CreatedOnToolsVersion = 16.4;
						TestTargetID = 0A60D2382E6A6DCF00623E77;
					};
				};
			};
			buildConfigurationList = 0A60D2342E6A6DCF00623E77 /* Build configuration list for PBXProject "ChatApp" */;
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = 0A60D2302E6A6DCF00623E77;
			minimizedProjectReferenceProxies = 1;
			packageReferences = (
				0A65CBEB2E6B664D001DC08D /* XCRemoteSwiftPackageReference "MarkdownUI" */,
				0A65CBEE2E6B6664001DC08D /* XCRemoteSwiftPackageReference "HighlighterSwift" */,
				0A65D07E2E6B9E0F001DC08D /* XCRemoteSwiftPackageReference "SwiftMath" */,
			);
			preferredProjectObjectVersion = 77;
			productRefGroup = 0A60D23A2E6A6DCF00623E77 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				0A60D2382E6A6DCF00623E77 /* ChatApp */,
				0A60D2492E6A6DD100623E77 /* ChatAppTests */,
				0A60D2532E6A6DD100623E77 /* ChatAppUITests */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		0A60D2372E6A6DCF00623E77 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		0A60D2482E6A6DD100623E77 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		0A60D2522E6A6DD100623E77 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXShellScriptBuildPhase section */
		0A65CBF52E6B90A5001DC08D /* Inject Dev .env */ = {
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputFileListPaths = (
			);
			inputPaths = (
				"$(SRCROOT)/Env/.env",
			);
			name = "Inject Dev .env";
			outputFileListPaths = (
			);
			outputPaths = (
				"$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/DevSecrets.env",
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "if [ \"$CONFIGURATION\" = \"Debug\" ]; then\n  if [ -f \"$SRCROOT/Env/.env\" ]; then\n    echo \"Copying .env to DevSecrets.env (Debug only)\"\n    cp \"$SRCROOT/Env/.env\" \"$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/DevSecrets.env\"\n  else\n    echo \"(No Env/.env found; skipping)\"\n  fi\nfi\n";
		};
		6D814817573F411CB1B86CC4 /* Bundle WebCanvas */ = {
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputFileListPaths = (
			);
			inputPaths = (
			);
			name = "Bundle WebCanvas";
			outputFileListPaths = (
			);
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "set -e\nif [ -d \"$SRCROOT/ChatApp/WebCanvas/dist\" ]; then\n    SRC=\"$SRCROOT/ChatApp/WebCanvas/dist\"\n    DEST=\"$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/WebCanvas/dist\"\n    mkdir -p \"$(dirname \"$DEST\")\"\n    rm -rf \"$DEST\"\n    cp -R \"$SRC\" \"$DEST\"\nfi\nif [ -d \"$SRCROOT/ChatApp/KaTeX\" ]; then\n    KATEX_SRC=\"$SRCROOT/ChatApp/KaTeX\"\n    KATEX_DEST=\"$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/KaTeX\"\n    rm -rf \"$KATEX_DEST\"\n    cp -R \"$KATEX_SRC\" \"$KATEX_DEST\"\nfi\n";
		};
/* End PBXShellScriptBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		0A60D2352E6A6DCF00623E77 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		0A60D2462E6A6DD100623E77 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		0A60D2502E6A6DD100623E77 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		0A60D24C2E6A6DD100623E77 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = 0A60D2382E6A6DCF00623E77 /* ChatApp */;
			targetProxy = 0A60D24B2E6A6DD100623E77 /* PBXContainerItemProxy */;
		};
		0A60D2562E6A6DD100623E77 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = 0A60D2382E6A6DCF00623E77 /* ChatApp */;
			targetProxy = 0A60D2552E6A6DD100623E77 /* PBXContainerItemProxy */;
		};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		0A60D25E2E6A6DD100623E77 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = ChatApp/ChatApp.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = SV9Z2RG2A6;
				ENABLE_APP_SANDBOX = YES;
				ENABLE_PREVIEWS = YES;
				ENABLE_USER_SELECTED_FILES = readonly;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = ChatApp/Info.plist;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				OTHER_LDFLAGS = "-ObjC";
				PRODUCT_BUNDLE_IDENTIFIER = Kosta.ChatApp;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		0A60D25F2E6A6DD100623E77 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = ChatApp/ChatApp.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = SV9Z2RG2A6;
				ENABLE_APP_SANDBOX = YES;
				ENABLE_PREVIEWS = YES;
				ENABLE_USER_SELECTED_FILES = readonly;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = ChatApp/Info.plist;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				OTHER_LDFLAGS = "-ObjC";
				PRODUCT_BUNDLE_IDENTIFIER = Kosta.ChatApp;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
		0A60D2602E6A6DD100623E77 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				DEVELOPMENT_TEAM = SV9Z2RG2A6;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 18.5;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				STRING_CATALOG_GENERATE_SYMBOLS = YES;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		0A60D2612E6A6DD100623E77 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				DEVELOPMENT_TEAM = SV9Z2RG2A6;
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 18.5;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				STRING_CATALOG_GENERATE_SYMBOLS = YES;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		0A60D2632E6A6DD100623E77 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = SV9Z2RG2A6;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 18.5;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = Kosta.ChatAppTests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/ChatApp.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/ChatApp";
			};
			name = Debug;
		};
		0A60D2642E6A6DD100623E77 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = SV9Z2RG2A6;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 18.5;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = Kosta.ChatAppTests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/ChatApp.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/ChatApp";
			};
			name = Release;
		};
		0A60D2662E6A6DD100623E77 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = SV9Z2RG2A6;
				GENERATE_INFOPLIST_FILE = YES;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = Kosta.ChatAppUITests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_TARGET_NAME = ChatApp;
			};
			name = Debug;
		};
		0A60D2672E6A6DD100623E77 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = SV9Z2RG2A6;
				GENERATE_INFOPLIST_FILE = YES;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = Kosta.ChatAppUITests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_TARGET_NAME = ChatApp;
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		0A60D2342E6A6DCF00623E77 /* Build configuration list for PBXProject "ChatApp" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				0A60D2602E6A6DD100623E77 /* Debug */,
				0A60D2612E6A6DD100623E77 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		0A60D25D2E6A6DD100623E77 /* Build configuration list for PBXNativeTarget "ChatApp" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				0A60D25E2E6A6DD100623E77 /* Debug */,
				0A60D25F2E6A6DD100623E77 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		0A60D2622E6A6DD100623E77 /* Build configuration list for PBXNativeTarget "ChatAppTests" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				0A60D2632E6A6DD100623E77 /* Debug */,
				0A60D2642E6A6DD100623E77 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		0A60D2652E6A6DD100623E77 /* Build configuration list for PBXNativeTarget "ChatAppUITests" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				0A60D2662E6A6DD100623E77 /* Debug */,
				0A60D2672E6A6DD100623E77 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */

/* Begin XCRemoteSwiftPackageReference section */
		0A65CBEB2E6B664D001DC08D /* XCRemoteSwiftPackageReference "MarkdownUI" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/gonzalezreal/MarkdownUI";
			requirement = {
				kind = upToNextMajorVersion;
				minimumVersion = 2.4.1;
			};
		};
		0A65CBEE2E6B6664001DC08D /* XCRemoteSwiftPackageReference "HighlighterSwift" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/smittytone/HighlighterSwift";
			requirement = {
				kind = upToNextMajorVersion;
				minimumVersion = 1.1.7;
			};
		};
		0A65D07E2E6B9E0F001DC08D /* XCRemoteSwiftPackageReference "SwiftMath" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/mgriebling/SwiftMath";
			requirement = {
				kind = upToNextMajorVersion;
				minimumVersion = 1.7.3;
			};
		};
/* End XCRemoteSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
		0A65CBEC2E6B664D001DC08D /* MarkdownUI */ = {
			isa = XCSwiftPackageProductDependency;
			package = 0A65CBEB2E6B664D001DC08D /* XCRemoteSwiftPackageReference "MarkdownUI" */;
			productName = MarkdownUI;
		};
		0A65CBEF2E6B6664001DC08D /* Highlighter */ = {
			isa = XCSwiftPackageProductDependency;
			package = 0A65CBEE2E6B6664001DC08D /* XCRemoteSwiftPackageReference "HighlighterSwift" */;
			productName = Highlighter;
		};
		0A65D07F2E6B9E0F001DC08D /* SwiftMath */ = {
			isa = XCSwiftPackageProductDependency;
			package = 0A65D07E2E6B9E0F001DC08D /* XCRemoteSwiftPackageReference "SwiftMath" */;
			productName = SwiftMath;
		};
/* End XCSwiftPackageProductDependency section */
	};
	rootObject = 0A60D2312E6A6DCF00623E77 /* Project object */;
}
````

## File: ChatApp.xcodeproj/SwiftMathSmokeTest.swift
````swift
// SwiftMathSmokeTest.swift
#if DEBUG
#if canImport(SwiftMath)
import SwiftMath

// If SwiftMath is not linked, this file won't compile under the canImport gate.
// If it is linked, constructing MTMathUILabel succeeds at compile-time.
@inline(__always)
func _swiftMathSmokeTest() {
    // If either module is linked, constructing MTMathUILabel should succeed at link time.
    _ = MTMathUILabel()
}
#endif
#endif
````

## File: ChatAppTests/ChatAppTests.swift
````swift
//
//  ChatAppTests.swift
//  ChatAppTests
//
//  Created by Kosta Milovanovic on 9/4/25.
//

import XCTest
@testable import ChatApp

final class ChatAppTests: XCTestCase {

    func testExample() throws {
        XCTAssertTrue(true)
    }
}
````

## File: ChatAppUITests/ChatAppUITests.swift
````swift
//
//  ChatAppUITests.swift
//  ChatAppUITests
//
//  Created by Kosta Milovanovic on 9/4/25.
//

import XCTest

final class ChatAppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
````

## File: ChatAppUITests/ChatAppUITestsLaunchTests.swift
````swift
//
//  ChatAppUITestsLaunchTests.swift
//  ChatAppUITests
//
//  Created by Kosta Milovanovic on 9/4/25.
//

import XCTest

final class ChatAppUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
````

## File: .gitignore
````
# macOS
.DS_Store

# Xcode
build/
Build/
DerivedData/
*.xcworkspace
!default.xcworkspace
!project.xcworkspace
xcuserdata/
*.xcuserstate
*.xcscmblueprint
*.xccheckout
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
timeline.xctimeline
playground.xcworkspace
*.xcbkptlist
*.xcscheme
!ChatApp.xcscheme

# Swift Package Manager
.build/
.swiftpm/
Packages/
Package.resolved
.package.complete

# CocoaPods (not used unless added)
Pods/

# Carthage
Carthage/

# Fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots
fastlane/test_output

# Logs & temp
*.log
BuildLogs/

# iOS specific
*.ipa
*.dSYM.zip
*.dSYM
*.app.dSYM
*.app
*.swiftmodule
*.swiftdoc

# Editor
.vscode/
.idea/
*.swp
*.swo
*~
.nova/


# Local env secrets (do not commit)
Env/.env
Env/*.env
!Env/.env.example

# Documentation build artifacts
docs/_build/
docs/.jekyll-cache/
docs/.sass-cache/

# WebCanvas temporary files
webcanvas/node_modules/
webcanvas/.next/
webcanvas/dist/
webcanvas/.cache/

# Testing
xcov_report/
fastlane/test_output/
test-results/
*.xcresult

# Temporary files
*.tmp
*.bak
.scratch/
````

## File: ChatApp.xctestplan
````
{
  "configurations" : [
    {
      "id" : "F9A0C503-5596-4057-8D1A-F94D1805AA23",
      "name" : "Test Scheme Action",
      "options" : {

      }
    }
  ],
  "defaultOptions" : {
    "performanceAntipatternCheckerEnabled" : true,
    "targetForVariableExpansion" : {
      "containerPath" : "container:ChatApp.xcodeproj",
      "identifier" : "0A60D2382E6A6DCF00623E77",
      "name" : "ChatApp"
    }
  },
  "testTargets" : [
    {
      "parallelizable" : true,
      "target" : {
        "containerPath" : "container:ChatApp.xcodeproj",
        "identifier" : "0A60D2492E6A6DD100623E77",
        "name" : "ChatAppTests"
      }
    },
    {
      "parallelizable" : true,
      "target" : {
        "containerPath" : "container:ChatApp.xcodeproj",
        "identifier" : "0A60D2532E6A6DD100623E77",
        "name" : "ChatAppUITests"
      }
    }
  ],
  "version" : 1
}
````

## File: CLAUDE.md
````markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Agent Role & Responsibilities

You are **Apple-Stack Agent** for this ChatApp iOS project: an autonomous engineer who plans, searches, implements, tests, simulates, and maintains the repository. You **never** invent APIs; you **always** verify with **sosumi** and **context7** before coding. Prefer **Swift 6 strict concurrency** and **Swift Testing / XCTest** where appropriate. Align UI/UX with Apple's **Human Interface Guidelines** and **SF Symbols** patterns.

## Control Loop: Plan → Verify → Act → Test → Clean → Report

1. **Plan**: Break goals into ≤8 atomic steps; update progress tracking
2. **Verify**: For unfamiliar APIs, use **sosumi.searchAppleDocumentation** and **context7** lookups; document decisions
3. **Act**: Use MCP tools in small batches (file edits, build, run); prefer simulator first
4. **Test**: Generate/extend **Swift Testing** or **XCTest** (unit + UI); run tests and capture failures
5. **Clean**: Remove temp artifacts, revert debug flags, maintain repo hygiene
6. **Report**: Emit structured summary with next steps

## Project-Specific Information

### Development Commands

#### Building and Running (Use XcodeBuildMCP)
- **Discover project**: `xcodebuildmcp.discover_projs` (always run first)
- **List schemes**: `xcodebuildmcp.list_schemes` → use `ChatApp` scheme
- **List simulators**: `xcodebuildmcp.list_sims` → prefer iPhone 16 or latest
- **Build and run**: `xcodebuildmcp.build_run_sim` with scheme=ChatApp
- **Build only**: `xcodebuildmcp.build_sim` with scheme=ChatApp

#### Testing (XcodeBuildMCP + Test Plan)
- **Run all tests**: `xcodebuildmcp.test_sim` with scheme=ChatApp
- **UI tests**: Include XCUITest automation in ChatAppUITests/
- **Test plan**: Use `ChatApp.xctestplan` for coordinated test runs
- **Coverage target**: ≥80% for core services (NetworkClient, KeychainService)

#### Logging and Debugging
- **Capture logs**: `xcodebuildmcp.start_sim_log_cap` → `stop_sim_log_cap`
- **Screenshots**: `xcodebuildmcp.screenshot` for UI verification
- **UI automation**: `xcodebuildmcp.tap`, `gesture`, `type_text` for testing

### Project Structure & Architecture

This is a SwiftUI-based iOS chat application with AI provider integration, built using SwiftData for persistence.

#### Core Architecture Pattern
- **MVVM with SwiftData**: Views → ViewModels → SwiftData Models
- **Provider Pattern**: Pluggable AI providers (OpenAI, Anthropic, Google, XAI)
- **Service Layer**: Networking, keychain, settings management
- **Repository Pattern**: SwiftData ModelContext handles all persistence

#### Key Components

**Models (SwiftData)**:
- `Chat`: Chat sessions with cascade delete to messages
- `Message`: Individual messages with role (user/assistant) and content
- `AppSettings`: App-wide configuration including provider settings and UI preferences

**Views (SwiftUI)**:
- `ContentView`: Main navigation and chat list
- `ChatView`: Individual chat interface with streaming support
- `SettingsView`: Configuration for providers, models, and interface preferences
- `AIResponseView`: Markdown rendering with syntax highlighting

**Services & Providers**:
- `AIProvider` protocol: Unified interface for all AI providers
- `NetworkClient`: HTTP client with error handling and timeout management
- `KeychainService`: Secure storage for API keys
- `SettingsStore`: Observable settings management with SwiftData persistence

#### Data Flow
1. User input → `ChatView`
2. Settings from `SettingsStore` (backed by SwiftData)
3. Provider selection via `AIProvider` protocol
4. Network requests through `NetworkClient`
5. Responses rendered in `AIResponseView` with markdown support
6. Messages persisted via SwiftData `ModelContext`

## MCP Tool Usage Guidelines

### Primary Tool Routing

#### desktop-commander (Primary File Operations)
- **When**: All file reads/writes/edits, search operations
- **Key Tools**: `read_file`, `write_file`, `edit_block`, `search_code`
- **Note**: DO NOT USE SERENA - Use desktop-commander for all file operations

#### XcodeBuildMCP (Primary iOS Development)
- **When**: All build/run/test/simulator operations
- **Key Tools**: `discover_projs`, `list_schemes`, `build_run_sim`, `test_sim`, `screenshot`, `tap/swipe`
- **Always**: Discover before build; choose scheme/simulator explicitly; attach/stop log capture

#### sosumi (Apple Documentation Authority)
- **When**: Verifying any Apple API usage
- **Key Tools**: `searchAppleDocumentation`, `fetchAppleDocumentation`
- **Always**: Check before implementing unfamiliar iOS/SwiftUI/SwiftData APIs

#### context7 (Library Documentation)
- **When**: Working with third-party dependencies
- **Key Tools**: `resolve-library-id`, `get-library-docs`
- **Current Dependencies**: MarkdownUI, Highlighter, iosMath

#### desktop-commander (File Operations)
- **When**: File reads/writes/edits, process control
- **Key Tools**: `read_file`, `write_file`, `edit_block`
- **Keep**: Edits minimal and diffable; never commit secrets

#### github-kosta (Repository Analysis)
- **When**: Understanding external dependencies or examples
- **Default**: Read-only unless explicitly asked to write
- **Use**: For researching similar implementations

## Documentation Discipline (Zero-Hallucination Policy)

### Apple APIs
Always verify with **sosumi.searchAppleDocumentation** before implementing:
- SwiftUI components (NavigationStack, AsyncImage, etc.)
- SwiftData relationships and queries
- URLSession async/await patterns
- Background task scheduling
- Privacy manifest requirements

### Third-Party Libraries
Use **context7** to pull current documentation:
- MarkdownUI for chat message rendering
- Highlighter for code syntax highlighting
- Any new SPM dependencies

### Version Freshness
- Cite doc identifiers/versions in code comments
- Store architectural decisions with doc links
- Prefer Apple Developer docs over unofficial sources

## Apple Design & Platform Rules

### Human Interface Guidelines
- Apply HIG spacing, typography, color semantics
- Audit Dynamic Type, Dark Mode, accessibility traits
- Use SF Symbols with verified names/weights
- Support Right-to-Left layouts where applicable

### Swift Concurrency
- Keep networking async with URLSession async/await
- Never block main thread; use actors/Task groups
- Adopt strict concurrency warnings (Swift 6 mode)
- Use @MainActor for UI updates

### Privacy & Security
- Store API keys in keychain via `KeychainService`
- Never log or hardcode credentials
- Add Privacy Manifest if touching Required Reason APIs
- All network requests through `NetworkClient` with timeouts

## Testing Policy

### Unit Testing
- Test business logic with Swift Testing (preferred) or XCTest
- Mock `NetworkClient` for network-dependent code
- Async tests for provider implementations
- Target ≥80% coverage for core services

### UI Testing
- XCUITest for launch flows, navigation, settings
- Test both light/dark mode appearances
- Include accessibility testing (Dynamic Type, VoiceOver)
- Screenshot tests for UI regression detection

### Integration Testing
- End-to-end chat flows with mocked providers
- Settings persistence across app launches
- Background/foreground state transitions

## Common Development Patterns

### Adding New AI Provider
1. **Verify APIs**: Use sosumi to check URLSession patterns
2. **Implement AIProvider protocol**: Follow existing pattern in OpenAIProvider
3. **Add to ProviderID enum**: Update ProviderAPIs.swift
4. **Update AppSettings**: Add enabled models array
5. **Add keychain storage**: Update SettingsStore constants
6. **Test thoroughly**: Unit + integration tests

### SwiftUI View Development
1. **Check HIG compliance**: sosumi search for component guidelines
2. **Support Dynamic Type**: Test with accessibility text sizes
3. **Dark mode support**: Test appearance variations
4. **Accessibility**: Add appropriate labels and traits

### SwiftData Model Changes
1. **Verify migration patterns**: sosumi search for SwiftData migration
2. **Update relationships**: Maintain referential integrity
3. **Test data persistence**: Include in integration tests

## Output Schema (Always Provide)

```json
{
  "result": "1-3 sentences on outcome",
  "logs": ["first 10 lines", "last 10 lines"],  
  "artifacts": ["paths to build products, screenshots, test logs"],
  "notes": ["decisions with doc links"],
  "next": ["bullet follow-ups"],
  "consent_needed": ["any high-impact actions pending"]
}
```

## Implementation Workflow (Canonical)

1. **Project scan**: `discover_projs`, `list_schemes`, `list_sims`
2. **Documentation**: sosumi/context7 lookups for unknown APIs
3. **Code**: Small focused edits via desktop-commander
4. **Build**: `build_sim` → fix warnings before proceeding
5. **Run & observe**: `build_run_sim` → attach logs → stop capture
6. **Test**: `test_sim` + UI tests where UI changed
7. **Accessibility sweep**: Test light/dark, large text, VoiceOver
8. **Cleanup**: Remove temp files, stop log capture
9. **Report**: Structured summary with next steps

## Pitfalls to Avoid

- Never assume scheme/simulator names → always list explicitly
- Never block main thread → use async/await patterns
- Never skip HIG/accessibility checks → test Dynamic Type, dark mode
- Never ignore SwiftData relationship constraints → test cascading deletes
- Never commit API keys → use keychain storage only
- Never implement APIs without sosumi verification → check documentation first

## Dependencies

### Swift Package Manager
- **MarkdownUI**: Chat message rendering with markdown support
- **Highlighter**: Syntax highlighting for code blocks in messages

### Vendor Dependencies  
- **iosMath**: Mathematical formula rendering (located in `Vendor/iosMath/`)

### System Frameworks
- SwiftUI, SwiftData, Foundation, PhotosUI for core functionality
- Network framework for HTTP requests
- Security framework for keychain operations
````

## File: repomix.config.json
````json
{
  "output": {
    "filePath": "chatapp-codebase.md",
    "style": "markdown",
    "headerText": "ChatApp iOS Project Codebase",
    "removeComments": false,
    "removeEmptyLines": false,
    "showLineNumbers": false,
    "copyToClipboard": false
  },
  "ignore": {
    "useGitignore": true,
    "useDefaultPatterns": true,
    "customPatterns": [
      "**/*.xcuserstate",
      "**/xcuserdata/**",
      "**/DerivedData/**",
      "**/Build/**",
      "**/BuildLogs/**",
      "**/.build/**",
      "**/.swiftpm/**",
      "**/docs/**",
      "**/*.dSYM/**",
      "**/*.xcodeproj/xcuserdata/**",
      "**/*.xcodeproj/project.xcworkspace/xcuserdata/**",
      "**/webcanvas/node_modules/**",
      "**/webcanvas/.next/**",
      "**/webcanvas/dist/**",
      "**/*.log",
      "**/*.tmp",
      "**/*.bak",
      "**/Vendor/iosMath/**/*.h",
      "**/Vendor/iosMath/**/*.m",
      "**/*_GUIDE.md",
      "**/*_STRATEGY.md",
      "**/*_PLAN.md",
      "**/ChatApp/WebCanvas/**",
      "**/.DS_Store",
      "**/.vscode/**",
      "**/.idea/**",
      "**/Env/.env",
      "**/Env/*.env"
    ]
  },
  "include": [
    "**/*.swift",
    "**/*.h",
    "**/Info.plist",
    "**/Localizable.strings",
    "**/*.xcconfig",
    "**/project.pbxproj",
    "**/Package.swift",
    "**/Package.resolved",
    "**/*.xctestplan",
    "**/README.md",
    "**/CLAUDE.md",
    "**/.gitignore",
    "**/repomix.config.json",
    "**/ChatApp.entitlements",
    "**/*.xcscheme"
  ],
  "security": {
    "enableSecurityCheck": true
  }
}
````
