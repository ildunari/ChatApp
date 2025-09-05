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
    static var chatGitHub: Theme {
        // Based on MarkdownUI v2 theming DSL: build styles via chained modifiers.
        Theme.gitHub
            .code {
                FontFamilyVariant(.monospaced)
                BackgroundColor(ChatStyle.codeBG)
            }
            .paragraph { configuration in
                configuration.label
                    .markdownMargin(top: 0, bottom: 8)
            }
    }
}
#endif
