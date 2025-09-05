---
applyTo:
  - "**/*.swift"
---
Logging and diagnostics

- Use `Logger` (OSLog). No `print`.
- Use categories per layer: `Logger(subsystem: ..., category: "Networking")`, `"UI"`, `"DB"`.
- Add signposts for slow paths and measure with Instruments.
