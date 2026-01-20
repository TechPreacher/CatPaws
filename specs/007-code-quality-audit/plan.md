# Implementation Plan: Code Quality Audit

**Branch**: `007-code-quality-audit` | **Date**: 2026-01-20 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/007-code-quality-audit/spec.md`

## Summary

Comprehensive code quality audit of the CatPaws macOS application to identify and remove dead code, eliminate duplicates, apply Swift best practices, and improve test quality. The application is currently working correctly—all changes must be behavior-preserving refactoring only.

## Technical Context

**Language/Version**: Swift 5.9+, Xcode 15+  
**Primary Dependencies**: SwiftUI, AppKit (NSEvent, NSStatusItem), CoreGraphics, ServiceManagement, Carbon  
**Storage**: UserDefaults (configuration and statistics persistence)  
**Testing**: XCTest (unit, integration, UI tests)  
**Target Platform**: macOS 14+  
**Project Type**: Single macOS menu bar application  
**Performance Goals**: N/A (audit/refactoring task, not performance optimization)  
**Constraints**: Behavior-preserving changes only; all existing tests must pass  
**Scale/Scope**: ~40 Swift source files, ~15 test files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Check (2026-01-20)

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Apple Platform Best Practices | ✅ PASS | Audit enforces Swift API Design Guidelines |
| II. Privacy & Security First | ✅ PASS | No changes to permission handling or data flow |
| III. Test-Driven Development | ✅ PASS | Audit improves test quality, maintains coverage |
| IV. User Experience & Accessibility | ✅ PASS | No UI changes; behavior-preserving only |
| V. App Store Compliance | ✅ PASS | No entitlement or API changes |

**Gate Result**: PASS - Proceed to Phase 0

### Post-Design Check (2026-01-20)

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Apple Platform Best Practices | ✅ PASS | 13 findings improve Swift conventions; no new violations |
| II. Privacy & Security First | ✅ PASS | Audit removes unused code; no security impact |
| III. Test-Driven Development | ✅ PASS | 17 test quality findings; adds coverage, fixes invalid tests |
| IV. User Experience & Accessibility | ✅ PASS | Behavior-preserving refactoring; no UI changes |
| V. App Store Compliance | ✅ PASS | Code cleanup only; sandboxing/entitlements unchanged |

**Gate Result**: PASS - Proceed to Phase 2 (tasks)

## Project Structure

### Documentation (this feature)

```text
specs/007-code-quality-audit/
├── plan.md              # This file
├── research.md          # Phase 0: Audit findings and analysis
├── data-model.md        # Phase 1: Audit report structure
├── quickstart.md        # Phase 1: Remediation guide
├── contracts/           # Phase 1: N/A for this feature
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (existing structure - no changes)

```text
CatPaws/CatPaws/
├── App/                 # App entry point and delegates
│   ├── AppDelegate.swift
│   └── CatPawsApp.swift
├── Configuration/       # Entitlements and Info.plist
├── MenuBar/            # Menu bar UI components
│   ├── MenuBarContentView.swift
│   ├── MenuBarView.swift
│   └── StatusItemManager.swift
├── Models/             # Data models and state
│   ├── AppState.swift
│   ├── AppStatistics.swift
│   ├── Configuration.swift
│   ├── DetectionEvent.swift
│   ├── KeyboardState.swift
│   ├── LockState.swift
│   ├── OnboardingState.swift
│   ├── PermissionStatus.swift
│   └── PermissionType.swift
├── Services/           # Business logic services
│   ├── AppLogger.swift
│   ├── CatDetecting.swift
│   ├── CatDetectionService.swift
│   ├── ConfigurationProviding.swift
│   ├── KeyboardAdjacencyMap.swift
│   ├── KeyboardLayoutDetector.swift
│   ├── KeyboardLockService.swift
│   ├── KeyboardLocking.swift
│   ├── KeyboardMonitor.swift
│   ├── KeyboardMonitorDelegate.swift
│   ├── KeyboardMonitoring.swift
│   ├── LockStateManager.swift
│   ├── LockStateManaging.swift
│   ├── LoginItemService.swift
│   ├── NotificationPresenting.swift
│   ├── NotificationWindowController.swift
│   ├── PermissionError.swift
│   ├── PermissionService.swift
│   └── StatisticsService.swift
├── Utilities/          # Helper utilities
├── ViewModels/         # MVVM view models
│   ├── AppViewModel.swift
│   └── OnboardingViewModel.swift
└── Views/              # SwiftUI views
    ├── CatLockPopupView.swift
    ├── OnboardingView.swift
    ├── PermissionGuideView.swift
    ├── PopoverView.swift
    ├── SettingsView.swift
    └── StatisticsView.swift

CatPaws/CatPawsTests/
├── IntegrationTests/
├── Mocks/
├── ModelTests/
│   ├── AppStateTests.swift
│   ├── KeyboardStateTests.swift
│   ├── LockStateTests.swift
│   ├── OnboardingStateTests.swift
│   ├── PermissionStatusTests.swift
│   └── PermissionTypeTests.swift
├── ServiceTests/
│   ├── CatDetectionServiceTests.swift
│   ├── KeyboardLockServiceTests.swift
│   ├── LockStateManagerTests.swift
│   └── PermissionServiceTests.swift
└── ViewModelTests/

CatPaws/CatPawsUITests/
├── MenuBarTests/
└── OnboardingTests/
```

**Structure Decision**: Existing MVVM structure maintained. Audit focuses on quality improvements within current architecture, not restructuring.

## Complexity Tracking

No constitution violations requiring justification.

## Audit Scope

### Files to Analyze

| Category | Count | Location |
|----------|-------|----------|
| App Entry | 2 | `App/` |
| Menu Bar | 3 | `MenuBar/` |
| Models | 9 | `Models/` |
| Services | 19 | `Services/` |
| View Models | 2 | `ViewModels/` |
| Views | 6 | `Views/` |
| Unit Tests | 10 | `CatPawsTests/` |
| UI Tests | 2+ | `CatPawsUITests/` |
| **Total** | ~53 | |

### Audit Categories

1. **Dead Code Detection** (P1)
   - Unused types, functions, properties
   - Unreferenced protocol conformances
   - Preserve `@objc` marked code

2. **Duplicate Code Detection** (P2)
   - Similar logic patterns across files
   - Copy-pasted code blocks
   - Opportunities for shared utilities

3. **Swift Best Practices** (P2)
   - Naming conventions (Swift API Design Guidelines)
   - Force unwrap usage (require inline comments)
   - Access control (prefer private)
   - Optional handling patterns
   - Documentation on public interfaces

4. **Test Quality** (P3)
   - Trivial/meaningless tests
   - Missing test coverage
   - Duplicate test logic
   - Mock accuracy

## Phase Outputs

- **Phase 0**: `research.md` - Detailed audit findings
- **Phase 1**: `data-model.md` - Finding categorization structure
- **Phase 1**: `quickstart.md` - Remediation guide
