# Project Status & Handoff (Rolling)

This document keeps new sessions fully oriented: what we decided, what’s done, what’s next, and how to proceed safely. Update it at the end of every working block.

## Snapshot (2025-09-06)
- **Product**: SwiftUI iOS chat app with streaming AI (SwiftData persistence)
- **Direction**: Migrate chat transcript rendering to a WKWebView-based WebCanvas (markdown-it + Shiki + KaTeX + Mermaid), artifacts-ready.
- **Native UI kept**: Navigation, toolbars, and `InputBar` remain SwiftUI.

## Current State
- **Working**: Native Markdown rendering via `AIResponseView` (MarkdownUI/Highlightr fallbacks), inline + block math via SwiftMath/iosMath or KaTeX `MathWebView` fallback.
- **Streaming**: Implemented in `ChatView.send()` using `OpenAIProvider.streamChat` → updates `streamingText`.
- **Decision**: Switch transcript area to WebCanvas (WKWebView) with progressive block rendering and plugin slot for “artifacts”.

## Milestone: WebCanvas v1 (Artifacts‑Ready Shell)
- **Goal**: Parity with current Markdown features plus streaming, tables, math, code, mermaid; establish artifact iframe slot.
- **Acceptance**:
  - Renders existing chats (user + assistant) identically or better.
  - Streams without reflow jitter (progressive block commit).
  - Tables scroll horizontally if overflow; math renders inline/block; code is Shiki highlighted.
  - Theme switch (light/dark) mirrors app setting; Dynamic Type scale applied.
  - “Artifacts” sandbox mounts and receives events; no security regressions.

## What’s Done
- Theme token layer added (`ThemeTokens.swift`), injected at app root.
- Claude-adjacent ToolCall bubble component for SwiftUI (`ToolCallBubble.swift`).
- WebCanvas bundle copying build phase attached to target; dist `index.html` updated and `toolcard.js` added.
- SSE streaming decoder implemented (`StreamingSSE.swift`), `OpenAIProvider.streamChat` updated.
- SwiftData store recovery fixed (sidecar cleanup) in `ChatAppApp.swift`.
- Markdown code-block trimming bug fixed (no longer drops first character).
- Inline flow layout width calc stabilized.
- PhotosPicker now preserves MIME types (HEIC/PNG/JPEG) and re-encodes only as fallback.
- Info.plist push background mode removed; iCloud and APS entitlements stripped.
- iOS deployment target corrected to 18.0.

## In Progress / Next Up
1) Optional: push Theme token CSS vars into WebCanvas (currently light/dark switch supported).
2) Add artifact iframe mount + JS→Swift event round-trip in WebCanvas.
3) UI polish: apply tokens across more SwiftUI surfaces, add copy buttons for code.
4) Unit tests for `NetworkClient`, `SettingsStore`, and provider error paths.

## Risks & Mitigations
- **WKWebView isolation**: Avoid CDNs; bundle assets. If future WebContainers needed, consider custom URL scheme + COOP/COEP; not in v1.
- **Performance on long chats**: Consider virtualizing older messages if DOM grows too large; not required for v1.
- **Accessibility**: Map text size setting to CSS scale; test VoiceOver and contrast.

## Rollback
- Keep `AIResponseView` behind a feature flag `AppSettings.useWebCanvas`. If issues, toggle off to restore native rendering.

## How To Contribute (Quickstart)
- **Run**: Open `ChatApp.xcodeproj`, run `ChatApp` on iPhone 16 simulator.
- **Where to work**: 
  - Web: `ChatApp/WebCanvas/dist/*` (add files if missing)
  - Swift bridge: `ChatApp/ChatCanvasView.swift` (new)
  - Integration: `ChatApp/ChatView.swift`
- **Validate**:
  - Send a message; verify streaming and scroll-to-bottom.
  - Paste a table, code fence with language, inline `$x$` and block `$$x$$`, and a ```mermaid fence.

## Update Procedure (Every Session)
- **Status**: Edit this file’s Snapshot date and sections above.
- **Decision Log**: Append one-liners to the log below.
- **TODO Board**: Update `docs/TODO.md` checkboxes and add new items.

## Decision Log
- 2025-09-06: Adopt WKWebView WebCanvas with markdown-it + Shiki + KaTeX + Mermaid; artifacts via sandboxed iframes first.
- 2025-09-06: Attach WebCanvas bundling phase; correct deployment target; remove unused push/iCloud capabilities.

## Contacts / Ownership
- **Default Agent**: Apple-Stack Agent (this session)
- **Escalations**: Create `docs/ISSUES.md` with reproducible steps if persistent blockers arise.
