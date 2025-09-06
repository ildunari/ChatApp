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
    static let sendSize: CGFloat = 32
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
                    // Voice controls when input is empty
                    Button(action: { onMic?() }) {
                        Image(systemName: "mic")
                            .foregroundStyle(.secondary)
                    }
                    Button(action: { onLive?() }) {
                        Image(systemName: "waveform.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.system(size: 20, weight: .semibold))
                    }
                } else {
                    // Send button only when there is text, styled like a small circle
                    Button(action: onSend) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.blue)
                            .frame(width: InputMetrics.sendSize, height: InputMetrics.sendSize)
                            .background(Circle().fill(Color.secondary.opacity(0.15)))
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .frame(minHeight: InputMetrics.fieldHeight, maxHeight: 120)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: InputMetrics.fieldCorner, style: .continuous)
                    .fill(Color.secondary.opacity(0.15))
            )
        }
        .padding(.horizontal, InputMetrics.edgePadding)
        .padding(.bottom, 8)
    }
}
