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
- Codebase scanned; plan + spec written (see `docs/WEB_CANVAS_MIGRATION.md`).
- Provider + streaming stable (`OpenAIProvider.streamChat`).
- Input bar UX improved (growing field, send button, mic visibility toggle).

## In Progress / Next Up
1) Create Web bundle skeleton under `ChatApp/WebCanvas/dist/` (index.html, app.css, app.bundle.js).
2) Add Swift bridge view `ChatCanvasView` (WKWebView + message handlers in custom content world).
3) Wire ChatView to use WebCanvas for transcript, keep `InputBar` and toolbar.
4) Implement progressive streaming (`startStream/appendDelta/endStream`).
5) Add artifact iframe mount API (sandboxed) and a basic demo panel.

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

## Contacts / Ownership
- **Default Agent**: Apple-Stack Agent (this session)
- **Escalations**: Create `docs/ISSUES.md` with reproducible steps if persistent blockers arise.

