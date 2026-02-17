# Contributing

## Golden rules
- Do NOT edit *.xcodeproj/project.pbxproj by hand or with AI tools.
  - Add/remove files and targets ONLY via Xcode UI.
- Prefer SwiftPM targets for shared logic and non-UI components.

## Definition of Done (DoD)
- TrackpadCore changes: add/update tests, `swift test` passes.
- App changes: build + launch confirmed (simulator or device).
- PR includes: what/why/how-to-test + risks.
