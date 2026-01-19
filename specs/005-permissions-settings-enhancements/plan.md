# Implementation Plan: Permissions & Settings Enhancements

**Branch**: `005-permissions-settings-enhancements` | **Date**: 2026-01-19 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/005-permissions-settings-enhancements/spec.md`

## Summary

Add Accessibility permission step to onboarding (after permission explanation, before Input Monitoring), display individual permission status in menu bar dropdown, fix UI sizing issues for menu bar and settings window, and provide a "Reset All Settings" option. Permission status polling at 1-second intervals enables real-time UI updates without app restart. Non-modal notification banner alerts users when permissions are revoked during runtime.

## Technical Context

**Language/Version**: Swift 5.9+, Xcode 15+
**Primary Dependencies**: SwiftUI, AppKit, CoreGraphics (CGPreflightListenEventAccess, AXIsProcessTrusted)
**Storage**: UserDefaults (preferences and onboarding state)
**Testing**: XCTest (unit tests for permission checking, view model logic, state management)
**Target Platform**: macOS 14+
**Project Type**: Single macOS menu bar application
**Performance Goals**: Permission status updates within 2 seconds of grant; UI responsive at 60fps
**Constraints**: Sandbox-compliant; only pattern metadata stored; no keystroke logging
**Scale/Scope**: Single-user desktop app; ~15 views; ~20 service/model files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Apple Platform Best Practices | PASS | SwiftUI for UI; AppKit for system integration; targets macOS 14+; Timer-based polling for permission status |
| II. Privacy & Security First | PASS | Only permission status checked (boolean); no keystroke data; clear user explanations for both permissions |
| III. Test-Driven Development | PASS | Unit tests planned for permission checking, view model logic, reset functionality |
| IV. User Experience & Accessibility | PASS | Clear permission status display; tooltips for truncated text; VoiceOver support maintained |
| V. App Store Compliance | PASS | Existing entitlements sufficient (input-monitoring); Accessibility check uses public AXIsProcessTrusted API |

**Gate Result**: ✅ PASS - All principles satisfied

## Project Structure

### Documentation (this feature)

```text
specs/005-permissions-settings-enhancements/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (API contracts)
└── tasks.md             # Phase 2 output (NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
CatPaws/CatPaws/
├── Models/
│   ├── OnboardingState.swift      # MODIFY: Add AccessibilityPermission step enum
│   └── Configuration.swift        # MODIFY: Add resetAll() method
├── ViewModels/
│   ├── OnboardingViewModel.swift  # MODIFY: Add Accessibility permission polling
│   └── AppViewModel.swift         # MODIFY: Add dual permission status tracking
├── Views/
│   ├── OnboardingView.swift       # MODIFY: Add Accessibility permission step UI
│   ├── PermissionGuideView.swift  # MODIFY: Dual permission status display
│   └── SettingsView.swift         # MODIFY: Add reset button, fix sizing
├── MenuBar/
│   └── MenuBarContentView.swift   # MODIFY: Adjust dropdown height
└── Services/
    └── PermissionService.swift    # NEW: Unified permission checking service

CatPawsTests/
├── ViewModelTests/
│   └── OnboardingViewModelTests.swift  # MODIFY: Add Accessibility permission tests
├── ServiceTests/
│   └── PermissionServiceTests.swift    # NEW: Permission checking tests
└── ModelTests/
    └── ConfigurationTests.swift        # MODIFY: Add reset functionality tests
```

**Structure Decision**: Follows existing single-project structure. New `PermissionService` consolidates permission checking logic currently spread across view models. No new directories needed.

## Constitution Check (Post-Design)

*Re-evaluated after Phase 1 design completion.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Apple Platform Best Practices | ✅ PASS | SwiftUI for all new UI; `AXIsProcessTrusted()` is public API; macOS 14+ target maintained |
| II. Privacy & Security First | ✅ PASS | Only boolean permission status read; no keystroke data; clear explanations in onboarding steps |
| III. Test-Driven Development | ✅ PASS | Tests planned for PermissionService, Configuration.resetAll(), OnboardingViewModel changes |
| IV. User Experience & Accessibility | ✅ PASS | Distinct permission status display; `.help()` tooltips for truncated text; VoiceOver support |
| V. App Store Compliance | ✅ PASS | No new entitlements required; `AXIsProcessTrusted()` is App Store compliant |

**Post-Design Gate Result**: ✅ PASS - All principles satisfied. No violations to justify.

## Complexity Tracking

> No violations requiring justification. Feature uses existing patterns and adds minimal new complexity.
