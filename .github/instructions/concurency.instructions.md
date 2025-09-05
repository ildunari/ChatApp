---
applyTo:
  - "**/*.swift"
---
Swift concurrency guardrails

- Prefer `async/await`; mark UI-touching logic **@MainActor**.
- Use **actors** for shared mutable state; avoid `nonisolated` unless justified.
- Convert completion handlers with continuations sparingly; prefer native async APIs.
- Never block the main actor with long tasks; hop to background when needed.
