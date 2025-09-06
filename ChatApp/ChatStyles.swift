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
