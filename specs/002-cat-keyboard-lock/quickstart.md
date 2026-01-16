# Quickstart: Cat Keyboard Lock

**Feature**: 002-cat-keyboard-lock
**Date**: 2026-01-16

## Prerequisites

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- Existing CatPaws project (from 001-swift-project-structure)

## Project Setup

### 1. Required Entitlements

Add to `CatPaws.entitlements`:

```xml
<key>com.apple.security.device.input-monitoring</key>
<true/>
```

### 2. Info.plist Entries

Add privacy description for Input Monitoring:

```xml
<key>NSInputMonitoringUsageDescription</key>
<string>CatPaws needs to monitor keyboard input to detect when your cat is on the keyboard and protect your work from unwanted keystrokes.</string>
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                      CatPawsApp                         │
│                    (SwiftUI Entry)                      │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                    AppViewModel                         │
│            (Orchestrates all services)                  │
│  - Coordinates detection → lock → notification flow    │
│  - Manages app-wide state                              │
└────────────────────────┬────────────────────────────────┘
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ KeyboardMonitor │ │ LockStateManager│ │ NotificationMgr │
│ (CGEvent tap)   │ │ (State machine) │ │ (Popup window)  │
└────────┬────────┘ └────────┬────────┘ └─────────────────┘
         │                   │
         ▼                   ▼
┌─────────────────┐ ┌─────────────────┐
│ CatDetection    │ │ KeyboardLock    │
│ (Pattern algo)  │ │ (Block input)   │
└─────────────────┘ └─────────────────┘
```

## Key Files to Create

### Models (CatPaws/Models/)

| File | Purpose |
|------|---------|
| `KeyboardState.swift` | Tracks currently pressed keys |
| `DetectionEvent.swift` | Represents detected cat patterns |
| `LockState.swift` | Lock state machine model |

### Services (CatPaws/Services/)

| File | Purpose |
|------|---------|
| `KeyboardMonitor.swift` | CGEvent tap for global keyboard monitoring |
| `CatDetectionService.swift` | Pattern detection algorithm |
| `KeyboardLockService.swift` | Input blocking when locked |
| `KeyboardAdjacencyMap.swift` | QWERTY key adjacency data |

### Views (CatPaws/Views/)

| File | Purpose |
|------|---------|
| `CatLockPopupView.swift` | Lock notification popup with dismiss button |

### Tests

| File | Purpose |
|------|---------|
| `KeyboardStateTests.swift` | Key state tracking tests |
| `LockStateTests.swift` | State machine transition tests |
| `CatDetectionServiceTests.swift` | Detection algorithm tests |
| `KeyboardMonitorTests.swift` | Event handling tests |

## Implementation Order

### Phase 1: Core Models
1. `KeyboardState.swift` - Key tracking data structure
2. `DetectionEvent.swift` - Detection event model
3. `LockState.swift` - State machine model with transitions

### Phase 2: Detection Logic
4. `KeyboardAdjacencyMap.swift` - Static adjacency data
5. `CatDetectionService.swift` - Pattern detection algorithm
6. Unit tests for detection logic

### Phase 3: Keyboard Monitoring
7. `KeyboardMonitor.swift` - CGEvent tap implementation
8. Permission handling flow
9. Integration with detection service

### Phase 4: Lock & Notification
10. `KeyboardLockService.swift` - Input blocking
11. `CatLockPopupView.swift` - Popup UI
12. State machine integration

### Phase 5: Integration
13. Update `AppViewModel.swift` - Wire everything together
14. Update `MenuBarContentView.swift` - Status icons and menu
15. Integration tests
16. UI tests

## Quick Test Commands

```bash
# Run all tests
xcodebuild test -scheme CatPaws -destination 'platform=macOS'

# Run specific test file
xcodebuild test -scheme CatPaws -destination 'platform=macOS' \
  -only-testing:CatPawsTests/CatDetectionServiceTests

# Reset Input Monitoring permission (for testing)
tccutil reset All com.yourteam.CatPaws
```

## Debug Tips

### Check Permission Status
```swift
print("Has permission: \(CGPreflightListenEventAccess())")
```

### Log Key Events
```swift
// In KeyboardMonitor callback
print("Key \(keyCode) \(type == .keyDown ? "down" : "up")")
```

### Simulate Cat Paw (for testing)
Press and hold: A, S, D, F simultaneously (4 adjacent keys)

## Configuration Defaults

| Setting | Default | Range |
|---------|---------|-------|
| Debounce | 300ms | 200-500ms |
| Re-check interval | 2 sec | 1-5 sec |
| Cooldown | 7 sec | 5-10 sec |
| Minimum keys | 3 | 3-5 |

## Common Issues

### Event Tap Not Working
1. Check Input Monitoring permission in System Settings
2. Restart app after granting permission
3. Verify entitlements are correct

### Popup Not Appearing
1. Check window level is `.floating` or higher
2. Verify `collectionBehavior` includes `.fullScreenAuxiliary`
3. Ensure popup view is visible (not zero-sized)

### False Positives
1. Increase debounce time (300ms → 400ms)
2. Increase minimum key count (3 → 4)
3. Verify modifier exclusion is working
