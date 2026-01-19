# Implementation Plan: Onboarding UI Fixes

**Branch**: `004-onboarding-ui-fixes` | **Date**: 2026-01-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-onboarding-ui-fixes/spec.md`

## Summary

Fix five UI issues in the CatPaws onboarding flow and menu bar:
1. Step 2 window height insufficient for content
2. Step 3 "Open System Settings" doesn't show CatPaws in Input Monitoring list
3. Step 4 text overflow/truncation
4. Step 4 test keys (ASDF) not realistic cat-paw pattern → change to S-E-D triangular cluster
5. Permission-required menu bar dropdown missing "Quit" option

## Technical Context

**Language/Version**: Swift 5.9+, Xcode 15+
**Primary Dependencies**: SwiftUI, AppKit (NSWindow, NSStatusItem)
**Storage**: UserDefaults (configuration/state persistence)
**Testing**: XCTest (unit tests), XCUITest (UI tests)
**Target Platform**: macOS 14+
**Project Type**: Single macOS menu bar application
**Performance Goals**: N/A (UI polish fixes)
**Constraints**: Must maintain existing window styling and brand consistency
**Scale/Scope**: 4 SwiftUI views, 1 AppDelegate configuration

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Design Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Apple Platform Best Practices | ✅ PASS | Using SwiftUI for UI, AppKit for window management |
| II. Privacy & Security First | ✅ PASS | No changes to data handling; fixes improve permission guidance |
| III. Test-Driven Development | ✅ PASS | Existing UI tests cover onboarding flow; will update tests |
| IV. User Experience & Accessibility | ✅ PASS | Fixes directly improve UX by making content visible |
| V. App Store Compliance | ✅ PASS | No new entitlements or APIs required |

**Pre-Design Gate Status**: PASSED

### Post-Design Check (Phase 1 Complete)

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Apple Platform Best Practices | ✅ PASS | SwiftUI layout changes follow HIG; window sizing uses standard AppKit |
| II. Privacy & Security First | ✅ PASS | No keystroke data exposed; Quit button improves user control |
| III. Test-Driven Development | ✅ PASS | Existing tests remain valid; new test key pattern testable |
| IV. User Experience & Accessibility | ✅ PASS | Content visibility improved; triangular key layout more intuitive |
| V. App Store Compliance | ✅ PASS | No new entitlements; existing sandbox preserved |

**Post-Design Gate Status**: PASSED - Design follows all constitutional principles.

## Project Structure

### Documentation (this feature)

```text
specs/004-onboarding-ui-fixes/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (minimal for UI fixes)
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (affected files)

```text
CatPaws/CatPaws/
├── App/
│   └── AppDelegate.swift           # Window size configuration (480x400 → 480x500)
├── Views/
│   ├── OnboardingView.swift        # Steps 2, 4 content and key pattern
│   ├── PermissionGuideView.swift   # Menu bar "Permission Required" view
│   └── MenuBarContentView.swift    # Menu bar content container
├── Services/
│   └── KeyboardMonitorService.swift # Event tap creation (verify Input Monitoring registration)
└── ViewModels/
    └── OnboardingViewModel.swift   # Onboarding state management

CatPaws/CatPawsUITests/
└── OnboardingTests/
    └── OnboardingUITests.swift     # UI tests for onboarding flow
```

**Structure Decision**: Single macOS app project. Changes are isolated to existing SwiftUI views and one AppDelegate configuration. No new files needed.

**Note**: FR-004 (Open System Settings to Input Monitoring pane) is already implemented correctly in `PermissionGuideView.openInputMonitoringSettings()`. No changes needed for this requirement.

## Complexity Tracking

> No Constitution violations to justify.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | N/A | N/A |
