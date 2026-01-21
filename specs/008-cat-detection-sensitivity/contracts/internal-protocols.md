# Internal Contracts: Cat Detection Sensitivity

**Feature**: 008-cat-detection-sensitivity  
**Date**: 2026-01-21

## Protocol Changes

### ConfigurationProviding (MODIFIED)

```swift
protocol ConfigurationProviding {
    // Existing properties...
    var isEnabled: Bool { get set }
    var debounceMs: Int { get set }
    var cooldownSec: Double { get set }
    var minimumKeyCount: Int { get set }
    var playSoundOnLock: Bool { get set }
    var playSoundOnUnlock: Bool { get set }
    
    // NEW: Rolling time window for detection
    /// Time window in milliseconds for aggregating rapid key presses (100-500)
    var detectionTimeWindowMs: Int { get set }
    
    func resetToDefaults()
}
```

---

## Struct Changes

### KeyboardState (MODIFIED)

```swift
/// Timestamped key event for rolling window tracking
struct TimestampedKeyEvent {
    let keyCode: UInt16
    let timestamp: Date
}

struct KeyboardState {
    // Existing properties
    private(set) var pressedKeys: Set<UInt16>
    private(set) var activeModifiers: Set<UInt16>
    private(set) var lastKeyEventTime: Date
    
    // NEW: Rolling window tracking
    private(set) var recentKeyPresses: [TimestampedKeyEvent]
    
    // NEW: Injected configuration
    var timeWindowSeconds: TimeInterval
    
    // NEW: Computed property for detection
    /// Returns union of currently pressed keys and keys pressed within time window
    /// Excludes modifier keys
    var keysForDetection: Set<UInt16> {
        let recentKeys = Set(recentKeyPresses.map(\.keyCode))
        let allKeys = pressedKeys.union(recentKeys)
        return allKeys.subtracting(KeyboardAdjacencyMap.modifierKeyCodes)
    }
    
    // MODIFIED: keyPressed now accepts timestamp and manages window
    mutating func keyPressed(_ keyCode: UInt16, at timestamp: Date = Date())
    
    // Existing methods unchanged
    mutating func keyReleased(_ keyCode: UInt16)
    mutating func modifierPressed(_ keyCode: UInt16)
    mutating func modifierReleased(_ keyCode: UInt16)
    mutating func updateModifiers(_ modifiers: Set<UInt16>)
    mutating func clearAll()
}
```

---

## Method Signature Changes

### KeyboardMonitorDelegate (UNCHANGED)

The delegate protocol remains unchanged. The timestamp is already passed:

```swift
protocol KeyboardMonitorDelegate: AnyObject {
    func keyDidPress(_ keyCode: UInt16, at timestamp: Date)
    func keyDidRelease(_ keyCode: UInt16, at timestamp: Date)
    func modifiersDidChange(_ modifiers: Set<UInt16>, at timestamp: Date)
}
```

### AppViewModel Changes

```swift
// MODIFIED: Pass timestamp to keyboardState
extension AppViewModel: KeyboardMonitorDelegate {
    nonisolated func keyDidPress(_ keyCode: UInt16, at timestamp: Date) {
        Task { @MainActor in
            keyboardState.keyPressed(keyCode, at: timestamp)  // NOW includes timestamp
            analyzeCurrentKeys()
        }
    }
}

// MODIFIED: Use keysForDetection instead of nonModifierKeys
private func analyzeCurrentKeys() {
    // OLD: let nonModifierKeys = keyboardState.nonModifierKeys
    // NEW: Uses keysForDetection which includes time window
    let keysToAnalyze = keyboardState.keysForDetection
    
    if let detection = catDetectionService.analyzePattern(pressedKeys: keysToAnalyze) {
        lockStateManager.handleDetection(detection)
    } else if lockStateManager.state.status == .debouncing &&
              keysToAnalyze.count < configuration.minimumKeyCount {
        lockStateManager.handleKeysReleased()
    }
}
```

---

## NotificationWindowController Internal API

```swift
final class NotificationWindowController: NotificationPresenting {
    // REMOVED
    // private var emergencyShortcutTask: Task<Void, Never>?
    // private let emergencyHoldDuration: TimeInterval = 2.0
    
    // NEW: ESC counting state
    private var escPressCount: Int = 0
    private var lastEscPressTime: Date?
    private let escTimeoutSeconds: TimeInterval = 2.0
    private let requiredEscPresses: Int = 5
    
    // MODIFIED: Event handling
    private func handleEmergencyShortcutEvent(_ event: NSEvent) {
        // NEW implementation: count ESC presses instead of hold detection
    }
    
    // REMOVED
    // private func startEmergencyShortcutTimer()
    // private func cancelEmergencyShortcutTimer()
}
```

---

## UI Contract

### CatLockPopupView

```swift
// Text change only - no API changes
// OLD: Text("Or hold ⌘⌥⎋ for 2 seconds")
// NEW: Text("Or press ESC 5 times to unlock")

// Accessibility label update
// OLD: "Emergency unlock shortcut: hold Command, Option, and Escape keys for 2 seconds"
// NEW: "Emergency unlock: press Escape key 5 times quickly"
```
