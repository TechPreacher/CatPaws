# Implementation Plan: Persistent Keyboard Lock

**Branch**: `006-persistent-keyboard-lock` | **Date**: 2026-01-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/006-persistent-keyboard-lock/spec.md`

## Summary

Modify the CatPaws keyboard lock behavior to persist until explicit user dismissal via mouse click or emergency keyboard shortcut (Cmd+Option+Escape held for 2 seconds), removing all timer-based and key-release auto-unlock logic. Additionally, auto-enable monitoring on app start and after onboarding completion.

## Technical Context

**Language/Version**: Swift 5.9+, Xcode 15+
**Primary Dependencies**: SwiftUI, AppKit (NSEvent for global keyboard monitoring), CoreGraphics (CGEvent)
**Storage**: UserDefaults (configuration persistence)
**Testing**: XCTest (unit and integration tests)
**Target Platform**: macOS 13+
**Project Type**: Single macOS menu bar application
**Performance Goals**: Instant lock response (<100ms from detection to lock)
**Constraints**: Must not interfere with mouse input; emergency shortcut must work even when keyboard is locked
**Scale/Scope**: Single-user desktop application

## Constitution Check

✅ All checks pass - existing project structure is maintained.

## Project Structure

### Documentation (this feature)

```text
specs/006-persistent-keyboard-lock/
├── plan.md              # This file
├── spec.md              # Feature specification
├── checklists/          # Quality checklists
│   └── requirements.md
└── tasks.md             # Task list (to be generated)
```

### Source Code (existing structure)

```text
CatPaws/CatPaws/
├── App/
│   ├── AppDelegate.swift          # MODIFY: Auto-enable after onboarding
│   └── CatPawsApp.swift
├── Models/
│   ├── LockState.swift            # MODIFY: Remove autoUnlock state transition
│   ├── Configuration.swift        # MODIFY: Track explicit user disable
│   └── OnboardingState.swift
├── Services/
│   ├── LockStateManager.swift     # MODIFY: Remove timer-based unlock, add emergency shortcut
│   ├── NotificationWindowController.swift  # MODIFY: Add emergency shortcut listener
│   └── KeyboardMonitor.swift
├── ViewModels/
│   ├── AppViewModel.swift         # MODIFY: Auto-enable on startup
│   └── OnboardingViewModel.swift  # MODIFY: Enable monitoring on complete
├── Views/
│   └── CatLockPopupView.swift     # MODIFY: Display emergency shortcut hint

CatPawsTests/
├── ServiceTests/
│   └── LockStateManagerTests.swift  # MODIFY: Update tests for new behavior
└── ViewModelTests/
    └── AppViewModelTests.swift      # MODIFY: Test auto-enable behavior
```

## Key Changes

### 1. LockStateManager.swift

- Remove `recheckTask` and `performRecheck()` method
- Remove `autoUnlock()` method
- Remove timer-based unlock logic from recheck
- Add emergency shortcut detection (Cmd+Option+Escape held for 2 seconds)
- Keep `manualUnlock()` for mouse dismiss and emergency shortcut dismiss

### 2. LockState.swift

- Remove `autoUnlock()` state transition method
- Keep only `manualUnlock()` for explicit user dismissal

### 3. CatLockPopupView.swift

- Add text displaying emergency keyboard shortcut: "Or hold ⌘⌥⎋ for 2 seconds"
- Position hint text below the dismiss button

### 4. NotificationWindowController.swift

- Add global event monitor for emergency shortcut detection while locked
- Track Cmd+Option+Escape key combination hold duration
- Trigger unlock when held for 2 seconds

### 5. AppViewModel.swift

- Auto-enable monitoring on startup if user hasn't explicitly disabled
- Check `Configuration.isEnabled` on init and start monitoring

### 6. Configuration.swift

- Add `hasUserExplicitlyDisabled` flag to distinguish between:
  - Never configured (should auto-enable)
  - User explicitly disabled (should respect)
  - User explicitly enabled (should auto-enable)

### 7. OnboardingViewModel.swift / AppDelegate.swift

- Enable monitoring when onboarding completes or is skipped
- Call `configuration.isEnabled = true` on completion

## Complexity Tracking

No constitution violations - all changes are within existing architecture.
