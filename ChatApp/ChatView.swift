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
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(sortedMessages) { message in
                            HStack(alignment: .top, spacing: 8) {
                                Text(message.role == "user" ? "You" : "AI")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, alignment: .leading)
                                Group {
                                    if message.role == "assistant" {
                                        AIResponseView(content: message.content)
                                    } else {
                                        Text(message.content)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal)
                        }
                        if let partial = streamingText {
                            HStack(alignment: .top, spacing: 8) {
                                Text("AI")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, alignment: .leading)
                                AIResponseView(content: partial)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal)
                        } else if isSending {
                            HStack {
                                ProgressView()
                                Text("Thinking…")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, contentBottomPadding)
                .onChange(of: chat.messages.count) { _ in
                    if let last = sortedMessages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
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

            let reply: String
            if let streaming = provider as? AIStreamingProvider {
                streamingText = ""
                reply = try await streaming.streamChat(
                    messages: aiMessages,
                    model: model,
                    temperature: settings.defaultTemperature,
                    maxOutputTokens: settings.defaultMaxTokens,
                    reasoningEffort: nil,
                    verbosity: nil
                ) { delta in
                    Task { @MainActor in
                        self.streamingText = (self.streamingText ?? "") + delta
                    }
                }
            } else if let adv = provider as? AIProviderAdvanced {
                reply = try await adv.sendChat(
                    messages: aiMessages,
                    model: model,
                    temperature: settings.defaultTemperature,
                    maxOutputTokens: settings.defaultMaxTokens,
                    reasoningEffort: nil,
                    verbosity: nil
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
