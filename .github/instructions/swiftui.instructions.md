---
applyTo:
  - "**/*.swift"
  - "App/**"
  - "Features/**/UI/**"
---
SwiftUI rules of engagement

Goals:
- Views are **pure** (layout/state derivation only).
- Side-effects go to **ViewModels** or injected services.

Do:
- Use `@Observable` (or `@StateObject` if interop) for models; mark ViewModels **@MainActor**.
- Use `NavigationStack`, value-type views, and dependency injection via environment or initializers.
- Prefer modifiers/layout over fixed frames; fall back to `GeometryReader` sparingly.
- Add **accessibility**: labels, traits, and Dynamic Type support (avoid text in images).

Don’t:
- Put networking/DB calls in Views.
- Use `print` for diagnostics; use `Logger`.

Design patterns to prefer:
- Small composable views; no “God views”.
- Derive view state from model; no redundant `@State` copies.
- Use `Task { await vm.load() }` for async onAppear work.

Example snippet:
```swift
@MainActor @Observable final class ProfileVM {
  private let api: ProfileAPI
  init(api: ProfileAPI) { self.api = api }
  var profile: Profile?
  func load() async throws { profile = try await api.fetchMe() }
}

struct ProfileView: View {
  @State private var vm = ProfileVM(api: LiveProfileAPI())
  var body: some View {
    Group {
      if let p = vm.profile { Text(p.name) } else { ProgressView() }
    }
    .task { try? await vm.load() }
    .navigationTitle("Profile")
  }
}
