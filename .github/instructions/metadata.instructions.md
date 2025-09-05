---
applyTo:
  - "**/Info.plist"
  - "**/*.entitlements"
  - "**/*.xcprivacy"
---
Metadata and capabilities

Info.plist:
- Justify each new key; **avoid** blanket `NSAllowsArbitraryLoads`. Use targeted **ATS** exceptions only when required.

Entitlements:
- Prefer adding via **Signing & Capabilities**. If editing the file, use valid keys only (iCloud, Push, BGTasks, etc).

Privacy:
- If code touches **Required-Reason APIs**, update `PrivacyInfo.xcprivacy` with the correct reason strings and scope.

Example minimal ATS exception (only if required):
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSExceptionDomains</key>
  <dict>
    <key>example.com</key>
    <dict>
      <key>NSIncludesSubdomains</key><true/>
      <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key><true/>
    </dict>
  </dict>
</dict>