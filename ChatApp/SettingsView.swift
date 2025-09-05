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
                VStack(alignment: .leading, spacing: 6) {
                    Text(label)
                        .font(titleFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .padding(.top, 14)
                    Text(sample)
                        .font(bodyFont)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 4)
                }
                .padding(14)
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
