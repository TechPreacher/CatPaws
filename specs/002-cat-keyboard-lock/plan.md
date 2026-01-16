# Implementation Plan: Cat Keyboard Lock

**Branch**: `002-cat-keyboard-lock` | **Date**: 2026-01-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-cat-keyboard-lock/spec.md`

## Summary

Implement cat detection and keyboard locking functionality for the CatPaws menu bar application. The system monitors keyboard input at the system level using macOS Accessibility APIs, detects cat-like patterns (3+ adjacent non-modifier keys pressed simultaneously, or 10+ keys for sitting/lying detection), and blocks keyboard input when a cat is detected. A popup notification with a dismiss button provides user feedback, and automatic unlock occurs when the cat leaves (no keys pressed).

## Technical Context

**Language/Version**: Swift 5.9+, Xcode 15+
**Primary Dependencies**: SwiftUI, AppKit, Accessibility APIs (CGEvent for global keyboard monitoring and input blocking)
**Storage**: UserDefaults (configuration only - debounce timing, cooldown duration)
**Testing**: XCTest (unit tests for detection logic, integration tests for state machine)
**Target Platform**: macOS 14+
**Project Type**: Single macOS menu bar application
**Performance Goals**: <100ms detection-to-lock latency, <500ms popup display
**Constraints**: Must not log/store keystrokes (privacy), only pattern metadata; requires Accessibility permissions
**Scale/Scope**: Single-user desktop application

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence/Notes |
|-----------|--------|----------------|
| I. Apple Platform Best Practices | PASS | SwiftUI for popup UI, AppKit/CGEvent for low-level monitoring; macOS 14+; async/await for timers |
| II. Privacy & Security First | PASS | Only pattern metadata (key count, timing) stored; no keystroke logging; Accessibility permission required with clear explanation |
| III. Test-Driven Development | PASS | Unit tests for detection algorithms, timing logic, state machine; integration tests for detection-to-lock flow |
| IV. User Experience & Accessibility | PASS | Menu bar icons per spec (outlined/filled/grayed paw); popup with dismiss button; VoiceOver support |
| V. App Store Compliance | PASS | Sandboxed with `com.apple.security.device.input-monitoring` entitlement; no private APIs |

**Gate Result**: PASS - All principles satisfied, no violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/002-cat-keyboard-lock/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (internal protocols)
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
CatPaws/CatPaws/
├── App/
│   ├── AppDelegate.swift
│   └── CatPawsApp.swift
├── MenuBar/
│   ├── MenuBarContentView.swift
│   ├── MenuBarView.swift
│   └── StatusItemManager.swift
├── Models/
│   ├── AppState.swift
│   ├── KeyboardState.swift          # NEW: Key press tracking
│   ├── DetectionEvent.swift         # NEW: Cat pattern detection
│   └── LockState.swift              # NEW: Lock/cooldown state
├── Services/
│   ├── KeyboardMonitor.swift        # NEW: Global keyboard event monitoring
│   ├── CatDetectionService.swift    # NEW: Pattern detection algorithm
│   └── KeyboardLockService.swift    # NEW: Input blocking logic
├── ViewModels/
│   └── AppViewModel.swift           # MODIFY: Add lock state management
└── Views/
    ├── PopoverView.swift
    ├── SettingsView.swift
    └── CatLockPopupView.swift       # NEW: Lock notification popup

CatPaws/CatPawsTests/
├── ModelTests/
│   ├── AppStateTests.swift
│   ├── KeyboardStateTests.swift     # NEW
│   └── LockStateTests.swift         # NEW
├── ServiceTests/
│   ├── CatDetectionServiceTests.swift  # NEW: Detection algorithm tests
│   └── KeyboardMonitorTests.swift      # NEW: Event handling tests
└── ViewModelTests/
    └── AppViewModelTests.swift

CatPaws/CatPawsUITests/
└── MenuBarTests/
    └── MenuBarUITests.swift
```

**Structure Decision**: Extending existing single-project structure with new Models, Services, and Views for keyboard monitoring and cat detection functionality. Follows established MVVM pattern in the codebase.

## Complexity Tracking

> No violations requiring justification - Constitution Check passed.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | N/A | N/A |
