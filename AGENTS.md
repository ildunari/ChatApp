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

## Project Status & Docs
- **Rolling Status/Handoff**: `docs/PROJECT_STATUS.md` (update each work session)
- **Migration Spec**: `docs/WEB_CANVAS_MIGRATION.md` (source of truth for WebCanvas)
- **Rolling TODO**: `docs/TODO.md` (checklist; keep fresh)

Update flow per session:
- Read `PROJECT_STATUS.md` (Snapshot date, Milestone, Risks)
- Pick TODOs from `docs/TODO.md`; append details to Status → In Progress
- After changes: update Status Snapshot + Decision Log; adjust TODOs
- Include test notes and screenshots in your summary output

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

## Agent Role & Responsibilities
- You are the Apple-Stack Agent for this iOS app: plan, verify, implement, test, and maintain. Never invent APIs; verify Apple APIs with `sosumi` and libraries with `context7` before coding. Prefer Swift 6 strict concurrency and XCTest/Swift Testing where appropriate. Align UI with Apple HIG and SF Symbols.

## Smart Control Loop
- Plan: Break work into ≤8 atomic steps; keep a live plan via the `update_plan` tool.
- Verify: Use `sosumi.searchAppleDocumentation` and `context7.get-library-docs` for any unfamiliar API.
- Act: Make small, reversible edits; build and run on a simulator first.
- Test: Run unit/UI tests; capture failures and screenshots.
- Clean: Remove temporary artifacts and debug flags.
- Report: Summarize results with commands run, artifacts, next steps.

## MCP Tooling & Routing
- XcodeBuildMCP: Primary for build/test/run/simulators/logs.
  - Discover: `discover_projs` → `list_schemes` (use `ChatApp`) → `list_sims`.
  - Build/Run: `build_sim` / `build_run_sim` with explicit simulator (e.g., `iPhone 16`).
  - Logs/UI: `start_sim_log_cap` → `stop_sim_log_cap`; `screenshot`, `tap`, `gesture`, `type_text` for UI automation.
- Xcode Diagnostics MCP: Fast visibility into errors/warnings from the latest build logs.
  - List projects: `xcode-diagnostics.get_xcode_projects()` → pick the ChatApp entry.
  - Fetch diagnostics: `xcode-diagnostics.get_project_diagnostics({ project_dir_name: "<DerivedDataName>", include_warnings: true })`.
  - Use when: builds produce errors/warnings; after CI runs; before PR to ensure zero critical issues.
  - Act on output: prioritize errors, address deprecations, and eliminate main-thread blockers; re-run `build_sim` to confirm.
- sosumi (Apple docs authority): Verify SwiftUI/SwiftData/URLSession/Background tasks and privacy manifest details.
- context7 (Library docs): Resolve library IDs, fetch focused docs for MarkdownUI/Highlighter/iosMath or any new SPM packages.
- Desktop Commander: Fallback for local file ops and process control when native editing isn’t enough. Keep edits minimal and diffable.
- GitHub MCP: Use for repository intel (branches, files, issues, PRs) and to validate remotes/auth. Push via standard `git` CLI; MCP ensures auth context.

## Zero‑Hallucination Verification
- Apple APIs: Verify with `sosumi.searchAppleDocumentation` before implementing or changing platform APIs.
- Third‑party libs: Verify with `context7.get-library-docs` and cite versions in code comments when relevant.
- Version freshness: Prefer official Apple docs; add short notes/links for architectural decisions.

## Canonical Implementation Workflow
1. Discover: `discover_projs`, `list_schemes`, `list_sims`.
2. Documentation: sosumi/context7 lookups for unknown APIs.
3. Code: Small focused edits; avoid blocking the main thread.
4. Build: `build_sim` → fix warnings before proceeding.
5. Run & Observe: `build_run_sim` → attach logs → `stop_sim_log_cap`.
6. Test: `xcodebuild test -project ChatApp.xcodeproj -scheme ChatApp -destination 'platform=iOS Simulator,name=iPhone 16'` (or use `ChatApp.xctestplan`); include UI tests where UI changed.
7. Accessibility: Verify Dynamic Type, dark mode, VoiceOver.
8. Cleanup: Remove temp files/log captures.
9. Report: Structured summary with artifacts and next steps.

## GitHub Updates (MCP‑Authenticated Pushes)
- Prepare commit:
  - `git add -A`
  - `git commit -m "feat: <concise summary>"`
- Push (direct or via feature branch):
  - Direct to main: `git push origin main`
  - Feature branch: `git checkout -b feat/<topic>` → commit → `git push -u origin feat/<topic>`
- Authentication: The GitHub MCP integration provides the token; pushes via `git` use this identity automatically.
- Verify with GitHub MCP (optional):
  - Repo info: `github_repo_info(repo_url: "https://github.com/<org>/<repo>")`
  - Branches: `github_list_branches(...)`
  - PR status: `github_list_pulls(...)`
- Open PR (if using feature branches): create via GitHub UI or your CLI; link to build/test artifacts and include screenshots for UI changes.

## Simulator Refresh (After Significant Changes)
- Reuse existing simulator. Do not create new devices unless user asks.
- Flow (assumes an already booted device from `list_sims`):
  1) Build: `xcodebuildmcp.build_sim({ projectPath: "<proj>", scheme: "ChatApp", simulatorId: "<BOOTED_UUID>" })`
  2) Path: `get_sim_app_path({ projectPath: "<proj>", scheme: "ChatApp", platform: 'iOS Simulator', simulatorId: '<BOOTED_UUID>' })`
  3) Install: `install_app_sim({ simulatorUuid: '<BOOTED_UUID>', appPath: '<from step 2>' })`
  4) Launch: `launch_app_sim({ simulatorUuid: '<BOOTED_UUID>', bundleId: 'Kosta.ChatApp' })`
  5) Optional logs: `start_sim_log_cap({ simulatorUuid: '<BOOTED_UUID>', bundleId: 'Kosta.ChatApp', captureConsole: true })` → `stop_sim_log_cap(...)` and attach head/tail.
- Handle pitfalls proactively:
  - If “Requires newer iOS”: pick the booted runtime or rebuild for that runtime version; don’t spin up a new device.
  - If “Launching…” hangs: delete the app on the same device, restart that simulator, then reinstall/launch.
  - Never create duplicate sims; prefer the single booted device.

## Proactive Agent Mode (Default)
- After any meaningful edit:
  - Build → run quick tests (`xcodebuild test` or `test_sim`), fix small issues now.
  - Refresh the simulator app if UI or runtime behavior changed (see section above).
  - Capture 1–2 screenshots and 10/10 log lines for the report.
  - Commit with Conventional Commit and push to `main` (or feature branch) automatically unless user disabled auto‑push for the task.
- Offer “next step” options unprompted, e.g., “Run full UI tests?”, “Bundle KaTeX assets?”, “Add reset data toggle?”, and be ready to execute.
- Clean up artifacts: remove temporary files, revert debug flags, and ensure `.gitignore` noise isn’t added.

## Pitfalls to Avoid
- Assuming scheme/simulator names: always list explicitly and pick a concrete simulator.
- Blocking the main thread: keep networking and heavy work off the main actor.
- Skipping HIG/accessibility: validate Dynamic Type, dark mode, and VoiceOver.
- SwiftData integrity: maintain relationships and test cascading deletes.
- Secrets: never commit API keys; rely on `KeychainService` and Settings.

## Output Contract for Tasks
- Plan: current steps and status.
- Commands: exact invocations used.
- Artifacts: paths to builds, logs, screenshots.
- Next: immediate follow‑ups and risks.
- Consent needed: any high‑impact actions awaiting approval.

---

## Codebase Map (Repo‑Specific)

- App Entry
  - `ChatApp/ChatAppApp.swift` — Configures SwiftData `ModelContainer` with a persistent store in Application Support and a one‑time recovery path if the SQLite store is corrupted.

- Data Models (SwiftData)
  - `ChatApp/Models.swift`
    - `Chat { id, title, createdAt, messages[] }` (cascade delete to messages)
    - `Message { id, role(user|assistant), content, createdAt, chat }`
    - `AppSettings { defaultProvider, defaultModel, defaultSystemPrompt, defaultTemperature, defaultMaxTokens, <enabled models per provider>, interfaceTheme, interfaceFontStyle, interfaceTextSizeIndex, chatBubbleColorID }`

- Views (SwiftUI)
  - `ChatApp/ContentView.swift` — Chat list (NavigationStack), creates initial chat on first launch.
  - `ChatApp/ChatView.swift` — Chat screen with suggestions, photo picker attachments, streaming responses, model menu in toolbar.
  - `ChatApp/AIResponseView.swift` — Segments assistant content into Markdown, Code, and Math blocks; supports inline `$...$` math and block `$$...$$` math with fallbacks.
  - `ChatApp/ChatUI.swift` — `SuggestionChips`, `InputBar` components.
  - `ChatApp/ChatStyles.swift` — MarkdownUI theme and shared visual constants.
  - `ChatApp/MathWebView.swift` — KaTeX WebView fallback; prefers bundled assets under `ChatApp/KaTeX/`.
  - `ChatApp/SettingsView.swift` — Providers, default chat, and interface settings flows (nested screens).

- Settings & Services
  - `ChatApp/SettingsStore.swift` — ObservableObject bridging SwiftData `AppSettings` with Keychain; primes from `Env/DevSecrets.env` in Debug via `EnvLoader`.
  - `ChatApp/EnvLoader.swift` — Loads `DevSecrets.env` from bundle (Debug) to ease local development.
  - `ChatApp/KeychainService.swift` — Save/read/delete API keys securely.
  - `ChatApp/SystemPrompt.swift` — Master system prompt rules for the assistant.

- Providers & Networking
  - `ChatApp/AIProvider.swift` — Chat provider protocols, including advanced + streaming interfaces.
  - `ChatApp/OpenAIProvider.swift` — Implements OpenAI Responses API (non‑stream + SSE streaming with helpful HTTP error mapping).
  - `ChatApp/ImageProvider.swift` / `ChatApp/OpenAIImageProvider.swift` — Image generation contract and OpenAI Images implementation.
  - `ChatApp/ProviderAPIs.swift` — Key verification and model listing for OpenAI/Anthropic/Google/XAI.
  - `ChatApp/NetworkClient.swift` — Shared URLSession with sane timeouts; `get`/`postJSON` helpers.

- Assets & Config
  - `ChatApp/KaTeX/*` — Local KaTeX JS/CSS used by `MathWebView` when available.
  - `ChatApp/Assets.xcassets/` — App icons and colors.
  - `ChatApp/Info.plist`, `ChatApp/ChatApp.entitlements` — App metadata and capabilities.

- Tests
  - `ChatAppTests/*` — Unit test target scaffold.
  - `ChatAppUITests/*` — UI test target scaffold, launch performance test, screenshot on launch.
  - `ChatApp.xctestplan` — Test plan for coordinated runs.

## Build & Dependencies Snapshot

- Schemes: `ChatApp`, `MarkdownUI` (verified via `xcodebuild -list`, 2025‑09‑06)
- SPM (resolved locally):
  - MarkdownUI 2.4.1, cmark‑gfm 0.6.0, NetworkImage 6.0.1, SwiftMath 1.7.3, HighlighterSwift 1.1.7
- Quick build check (2025‑09‑06): `xcodebuild -project ChatApp.xcodeproj -scheme ChatApp -destination 'generic/platform=iOS Simulator' build` succeeded.

## Key Flows

- Chat Send
  1) User types in `InputBar` → `ChatView.send()` inserts a user `Message`.
  2) Settings resolved from `SettingsStore` → provider constructed (`OpenAIProvider` today).
  3) Messages mapped to `AIMessage` (text + optional image parts via `PhotosPicker`).
  4) Streaming path updates `streamingText`; final reply is inserted as assistant `Message`.
  5) Title autoupdates from first user message if default.

- Settings
  - `SettingsView` edits `SettingsStore` fields; on save, writes SwiftData + Keychain.
  - Providers screen verifies API keys and lists models via `ProviderAPIs`.

- Rendering
  - Markdown (MarkdownUI theme), code highlighting (Highlightr/HighlighterSwift fallback), math via SwiftMath/iosMath or KaTeX WebView fallback.

## Troubleshooting Notes

- OpenAI streaming errors are surfaced with friendly messages (401/403/404/429/5xx) in `OpenAIProvider.streamChat`.
- If chat persistence breaks, `ChatAppApp` attempts a one‑time SQLite store cleanup and re‑init.
- If math doesn’t render, ensure KaTeX assets are present (or allow CDN) and that inline `$...$` is balanced.
- No API keys? In Debug, add values to `Env/.env` (copied to bundle as `DevSecrets.env`) to prime Keychain on first run.

## Backlog (Living)

- Implement additional chat providers (Anthropic, Google, XAI) conforming to `AIProvider`/`AIProviderAdvanced`/`AIStreamingProvider`.
- Add UI for image generation using `OpenAIImageProvider` and a lightweight gallery viewer.
- Unit tests for `NetworkClient`, `KeychainService`, `SettingsStore`, `OpenAIProvider` (including SSE aggregation and error paths).
- UI tests: first‑run flow (initial chat), model picker, Settings verify/refresh.
- Bundle KaTeX offline and gate CDN usage behind a build flag; consider a privacy manifest if needed.
- Model list caching per provider + manual refresh.

## Decision Log

- 2025‑09‑06: Added repo‑specific Codebase Map, build/dependency snapshot, key flows, troubleshooting, and backlog to AGENTS.md.
