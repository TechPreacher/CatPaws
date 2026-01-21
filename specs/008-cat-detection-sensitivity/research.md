# Research: Cat Detection Sensitivity Improvements

**Feature**: 008-cat-detection-sensitivity  
**Date**: 2026-01-21

## Research Tasks

### 1. Rolling Time Window Implementation Pattern

**Question**: How to efficiently track key events within a rolling time window in Swift?

**Decision**: Use a timestamped event buffer with automatic pruning.

**Rationale**: 
- Swift's `Date` type provides nanosecond precision for timestamps
- A simple array of `(keyCode: UInt16, timestamp: Date)` tuples is sufficient
- Prune entries older than the time window on each new key event
- Memory-efficient: at 300ms window with even rapid cat paw presses, max ~10-15 entries

**Alternatives considered**:
- Circular buffer: Overkill for this use case, adds complexity
- Timer-based cleanup: Unnecessary overhead, event-driven pruning is simpler
- Combine PassthroughSubject with time window operator: More complex than needed

**Implementation approach**:
```swift
struct TimestampedKeyEvent {
    let keyCode: UInt16
    let timestamp: Date
}

// In KeyboardState:
private(set) var recentKeyPresses: [TimestampedKeyEvent] = []

mutating func keyPressed(_ keyCode: UInt16, at timestamp: Date = Date()) {
    // Prune old entries
    let cutoff = timestamp.addingTimeInterval(-timeWindowSeconds)
    recentKeyPresses.removeAll { $0.timestamp < cutoff }
    
    // Add new entry
    recentKeyPresses.append(TimestampedKeyEvent(keyCode: keyCode, timestamp: timestamp))
    
    // Update existing state
    pressedKeys.insert(keyCode)
    lastKeyEventTime = timestamp
}

var keysInTimeWindow: Set<UInt16> {
    Set(recentKeyPresses.map(\.keyCode))
}
```

---

### 2. Detection Logic Modification

**Question**: How to modify CatDetectionService to use time-windowed keys while preserving existing behavior?

**Decision**: Union of currently-pressed keys with time-windowed recent keys.

**Rationale**:
- Current behavior: analyzes `pressedKeys` (keys currently held down)
- New behavior: analyzes `pressedKeys ∪ keysInTimeWindow` (held keys + recent rapid presses)
- This preserves existing simultaneous-press detection while adding sequential support
- The adjacency check already operates on a Set, so no algorithm changes needed

**Alternatives considered**:
- Replace pressedKeys entirely with time window: Would break modifier key handling
- Separate detection paths: Adds complexity without benefit

**Implementation approach**:
- `KeyboardState` provides `keysForDetection` computed property that returns union
- `AppViewModel.analyzeCurrentKeys()` passes this union to `CatDetectionService`
- No changes to `CatDetectionService.analyzePattern()` signature needed

---

### 3. ESC Key Counting State Machine

**Question**: Best pattern for tracking consecutive ESC presses with timeout?

**Decision**: Simple counter with timestamp, reset on non-ESC or timeout.

**Rationale**:
- State: `escPressCount: Int`, `lastEscPressTime: Date?`
- On ESC keyDown: check if within timeout, increment or reset counter
- On non-ESC keyDown: reset counter
- When counter reaches 5: trigger unlock
- Simple, testable, no complex state machine needed

**Alternatives considered**:
- Full state machine enum: Overkill for 5-press counter
- Combine publisher chain: Harder to test and debug
- Timer-based approach: Introduces async complexity

**Implementation approach**:
```swift
// In NotificationWindowController:
private var escPressCount: Int = 0
private var lastEscPressTime: Date?
private let escTimeoutSeconds: TimeInterval = 2.0
private let requiredEscPresses: Int = 5

private func handleKeyEvent(_ event: NSEvent) {
    guard event.type == .keyDown else { return }
    
    let escapeKeyCode: UInt16 = 53
    
    if event.keyCode == escapeKeyCode {
        let now = Date()
        if let lastTime = lastEscPressTime,
           now.timeIntervalSince(lastTime) <= escTimeoutSeconds {
            escPressCount += 1
        } else {
            escPressCount = 1
        }
        lastEscPressTime = now
        
        if escPressCount >= requiredEscPresses {
            handleDismiss()
        }
    } else {
        // Non-ESC key resets counter
        escPressCount = 0
        lastEscPressTime = nil
    }
}
```

---

### 4. Configuration Storage

**Question**: How to add detectionTimeWindowMs to Configuration?

**Decision**: Follow existing pattern in Configuration.swift.

**Rationale**:
- Existing keys use `catpaws.` prefix
- Existing range validation pattern (clamp to valid range)
- Default 300ms, range 100-500ms allows user tuning

**Implementation**:
```swift
// In Keys enum:
static let detectionTimeWindowMs = "catpaws.detectionTimeWindowMs"

// In Defaults enum:
static let detectionTimeWindowMs = 300

// In Ranges enum:
static let detectionTimeWindowMs = 100...500

// Property:
var detectionTimeWindowMs: Int {
    get { /* same pattern as debounceMs */ }
    set { /* same pattern as debounceMs */ }
}
```

---

### 5. Popup Text Update

**Question**: What text should replace the Cmd+Option+Escape instructions?

**Decision**: "Press ESC 5 times to unlock"

**Rationale**:
- Clear, concise, actionable
- Uses "ESC" which is universally recognized
- Specifies exact count for clarity
- Consistent with Apple's tone in system dialogs

**Implementation**:
```swift
// In CatLockPopupView:
// Replace: Text("Or hold ⌘⌥⎋ for 2 seconds")
// With:    Text("Or press ESC 5 times to unlock")
```

---

## Summary of Decisions

| Topic | Decision | Key Files Affected |
|-------|----------|-------------------|
| Time window tracking | Timestamped event buffer with pruning | KeyboardState.swift |
| Detection modification | Union of pressed + recent keys | AppViewModel.swift |
| ESC unlock | Counter with 2s timeout | NotificationWindowController.swift |
| Configuration | Add detectionTimeWindowMs (100-500ms, default 300) | Configuration.swift, ConfigurationProviding.swift |
| Popup text | "Press ESC 5 times to unlock" | CatLockPopupView.swift |

## Dependencies

No new external dependencies required. All implementations use Swift standard library and existing AppKit/SwiftUI frameworks.
