# TODO Board (Rolling, Check as You Go)

- [ ] Create Web bundle skeleton under `ChatApp/WebCanvas/dist/`
  - [ ] `index.html` with strict CSP
  - [ ] `app.css` (chat typography, tables, code, math, mermaid)
  - [ ] `app.bundle.js` (ESM bundle; Renderer class; bridge API)
- [ ] Add Swift bridge `ChatCanvasView.swift`
  - [ ] WKWebView configuration + custom `WKContentWorld`
  - [ ] Register `bridge` message handler (JS→Swift)
  - [ ] Implement Swift→JS calls: `loadTranscript/startStream/appendDelta/endStream/setTheme/scrollToBottom`
  - [ ] Queue calls until `ready` event
- [ ] Integrate into `ChatView.swift`
  - [ ] Replace transcript area with `ChatCanvasView` (behind feature flag)
  - [ ] Convert `chat.messages` to `[CanvasMessage]` and `loadTranscript`
  - [ ] Wire streaming to `startStream/appendDelta/endStream`
  - [ ] Maintain error banner and suggestions UI
- [ ] Settings toggle
  - [ ] Add `useWebCanvas: Bool` to `AppSettings`
  - [ ] UI switch in `SettingsView` → Interface section
  - [ ] Default on (Debug), off (Release) until validated
- [ ] Theming & accessibility
  - [ ] `setTheme(light|dark)` mapping from app setting
  - [ ] Text size scaling based on `interfaceTextSizeIndex`
  - [ ] Keyboard focus stays on `InputBar`
- [ ] Artifacts v1
  - [ ] `artifact.mount(config)` sandboxed iframe
  - [ ] Demo: simple HTML/CSS/JS, and Sandpack embed option
  - [ ] Event round‑trip (JS→Swift `artifact.event`)
- [ ] Tests & validation
  - [ ] Manual: streaming, tables, math, code, mermaid
  - [ ] UI test: open chat, send prompt, wait for canvas paint, screenshot
  - [ ] Performance: large transcript smoke test
- [ ] Rollout & docs
  - [ ] Flip default on for Release once green
  - [ ] Update `docs/PROJECT_STATUS.md` Snapshot & Decision Log
  - [ ] Keep this board fresh; add regressions as new tasks

Backlog / Nice‑to‑Have
- [ ] Virtualize very long transcripts
- [ ] “Copy code” buttons + section anchors in the canvas
- [ ] Per‑provider badges in assistant header
- [ ] WebContainers experiment (requires custom URL scheme + COOP/COEP)

