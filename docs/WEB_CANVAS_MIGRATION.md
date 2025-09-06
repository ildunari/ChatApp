# WebCanvas Migration Spec (WKWebView + markdown‑it + Shiki + KaTeX + Mermaid)

Purpose: Replace native Markdown view with a single HTML/CSS/JS canvas that supports streaming, tables, math, code, mermaid, and an artifacts slot. Keep native `InputBar` and navigation.

## Deliverables
- `ChatApp/WebCanvas/dist/index.html` — strict CSP; mounts app + artifacts roots.
- `ChatApp/WebCanvas/dist/app.css` — compact chat styles; dense tables; Shiki tokens; KaTeX & Mermaid tweaks.
- `ChatApp/WebCanvas/dist/app.bundle.js` — ESM bundle exporting `window.ChatCanvas` API.
- `ChatApp/ChatCanvasView.swift` — WKWebView wrapper, message bridge, typed Swift API.

## JS API (window.ChatCanvas)
- `loadTranscript(messages)` → render full array.
- `startStream(id)` / `appendDelta(id, delta)` / `endStream(id)` → progressive block rendering.
- `setTheme(lightOrDark)` → swap CSS + Shiki theme.
- `scrollToBottom()` → stick to tail.
- `artifact.mount(config)` → sandboxed iframe (or Sandpack) mount.

Message format `messages[]`:
```
{ id: string, role: 'user'|'assistant', content: string, createdAt: number }
```

## Swift API (ChatCanvasView)
- `loadTranscript(_ items: [CanvasMessage])`
- `startStream(id: String)` / `appendDelta(id: String, delta: String)` / `endStream(id: String)`
- `setTheme(_ theme: CanvasTheme)` / `scrollToBottom()`
- Queues calls until it receives `{type:'ready'}` from JS.

Message handler (JS→Swift) single channel `bridge`:
- `ready`, `height`, `linkClick{href}`, `copy{text}`, `artifact.event{id,data}`, `error{message}`.

## Streaming Algorithm (Deterministic)
- Maintain a buffer for the active assistant block.
- On `appendDelta`, append text, reparse only the tail (last few KB), commit closed blocks into DOM.
- Apply KaTeX and Mermaid transforms on block commit or `endStream` (not every delta).
- Keep one warm Shiki highlighter; pre‑load 1 light + 1 dark theme.

## Artifacts v1
- `artifact.mount({ id, title, sandbox: true, html?, css?, js?, sandpack? })` creates an iframe in `#artifacts`.
- Security: use `sandbox` attribute without `allow-same-origin` unless strictly required. No top navigation.
- Events: iframe `postMessage` → JS forwards as `artifact.event` to Swift.

## Theming & Accessibility
- CSS vars for foreground/background, borders, spacing.
- Scale base font size from app’s `interfaceTextSizeIndex` (optional `setTextScale` extension later).
- Respect dark/light mapping via `setTheme`.

## Integration Points
1) In `ChatView`, replace the LazyVStack transcript with `ChatCanvasView` when `useWebCanvas == true`.
2) Convert `chat.messages` → `[CanvasMessage]` on appear; call `loadTranscript`.
3) Streaming flow: call `startStream('current')` → `appendDelta` per token → `endStream` on completion; keep `scrollToBottom`.
4) Preserve error banner and suggestions.

## Feature Flag
- `AppSettings.useWebCanvas: Bool` (default true in Debug, false in Release until validated). Toggle in Settings → Interface.

## File Stubs (Minimal)

index.html
```
<!doctype html>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'self' 'unsafe-inline'; script-src 'self'; img-src 'self' data:; font-src 'self' data:; frame-src 'self' https://*.codesandbox.io; connect-src 'self';">
<link rel="stylesheet" href="./app.css">
<div id="app"></div>
<div id="artifacts"></div>
<script src="./app.bundle.js"></script>
```

app.bundle.js (structure)
```
// import markdownit, gfm plugins, shiki, katex, mermaid
class Renderer {
  constructor({ theme }) { /* init pipeline + themes */ }
  loadTranscript(items) { /* render all */ }
  startStream(id) { /* create pending block */ }
  appendDelta(id, delta) { /* tail reparse + commit */ }
  endStream(id) { /* finalize + transforms */ }
  setTheme(mode) { /* swap CSS + shiki */ }
  scrollToBottom() { /* stick to tail */ }
  artifact = { mount(cfg) { /* iframe or Sandpack */ } };
}
window.ChatCanvas = new (class {
  /* thin facade that delegates to a single Renderer instance */
})();
```

app.css (outline)
```
:root { --fg: #111; --bg: #fff; --muted: #6b7280; /* … */ }
.assistant { padding: 2px 0; }
.user { border-radius: 16px; background: rgba(0,0,0,.05); padding: 10px; }
table { border-collapse: collapse; font-size: 0.95em; }
pre code { /* shiki tokens */ }
.katex { /* spacing */ }
.mermaid { /* container */ }
```

## Validation
- Manual: send prompt and verify streaming smoothness, tables/mermaid/math/code.
- UI Test: wait for canvas `ready` and non‑empty content; screenshot.
- Performance: smoke test 200+ messages.

## Rollback
- Flip `useWebCanvas` off to return to `AIResponseView`.

