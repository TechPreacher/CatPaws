# Implementation Plan: Cat Detection Sensitivity Improvements

**Branch**: `008-cat-detection-sensitivity` | **Date**: 2026-01-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/008-cat-detection-sensitivity/spec.md`

## Summary

Improve cat paw detection by implementing a rolling time window (default 300ms) that aggregates rapid sequential key presses for pattern analysis, addressing cases where cat paws don't hit all keys simultaneously. Additionally, replace the Cmd+Option+Escape emergency unlock with a simpler 5-consecutive-ESC-press mechanism.

## Technical Context

**Language/Version**: Swift 5.9+  
**Primary Dependencies**: SwiftUI, AppKit (NSEvent for local monitoring), Combine  
**Storage**: UserDefaults (configuration only)  
**Testing**: XCTest  
**Target Platform**: macOS 14+  
**Project Type**: Single macOS app  
**Performance Goals**: <10ms detection latency, no perceptible UI delay  
**Constraints**: Must not impact normal typing performance, memory-efficient key event history  
**Scale/Scope**: Single-user desktop app, ~15 source files modified

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Apple Platform Best Practices | ✅ PASS | SwiftUI for UI, AppKit only for event monitoring |
| II. Privacy & Security First | ✅ PASS | No keystroke data stored/transmitted, only timing metadata |
| III. Test-Driven Development | ✅ PASS | Unit tests for time window logic, ESC counting |
| IV. User Experience & Accessibility | ✅ PASS | Clear popup instructions, simple unlock method |
| V. App Store Compliance | ✅ PASS | No new entitlements required, existing sandbox |

**Gate Status**: PASS - All principles satisfied

## Project Structure

### Documentation (this feature)

```text
specs/008-cat-detection-sensitivity/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (internal protocols)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
CatPaws/CatPaws/
├── Models/
│   ├── KeyboardState.swift          # MODIFY: Add rolling window tracking
│   └── Configuration.swift          # MODIFY: Add detectionTimeWindowMs setting
├── Services/
│   ├── CatDetectionService.swift    # MODIFY: Accept time-windowed key set
│   ├── ConfigurationProviding.swift # MODIFY: Add detectionTimeWindowMs property
│   └── NotificationWindowController.swift  # MODIFY: Replace emergency shortcut logic
├── Views/
│   └── CatLockPopupView.swift       # MODIFY: Update unlock instructions text
└── ViewModels/
    └── AppViewModel.swift           # MODIFY: Manage rolling window state

CatPawsTests/
├── ModelTests/
│   └── KeyboardStateTests.swift     # ADD: Rolling window tests
└── ServiceTests/
    ├── CatDetectionServiceTests.swift    # ADD: Time-windowed detection tests
    └── NotificationWindowControllerTests.swift  # ADD: ESC counting tests
```

**Structure Decision**: Existing single macOS app structure. Modifications to existing files plus new test cases.
