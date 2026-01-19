<!--
  SYNC IMPACT REPORT
  ====================
  Version change: 1.0.0 → 1.0.1 (Terminology correction)

  Modified principles:
  - II. Privacy & Security First: "Accessibility API" → "Input Monitoring permission"

  Modified sections:
  - "Accessibility API Requirements" → "Input Monitoring Requirements" (renamed for accuracy)
  - Updated permission path from "Privacy & Security > Accessibility" to
    "Privacy & Security > Input Monitoring"

  Added sections: None

  Removed sections: None

  Templates requiring updates:
  - .specify/templates/plan-template.md: ✅ Compatible (no changes needed)
  - .specify/templates/spec-template.md: ✅ Compatible (no changes needed)
  - .specify/templates/tasks-template.md: ✅ Compatible (no changes needed)
  - .specify/templates/agent-file-template.md: ✅ Compatible (no changes needed)
  - .specify/templates/checklist-template.md: ✅ Compatible (no changes needed)

  Follow-up TODOs: None

  Rationale: The application uses Input Monitoring permission
  (com.apple.security.device.input-monitoring), not Accessibility API permission.
  This correction aligns the constitution with the actual implementation and
  macOS terminology.
-->

# CatPaws Constitution

## Core Principles

### I. Apple Platform Best Practices

All code MUST follow Apple's official guidelines and Human Interface Guidelines (HIG).
The application MUST use SwiftUI for UI components where feasible, falling back to AppKit
only when SwiftUI lacks required functionality (e.g., low-level event monitoring).
Code MUST target macOS 14+ and use modern Swift concurrency (async/await, actors) for
all asynchronous operations. Memory management MUST rely on ARC without manual retain
cycles. All deprecated APIs MUST be avoided.

### II. Privacy & Security First

The application MUST request only the minimum permissions required (Input Monitoring
permission for keyboard monitoring). All permission requests MUST include clear,
user-facing explanations of why they are needed. The application MUST NOT log, store,
or transmit any keystroke data—only pattern metadata (timing, key count) for detection
purposes. The application MUST handle permission denial gracefully with clear user
guidance. All data storage (configuration only) MUST use secure macOS APIs (UserDefaults,
Keychain where appropriate).

### III. Test-Driven Development

Comprehensive tests are MANDATORY for this project. Unit tests MUST cover all detection
algorithms, timing logic, and state machine transitions. UI tests MUST verify menu bar
interactions and settings persistence. Integration tests MUST validate the complete
detection-to-blocking flow using simulated input events. Tests MUST be written using
XCTest framework. All tests MUST pass before any merge to main branch. Code coverage
for core detection logic MUST exceed 80%.

### IV. User Experience & Accessibility

The menu bar interface MUST clearly communicate app state through distinct icons:
- Paw icon (outlined): App active, keyboard unlocked
- Paw icon (filled/highlighted): App active, keyboard locked (cat detected)
- Paw icon (grayed/crossed): App inactive/disabled

State transitions MUST provide optional audio/visual feedback. The settings UI MUST be
accessible via VoiceOver. Configuration options MUST have sensible defaults that work
for most users without adjustment. The unlock timeout MUST be configurable with a
reasonable default (3-5 seconds recommended).

### V. App Store Compliance

The application MUST meet all Mac App Store review guidelines. The application MUST be
sandboxed with only necessary entitlements (com.apple.security.device.input-monitoring).
The application MUST NOT use private APIs. All third-party dependencies MUST be
App Store compliant. The application MUST include proper privacy policy and usage
descriptions. Version numbering MUST follow semantic versioning (MAJOR.MINOR.PATCH)
for App Store releases.

## App Store & Platform Compliance

### Required Entitlements

- `com.apple.security.app-sandbox`: Required for App Store distribution
- `com.apple.security.device.input-monitoring`: Required for keyboard event monitoring

### Input Monitoring Requirements

The application MUST guide users through enabling Input Monitoring permission in
System Settings > Privacy & Security > Input Monitoring. The application MUST detect
when permissions are revoked and respond appropriately. The application MUST NOT
attempt to circumvent macOS security measures.

### Distribution Requirements

- Signed with valid Apple Developer ID
- Notarized for distribution outside App Store (if applicable)
- Provisioned correctly for Mac App Store submission
- Privacy manifest included as required by Apple

## Development Workflow

### Code Quality Gates

1. All code MUST compile without warnings (treat warnings as errors)
2. All tests MUST pass before PR approval
3. SwiftLint MUST report zero violations
4. Code MUST be reviewed by at least one other contributor (if team > 1)

### Branching Strategy

- `main`: Production-ready, App Store release candidates
- `develop`: Integration branch for features
- `feature/*`: Individual feature branches
- `fix/*`: Bug fix branches

### Commit Standards

Commits MUST follow conventional commit format:
- `feat:` New feature
- `fix:` Bug fix
- `test:` Test additions/changes
- `docs:` Documentation
- `refactor:` Code refactoring
- `chore:` Build/tooling changes

## Governance

This constitution defines the non-negotiable principles for CatPaws development. All
pull requests and code reviews MUST verify compliance with these principles. Violations
require explicit justification and team consensus before merging.

### Amendment Process

1. Propose amendment via pull request to this document
2. Document rationale for change
3. Update version number according to semantic versioning:
   - MAJOR: Removing or fundamentally changing a principle
   - MINOR: Adding new principles or significant guidance
   - PATCH: Clarifications and typo fixes
4. Update LAST_AMENDED_DATE to current date

### Compliance Review

Before each App Store submission, verify:
- All principles are followed in the codebase
- Test coverage meets requirements
- Privacy and security requirements are satisfied
- App Store guidelines are met

**Version**: 1.0.1 | **Ratified**: 2026-01-15 | **Last Amended**: 2026-01-17
