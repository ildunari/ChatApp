# Icons: Phosphor (Bold) as Default

We use the Phosphor icon set in Bold weight via the Swift package `phosphor-icons/swift`, with a lightweight wrapper for easy swapping and fallbacks.

## Package

- Repository: https://github.com/phosphor-icons/swift
- Integration: already added to the Xcode project (branch `main`). If you need to re-add:
  - Xcode → Project → Package Dependencies → `+` → URL above → Add to `ChatApp`.

## Usage

Use the convenience wrapper instead of `Image(systemName:)` directly:

```swift
// Import nothing extra; call the wrapper helpers
AppIcon.plus(18)
AppIcon.paperPlane(18)
AppIcon.gear()
AppIcon.starsHeader(14)
```

The wrapper (`ChatApp/Icons.swift`) renders Phosphor when available, with SF Symbols fallback when the package isn’t present (e.g., for quick local builds).

## Weight & Style

- Default weight is Bold to match the visual language.
- Color is inherited from `.foregroundStyle` of the calling view.

## Adding New Icons

1) Pick the icon from https://phosphoricons.com/?weight=bold
2) Find the Swift symbol name (kebab-case becomes snake_case).
3) Add a helper to `AppIcon` following the existing pattern.

Example:

```swift
@ViewBuilder static func heart(_ size: CGFloat = 18) -> some View {
    #if canImport(PhosphorSwift)
    Ph.heart.bold.frame(width: size, height: size)
    #else
    Image(systemName: "heart.fill").font(.system(size: size, weight: .bold))
    #endif
}
```

