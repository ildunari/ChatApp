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
    static let fieldHeight: CGFloat = 44
    static let fieldCorner: CGFloat = 18
}

struct InputBar: View {
    @Binding var text: String
    var onSend: () -> Void
    var onMic: (() -> Void)? = nil
    var onLive: (() -> Void)? = nil
    var onPlus: (() -> Void)? = nil
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        HStack(spacing: InputMetrics.rowSpacing) {
            Button(action: { onPlus?() }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
            }
            .frame(width: InputMetrics.plusSize, height: InputMetrics.plusSize)
            .background(Circle().fill(Color.secondary.opacity(0.15)))

            HStack(spacing: 8) {
                TextField("Ask anything", text: $text, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .lineLimit(1...6)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        // This captures Return key on iOS (with shift+return for new line)
                        if !text.isEmpty {
                            onSend()
                        }
                    }
                    .submitLabel(.send)
                Button(action: { onMic?() }) {
                    Image(systemName: "mic")
                        .foregroundStyle(.secondary)
                }
                Button(action: onSend) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                // New send button with paper plane icon
                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .frame(minHeight: InputMetrics.fieldHeight, maxHeight: 120)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: InputMetrics.fieldCorner, style: .continuous)
                    .fill(Color.secondary.opacity(0.15))
            )
        }
        .padding(.horizontal, InputMetrics.edgePadding)
        .padding(.bottom, 8)
    }
}
