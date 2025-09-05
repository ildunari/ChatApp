---
applyTo:
  - "Config/**"
  - "**/*.xcconfig"
---
Config guidance

- Keep **env/build flags** in `.xcconfig`; surface to `Info.plist` with `$(VAR)`.
- Never store secrets; assume CI injects env vars.
- Prefer `.xcconfig` or Xcode UI steps over raw `project.pbxproj` edits.

Example:
// Config/Debug.xcconfig
API_BASE_URL = https://api.example.com

// Info.plist entry
<key>API_BASE_URL</key>
<string>$(API_BASE_URL)</string>