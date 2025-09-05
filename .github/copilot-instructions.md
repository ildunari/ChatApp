# Repo baseline (Xcode)

## Project
Apple platforms app, Swift 5.10+, SwiftPM only. UI: SwiftUI. Architecture: MVVM. Minimum iOS target: 17 (unless code says otherwise).

## Build & test (do these first)
Use **XcodeBuildMCP** tools to avoid guessing. If a scheme isn’t specified in the user prompt:
1) List schemes; choose the primary app scheme.
2) Build & test on iOS Simulator (iPhone 15). Example fallback if needed:
   xcodebuild clean test -scheme <primary-scheme> -destination 'platform=iOS Simulator,name=iPhone 15' -quiet

## Lint/format
If `.swiftlint.yml` exists, run SwiftLint and fix warnings before proposing changes.

## Concurrency & logging
Use async/await; mark UI-touched code `@MainActor`. Use `Logger(subsystem: Bundle.main.bundleIdentifier ?? "App", category: "App")`.

## Networking
URLSession + Codable. Never weaken ATS without explicit request; if asked, propose minimal key with justification.

## Guardrails
Do not edit `project.pbxproj` directly. Prefer .xcconfig or Xcode UI steps; describe the steps if necessary. For entitlements and privacy, prefer “Signing & Capabilities” and valid Apple keys.

## Tests
Prefer Swift Testing when available. Keep tests hermetic (no network). Put files under `Tests/**`, suffixed `*Tests.swift`.

## MCP usage policy
• **XcodeBuildMCP**: default for build/test/simulator/device.  
• **Context7**: default for SDK/syntax lookups (Apple/Swift symbols, frameworks).  
• **GitHub MCP**: issues/PR context when refactoring or writing changesets.
