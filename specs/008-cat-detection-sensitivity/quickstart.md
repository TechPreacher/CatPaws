# Quickstart: Cat Detection Sensitivity Improvements

**Feature**: 008-cat-detection-sensitivity  
**Date**: 2026-01-21

## Overview

This feature improves cat paw detection by capturing rapid sequential key presses (within 300ms) and replaces the complex Cmd+Option+Escape unlock with pressing ESC 5 times.

## Prerequisites

- macOS 14+
- Xcode 15+
- Existing CatPaws codebase on main branch

## Quick Implementation Checklist

### 1. Configuration (5 min)

**File**: `CatPaws/CatPaws/Models/Configuration.swift`

Add `detectionTimeWindowMs` property following existing pattern:
- Key: `catpaws.detectionTimeWindowMs`
- Default: 300
- Range: 100-500

**File**: `CatPaws/CatPaws/Services/ConfigurationProviding.swift`

Add protocol requirement:
```swift
var detectionTimeWindowMs: Int { get set }
```

### 2. KeyboardState Extension (10 min)

**File**: `CatPaws/CatPaws/Models/KeyboardState.swift`

1. Add `TimestampedKeyEvent` struct
2. Add `recentKeyPresses: [TimestampedKeyEvent]` property
3. Add `timeWindowSeconds: TimeInterval` property
4. Add `keysForDetection` computed property
5. Modify `keyPressed(_:at:)` to prune old entries and add new events
6. Update `clearAll()` to clear recentKeyPresses

### 3. AppViewModel Update (5 min)

**File**: `CatPaws/CatPaws/ViewModels/AppViewModel.swift`

1. Initialize KeyboardState with time window from Configuration
2. Pass timestamp in `keyDidPress` delegate method
3. Use `keysForDetection` instead of `nonModifierKeys` in `analyzeCurrentKeys()`

### 4. ESC Unlock Implementation (15 min)

**File**: `CatPaws/CatPaws/Services/NotificationWindowController.swift`

1. Remove `emergencyShortcutTask` and `emergencyHoldDuration` properties
2. Add `escPressCount`, `lastEscPressTime` properties
3. Replace `handleEmergencyShortcutEvent(_:)` with ESC counting logic
4. Remove `startEmergencyShortcutTimer()` and `cancelEmergencyShortcutTimer()`

### 5. Popup Text Update (2 min)

**File**: `CatPaws/CatPaws/Views/CatLockPopupView.swift`

Change emergency shortcut text:
```swift
// OLD
Text("Or hold ⌘⌥⎋ for 2 seconds")

// NEW
Text("Or press ESC 5 times to unlock")
```

Update accessibility label accordingly.

## Testing Checklist

### Unit Tests

- [ ] KeyboardState: Time window pruning works correctly
- [ ] KeyboardState: keysForDetection returns correct union
- [ ] Configuration: detectionTimeWindowMs validates range
- [ ] ESC counting: Counter increments on ESC press
- [ ] ESC counting: Counter resets on timeout
- [ ] ESC counting: Counter resets on non-ESC key

### Integration Tests

- [ ] Rapid sequential key presses trigger detection
- [ ] Normal typing speed does NOT trigger detection
- [ ] Simultaneous key press still triggers (existing behavior)
- [ ] 5 ESC presses unlock the keyboard
- [ ] Mouse click still dismisses popup

## Build & Test Commands

```bash
# Build
cd CatPaws
xcodebuild -scheme CatPaws -configuration Debug build

# Run tests
xcodebuild -scheme CatPaws -configuration Debug test

# Run SwiftLint
swiftlint
```

## Key Implementation Notes

1. **Time window pruning**: Do it on each key press, not with a timer
2. **ESC key code**: 53 (same as existing code)
3. **Union for detection**: `pressedKeys.union(keysInTimeWindow)` preserves both patterns
4. **No CatDetectionService changes**: It receives a Set<UInt16>, source doesn't matter

## Files Changed Summary

| File | Change Type |
|------|-------------|
| Configuration.swift | Add property |
| ConfigurationProviding.swift | Add protocol requirement |
| KeyboardState.swift | Major extension |
| AppViewModel.swift | Minor modification |
| NotificationWindowController.swift | Replace unlock logic |
| CatLockPopupView.swift | Text change |
