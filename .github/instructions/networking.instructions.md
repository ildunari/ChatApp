---
applyTo:
  - "Networking/**"
  - "**/*API*.swift"
  - "**/*Client*.swift"
---
Networking ground rules

Transport & parsing:
- Use `URLSession` with **async/await**; parse via `Codable`.
- Configure decoders explicitly (e.g., `.dateDecodingStrategy = .iso8601`).

Errors:
- Map HTTP status → typed errors (`Unauthorized`, `NotFound`, `RateLimited`, `ServerError`).
- Bubble errors with `throws`; avoid `try?` unless intentionally lossy.

Security:
- **Do not** relax **ATS** unless explicitly requested. If requested, propose the **minimal** Info.plist exception and explain why.

Observability:
- Log request/response summaries via `Logger("Networking")` (no PII); add signposts for long calls.

Resilience (only if asked):
- Backoff (exponential/jitter) and idempotent retries for 5xx/timeout; never retry unsafe methods by default.

Template:
```swift
struct APIError: Error { let code: Int; let message: String }

func fetch<T: Decodable>(_ req: URLRequest) async throws -> T {
  let (data, resp) = try await URLSession.shared.data(for: req)
  guard let http = resp as? HTTPURLResponse else { throw APIError(code: -1, message: "No HTTP") }
  switch http.statusCode {
    case 200..<300: return try JSONDecoder.iso.decode(T.self, from: data)
    case 401: throw APIError(code: 401, message: "Unauthorized")
    case 404: throw APIError(code: 404, message: "Not found")
    case 429: throw APIError(code: 429, message: "Rate limited")
    default: throw APIError(code: http.statusCode, message: "Server error")
  }
}
