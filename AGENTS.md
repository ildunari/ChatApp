# Repository Guidelines

This guide helps contributors work efficiently in this SwiftUI iOS project.

## Project Structure & Module Organization
- `ChatApp/`: App code — views (`ChatView.swift`, `SettingsView.swift`, `ContentView.swift`), services (`NetworkClient.swift`, `KeychainService.swift`), providers (`AIProvider.swift`, `OpenAIProvider.swift`, `OpenAIImageProvider.swift`), models (`Models.swift`, `Item.swift`), app entry (`ChatAppApp.swift`), config (`Info.plist`), assets (`Assets.xcassets/`), entitlements.
- `ChatAppTests/`: Unit tests (XCTest).
- `ChatAppUITests/`: UI tests (XCUITest).
- `ChatApp.xcodeproj/`, `ChatApp.xctestplan`: Xcode project and test plan.

## Build, Test, and Development Commands
- Open in Xcode: `open ChatApp.xcodeproj`.
- Build (CLI): `xcodebuild -project ChatApp.xcodeproj -scheme ChatApp build`.
- Run tests (CLI): `xcodebuild test -project ChatApp.xcodeproj -scheme ChatApp -destination 'platform=iOS Simulator,name=iPhone 16'`.
- Run a specific test: `xcodebuild test -only-testing:ChatAppTests/YourTestName …` (adjust names). Use `xcrun simctl list devices` to pick an available simulator.

## Coding Style & Naming Conventions
- Indentation: 4 spaces; trim trailing whitespace.
- Swift: camelCase for vars/functions; PascalCase for types; one primary type per file.
- View files end with `View` (e.g., `SettingsView.swift`). Use `// MARK:` to group sections and extensions.
- Prefer value types (`struct`), dependency injection via initializers, and immutable state where practical.

## Testing Guidelines
- Frameworks: XCTest + XCUITest. Keep tests fast and isolated from network; mock `NetworkClient`.
- Naming: Mirror target type with `Tests` suffix (e.g., `NetworkClientTests`). UI tests live in `ChatAppUITests`.
- Coverage: Aim ≥80% for core services (`NetworkClient`, `KeychainService`). Use the provided `.xctestplan` for full-suite runs.

## Commit & Pull Request Guidelines
- History shows no established convention; use Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.
- PRs include: concise summary, scope, before/after screenshots for UI changes, test steps, linked issues, and potential risks/roll-back plan.

## Security & Configuration Tips
- Never hardcode API keys; store secrets with `KeychainService` and expose configuration via Settings.
- Do not commit secrets or personal data; review `Info.plist` diffs carefully.
- Network code belongs in `NetworkClient`; add timeouts, error handling, and avoid blocking the main thread.

## Agent Behavior (Xcode & MCP)
- Control loop: Plan → Ask (if missing context) → Execute (small, safe batches) → Verify (build/test pass + logs) → Summarize → Confirm for high‑impact actions.
- Tool routing (use in this order):
  - `XcodeBuildMCP`: primary for build/test/run, simulators, logs. Prefer:
    - List sims: `list_sims` → pick available iOS version.
    - Build: `build_sim` or `build_macos` with `scheme=ChatApp`.
    - Run on sim: `build_run_sim` (set `simulatorName='iPhone 16'` or discover via `list_sims`).
    - Logs: `start_sim_log_cap` / `stop_sim_log_cap`; screenshots via `screenshot` when debugging UI.
  - `Context7` (docs retrieval): resolve library IDs, then fetch focused docs. Examples:
    - `resolve-library-id('upstash/context7')` → `get-library-docs(topic='usage', tokens=4000)`.
    - `resolve-library-id('NSHipster/sosumi.ai')` (or `sosumi.ai` if different org) → `get-library-docs(topic='swift examples', tokens=4000)`.
  - Desktop Commander: fallback for local file ops only (never external writes without consent).
- Documentation hygiene: prefer Apple Developer docs; augment with Context7 and the `sosumi.ai` repo for Apple‑platform nuances; cite sources in summaries when used.
- Safety & permissions: dry‑run first (e.g., `show_build_settings`), confirm before Level ≥3 actions (launching, installing, deleting, system changes). Provide previews and clear revert steps.
- Pitfalls to avoid: assuming a specific simulator, running CocoaPods/Fastlane if not present, modifying signing without confirmation, or blocking the main thread in SwiftUI.
- Output contract for actions: include `plan`, `commands`, `artifacts` (e.g., build paths, screenshots), `next`, and `consent_needed`.

### Git Workflow
- Always keep `main` deployable. Use feature branches for risky work.
- After any major change or addition: commit with a Conventional Commit message and push immediately to `origin main` (or the active feature branch, then PR to `main`).
- Example: `feat: add OpenAI image provider` then `git push -u origin main`.
- Avoid committing user-specific Xcode data; `.gitignore` covers common noise (DerivedData, `xcuserdata`, logs).
