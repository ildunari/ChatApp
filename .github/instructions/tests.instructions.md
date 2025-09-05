---
applyTo:
  - "Tests/**"
  - "**/*Tests.swift"
---
Testing policy

Defaults:
- Prefer **Swift Testing**; if unavailable, use XCTest.
- Tests are hermetic: no network, no global state, no reliance on wall-clock.

Structure:
- One SUT per test file; arrange **Given/When/Then**.
- Use **fakes** (lightweight structs) over heavy mocks.
- Include at least one error-path test.

Swift Testing example:
```swift
import Testing
@testable import App

@Test("Login success and error cases")
func login_flow() async throws {
  let api = FakeAuthAPI(success: true)
  let vm = LoginVM(api: api)
  try await vm.login(user: "a", pass: "b")
  #expect(vm.isLoggedIn)

  let api2 = FakeAuthAPI(success: false)
  let vm2 = LoginVM(api: api2)
  await #expect(throws: AuthError.invalid) {
    try await vm2.login(user: "a", pass: "bad")
  }
}