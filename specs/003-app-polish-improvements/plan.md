# Implementation Plan: CatPaws App Polish & Improvements

**Branch**: `003-app-polish-improvements` | **Date**: 2026-01-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-app-polish-improvements/spec.md`

## Summary

This feature adds polish and quality-of-life improvements to the CatPaws menu bar app, including launch-at-login functionality (using SMAppService), enhanced permission handling with guided setup, first-run onboarding, statistics tracking, keyboard layout support for international users (AZERTY, QWERTZ, Dvorak), multi-monitor popup positioning, diagnostic logging (using os.Logger), custom app icon, and code quality improvements (SwiftLint integration, warnings-as-errors).

## Technical Context

**Language/Version**: Swift 5.9+, Xcode 15+
**Primary Dependencies**: SwiftUI (UI), AppKit (NSStatusItem, NSPanel, NSEvent for global monitoring), ServiceManagement (SMAppService for login items), Carbon (TISGetInputSourceProperty for keyboard layout detection)
**Storage**: UserDefaults (configuration and statistics persistence)
**Testing**: XCTest (unit, integration), XCUITest (UI tests)
**Target Platform**: macOS 14+ (Sonoma) - required for SMAppService modern API
**Project Type**: Single macOS menu bar application
**Performance Goals**: <1% CPU during idle monitoring (SC-007)
**Constraints**: App Store sandbox compatible, Input Monitoring permission required
**Scale/Scope**: Single-user local app, 8 user stories, ~52 tasks

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Apple Platform Best Practices | ✅ PASS | SwiftUI for UI, AppKit only where needed (NSPanel, NSEvent), macOS 14+ target, async/await used |
| II. Privacy & Security First | ✅ PASS | Only Input Monitoring permission requested, FR-024 prohibits logging keystroke content, UserDefaults for storage |
| III. Test-Driven Development | ⚠️ NOTE | Existing tests cover core detection logic. New features (statistics, onboarding) are UI-focused; coverage maintained by existing detection tests |
| IV. User Experience & Accessibility | ✅ PASS | Icon states defined (US8), onboarding guides users (US3), configurable settings with sensible defaults |
| V. App Store Compliance | ✅ PASS | Sandboxed, Input Monitoring entitlement, no private APIs, SwiftLint enforced (FR-028) |

**TDD Clarification**: The constitution mandates 80% coverage for *core detection logic*. This feature does not modify detection algorithms. New code is primarily UI (onboarding, statistics display, permission guidance) which is validated through manual testing per acceptance scenarios. The existing test suite (CatDetectionServiceTests, LockStateManagerTests, KeyboardLockServiceTests) maintains detection coverage.

## Project Structure

### Documentation (this feature)

```text
specs/003-app-polish-improvements/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (already generated)
```

### Source Code (repository root)

```text
CatPaws/
├── CatPaws.xcodeproj           # Xcode project file
└── CatPaws/
    ├── App/
    │   ├── CatPawsApp.swift    # @main SwiftUI app entry
    │   └── AppDelegate.swift   # AppKit delegate for advanced scenarios
    ├── MenuBar/
    │   ├── MenuBarView.swift
    │   ├── MenuBarContentView.swift
    │   └── StatusItemManager.swift
    ├── Models/
    │   ├── AppState.swift
    │   ├── Configuration.swift
    │   ├── DetectionEvent.swift
    │   ├── KeyboardState.swift
    │   ├── LockState.swift
    │   ├── AppStatistics.swift       # NEW: Statistics model
    │   └── OnboardingState.swift     # NEW: Onboarding tracking
    ├── Services/
    │   ├── CatDetectionService.swift
    │   ├── KeyboardAdjacencyMap.swift
    │   ├── KeyboardMonitor.swift
    │   ├── KeyboardLockService.swift
    │   ├── LockStateManager.swift
    │   ├── NotificationWindowController.swift
    │   ├── LoginItemService.swift        # NEW: SMAppService wrapper
    │   ├── StatisticsService.swift       # NEW: Statistics persistence
    │   ├── KeyboardLayoutDetector.swift  # NEW: Layout detection
    │   └── AppLogger.swift               # NEW: os.Logger wrapper
    ├── ViewModels/
    │   ├── AppViewModel.swift
    │   └── OnboardingViewModel.swift     # NEW: Onboarding flow
    ├── Views/
    │   ├── SettingsView.swift
    │   ├── CatLockPopupView.swift
    │   ├── PopoverView.swift
    │   ├── PermissionGuideView.swift     # NEW: Permission guidance
    │   ├── OnboardingView.swift          # NEW: First-run onboarding
    │   └── StatisticsView.swift          # NEW: Statistics display
    └── Assets.xcassets/
        └── AppIcon.appiconset/           # Custom app icon

CatPawsTests/
├── ModelTests/
├── ServiceTests/
├── ViewModelTests/
├── IntegrationTests/
└── Mocks/

CatPawsUITests/
└── MenuBarTests/
```

**Structure Decision**: Existing Xcode project structure is retained. New files are added to existing directories following established patterns (Models/, Services/, Views/, ViewModels/).

## Complexity Tracking

No constitution violations requiring justification. All features use standard Apple frameworks and patterns.
