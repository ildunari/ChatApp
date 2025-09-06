# TODO Board (Rolling, Check as You Go)

- [x] Create Web bundle skeleton under `ChatApp/WebCanvas/dist/`
  - [x] `index.html` with strict CSP (present); include `toolcard.js`
  - [x] `app.css`/`app.bundle.js` present in repo
  - [x] `toolcard.js` (adds expandable tool card UI)
- [x] Add Swift bridge `ChatCanvasView.swift`
  - [x] WKWebView configuration + custom `WKContentWorld`
  - [x] Register `bridge` message handler (JS→Swift)
  - [x] Implement Swift→JS calls: `loadTranscript/startStream/appendDelta/endStream/setTheme/scrollToBottom`
  - [x] Queue calls until `ready` event
  - [x] Add `appendToolCard(...)` API calling ChatCanvas or fallback ToolCard
- [x] Integrate into `ChatView.swift`
  - [x] Replace transcript area with `ChatCanvasView` (behind feature flag exists)
  - [x] Convert `chat.messages` to `[CanvasMessage]` and `loadTranscript`
  - [x] Wire streaming to `startStream/appendDelta/endStream`
  - [x] Maintain error banner and suggestions UI
- [x] Settings toggle
  - [x] `useWebCanvas: Bool` exists in `AppSettings`
  - [x] UI toggle present in Settings
  - [x] Default on for now
- [x] Theming & accessibility
  - [x] Theme tokens layer + injection at root
  - [x] Apply tokens to background + user bubbles; more polish later
  - [x] `setTheme(light|dark)` already forwarded to WebCanvas
  - [ ] Text size scaling based on `interfaceTextSizeIndex`
  - [ ] Keyboard focus stays on `InputBar`
- [ ] Artifacts v1
  - [ ] `artifact.mount(config)` sandboxed iframe
  - [ ] Demo: simple HTML/CSS/JS, and Sandpack embed option
  - [ ] Event round‑trip (JS→Swift `artifact.event`)
- [ ] Tests & validation
  - [x] Manual: basic build + streaming code paths
  - [ ] Manual: streaming, tables, math, code, mermaid
  - [ ] UI test: open chat, send prompt, wait for canvas paint, screenshot
  - [ ] Performance: large transcript smoke test
- [x] Rollout & docs
  - [x] Attach WebCanvas bundle phase to target
  - [x] Update `docs/PROJECT_STATUS.md` Snapshot & Decision Log
  - [x] Keep this board fresh; add regressions as new tasks

---

New (Design/Infra/Provider)
- [x] Claude-adjacent ToolCall bubble for SwiftUI (`ToolCallBubble.swift`)
- [x] WebCanvas tool card (`toolcard.js`) + Swift bridge method
- [x] Fix SwiftData sidecar cleanup
- [x] Fix Markdown code-block trimming
- [x] SSE decoder + wire `OpenAIProvider.streamChat`
- [x] PhotosPicker MIME handling (JPEG/PNG/HEIC)
- [x] Remove push background mode + iCloud/APS entitlements
- [x] Set deployment target to 18.0
- [ ] Apply tokens to more SwiftUI surfaces (assistant header, dividers, code backgrounds)
- [ ] Add copy buttons for code blocks
- [ ] Add unit tests for `NetworkClient`, `SettingsStore`, provider error mapping

Backlog / Nice‑to‑Have
- [ ] Virtualize very long transcripts
- [ ] “Copy code” buttons + section anchors in the canvas
- [ ] Per‑provider badges in assistant header
- [ ] WebContainers experiment (requires custom URL scheme + COOP/COEP)
