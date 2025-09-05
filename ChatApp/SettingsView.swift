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
                Section("Defaults") {
                    Picker("Default Provider", selection: $store.defaultProvider) {
                        Text("OpenAI").tag("openai")
                        Text("Anthropic").tag("anthropic")
                        Text("Google").tag("google")
                        Text("XAI").tag("xai")
                    }
                    TextField("Default Model", text: $store.defaultModel)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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
                        ModelCheckRow(title: m, isOn: bindingForModel(m))
                    }
                }
            }
        }
        .navigationTitle(provider.displayName)
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
        await MainActor.run {
            verified = ok
            verifying = false
        }
    }

    private func reloadModels() async {
        loadingModels = true
        do {
            let models = try await ProviderAPIs.listModels(provider: provider, apiKey: apiKey)
            await MainActor.run {
                self.available = models
                // Initialize enabled set if empty
                if models.isEmpty == false {
                    switch provider {
                    case .openai: if store.openAIEnabled.isEmpty { store.openAIEnabled = Set(models.prefix(5)) }
                    case .anthropic: if store.anthropicEnabled.isEmpty { store.anthropicEnabled = Set(models.prefix(5)) }
                    case .google: if store.googleEnabled.isEmpty { store.googleEnabled = Set(models.prefix(5)) }
                    case .xai: if store.xaiEnabled.isEmpty { store.xaiEnabled = Set(models.prefix(5)) }
                    }
                }
            }
        } catch {
            await MainActor.run { self.available = [] }
        }
        loadingModels = false
    }
}

private struct ModelCheckRow: View {
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOn ? .blue : .secondary)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
            }
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
                    Slider(value: $store.temperature, in: 0...2, step: 0.05)
                }
                VStack(alignment: .leading) {
                    HStack { Text("Max Tokens"); Spacer(); Text("\(store.maxTokens)").foregroundStyle(.secondary) }
                    Slider(value: Binding(get: { Double(store.maxTokens) }, set: { store.maxTokens = Int($0) }), in: 64...8192, step: 32)
                }
            }
        }
        .navigationTitle("Default Chat")
    }
}

#Preview {
    let container = try! ModelContainer(for: Chat.self, Message.self, AppSettings.self)
    let context = ModelContext(container)
    return SettingsView(context: context)
        .modelContainer(container)
}
