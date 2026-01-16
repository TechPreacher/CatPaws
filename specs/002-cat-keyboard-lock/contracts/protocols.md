# Service Protocols: Cat Keyboard Lock

**Feature**: 002-cat-keyboard-lock
**Date**: 2026-01-16

## Overview

This document defines the internal service protocols (interfaces) for the cat keyboard lock feature. These protocols enable testability through dependency injection and clear separation of concerns.

---

## KeyboardMonitoring Protocol

Responsible for system-level keyboard event monitoring.

```swift
protocol KeyboardMonitoring: AnyObject {
    /// Delegate to receive keyboard events
    var delegate: KeyboardMonitorDelegate? { get set }

    /// Whether the monitor is currently active
    var isMonitoring: Bool { get }

    /// Start monitoring keyboard events
    /// - Throws: PermissionError if accessibility permission not granted
    func startMonitoring() throws

    /// Stop monitoring keyboard events
    func stopMonitoring()

    /// Check if app has required Input Monitoring permission
    func hasPermission() -> Bool

    /// Request Input Monitoring permission (shows system dialog)
    func requestPermission()

    /// Open System Settings to Input Monitoring pane
    func openPermissionSettings()
}

protocol KeyboardMonitorDelegate: AnyObject {
    /// Called when a key is pressed
    /// - Parameters:
    ///   - keyCode: The CGKeyCode of the pressed key
    ///   - timestamp: When the event occurred
    func keyDidPress(_ keyCode: UInt16, at timestamp: Date)

    /// Called when a key is released
    /// - Parameters:
    ///   - keyCode: The CGKeyCode of the released key
    ///   - timestamp: When the event occurred
    func keyDidRelease(_ keyCode: UInt16, at timestamp: Date)

    /// Called when modifier flags change
    /// - Parameters:
    ///   - modifiers: Set of currently active modifier key codes
    ///   - timestamp: When the event occurred
    func modifiersDidChange(_ modifiers: Set<UInt16>, at timestamp: Date)
}

enum PermissionError: Error {
    case accessibilityNotGranted
    case eventTapCreationFailed
}
```

---

## CatDetection Protocol

Responsible for analyzing key patterns and detecting cat presence.

```swift
protocol CatDetecting {
    /// Analyze current keyboard state for cat patterns
    /// - Parameter state: Current keyboard state
    /// - Returns: DetectionEvent if cat pattern found, nil otherwise
    func analyzePattern(_ state: KeyboardState) -> DetectionEvent?

    /// Check if a set of keys forms a connected cluster
    /// - Parameter keyCodes: Set of pressed key codes
    /// - Returns: true if keys are adjacent and connected
    func formsConnectedCluster(_ keyCodes: Set<UInt16>) -> Bool

    /// Get adjacent keys for a given key
    /// - Parameter keyCode: The key to check
    /// - Returns: Set of adjacent key codes
    func adjacentKeys(for keyCode: UInt16) -> Set<UInt16>

    /// Check if a key is a modifier key
    /// - Parameter keyCode: The key to check
    /// - Returns: true if key is a modifier
    func isModifierKey(_ keyCode: UInt16) -> Bool
}
```

---

## KeyboardLocking Protocol

Responsible for blocking keyboard input when locked.

```swift
protocol KeyboardLocking: AnyObject {
    /// Whether keyboard input is currently blocked
    var isLocked: Bool { get }

    /// Lock the keyboard (block all input)
    func lock()

    /// Unlock the keyboard (allow input)
    func unlock()

    /// Process a keyboard event, blocking if locked
    /// - Parameter event: The keyboard event to process
    /// - Returns: true if event should be passed through, false if blocked
    func shouldPassThrough(_ event: CGEvent) -> Bool
}
```

---

## LockStateManaging Protocol

Responsible for managing the lock state machine and timing.

```swift
protocol LockStateManaging: AnyObject {
    /// Current lock state
    var currentState: LockState { get }

    /// Publisher for state changes (for SwiftUI binding)
    var statePublisher: AnyPublisher<LockState, Never> { get }

    /// Handle a cat detection event
    /// - Parameter event: The detection event
    func handleDetection(_ event: DetectionEvent) async

    /// Handle pattern cleared (keys released during debounce)
    func handlePatternCleared()

    /// Perform periodic re-check while locked
    /// - Parameter currentKeyState: Current keyboard state
    func performRecheck(currentKeyState: KeyboardState) async

    /// Manually unlock (user dismissed popup or used menu)
    func manualUnlock()

    /// Reset to monitoring state
    func reset()
}
```

---

## NotificationPresenting Protocol

Responsible for showing/hiding the lock notification popup.

```swift
protocol NotificationPresenting: AnyObject {
    /// Whether the notification is currently visible
    var isVisible: Bool { get }

    /// Show the lock notification
    /// - Parameters:
    ///   - detectionType: Type of cat detection for messaging
    ///   - onDismiss: Callback when user clicks dismiss button
    func show(detectionType: DetectionType, onDismiss: @escaping () -> Void)

    /// Hide the notification
    func hide()

    /// Update the notification message
    /// - Parameter message: New message to display
    func updateMessage(_ message: String)
}
```

---

## Configuration Protocol

Responsible for reading/writing user configuration.

```swift
protocol ConfigurationProviding {
    /// Whether cat detection is enabled
    var isEnabled: Bool { get set }

    /// Debounce period in milliseconds (200-500)
    var debounceMs: Int { get set }

    /// Re-check interval in seconds while locked (1-5)
    var recheckIntervalSec: Double { get set }

    /// Cooldown period in seconds after manual unlock (5-10)
    var cooldownSec: Double { get set }

    /// Minimum adjacent keys to trigger detection (3-5)
    var minimumKeyCount: Int { get set }

    /// Play sound when keyboard locks
    var playSoundOnLock: Bool { get set }

    /// Play sound when keyboard unlocks
    var playSoundOnUnlock: Bool { get set }

    /// Reset all settings to defaults
    func resetToDefaults()
}
```

---

## Service Dependencies

```
┌──────────────────────┐
│    AppViewModel      │
│  (orchestrates all)  │
└──────────────────────┘
          │
          │ uses
          ▼
┌──────────────────────┐     ┌──────────────────────┐
│  KeyboardMonitoring  │────▶│    CatDetecting      │
└──────────────────────┘     └──────────────────────┘
          │                            │
          │                            │ triggers
          ▼                            ▼
┌──────────────────────┐     ┌──────────────────────┐
│   KeyboardLocking    │◀────│  LockStateManaging   │
└──────────────────────┘     └──────────────────────┘
                                       │
                                       │ controls
                                       ▼
                             ┌──────────────────────┐
                             │ NotificationPresenting│
                             └──────────────────────┘
                                       │
                                       │ reads
                                       ▼
                             ┌──────────────────────┐
                             │ ConfigurationProviding│
                             └──────────────────────┘
```

---

## Testing Considerations

Each protocol can be mocked for unit testing:

- **MockKeyboardMonitor**: Simulates key press/release events
- **MockCatDetector**: Returns predetermined detection results
- **MockKeyboardLock**: Tracks lock/unlock calls without system interaction
- **MockLockStateManager**: Allows direct state manipulation for testing transitions
- **MockNotificationPresenter**: Tracks show/hide calls without UI
- **MockConfiguration**: In-memory configuration for tests
