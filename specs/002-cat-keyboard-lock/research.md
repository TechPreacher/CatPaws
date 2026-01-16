# Research: Cat Keyboard Lock

**Feature**: 002-cat-keyboard-lock
**Date**: 2026-01-16

## Research Areas

### 1. macOS Global Keyboard Monitoring

**Decision**: Use `CGEvent.tapCreate` for global keyboard event interception

**Rationale**:
- Can both monitor and block keyboard events (return `nil` from callback to block)
- App Store compatible since macOS 10.15 with `com.apple.security.device.input-monitoring` entitlement
- Works at session level to capture all keyboard input
- Supports key down, key up, and modifier (flagsChanged) events

**Alternatives Considered**:
- `NSEvent.addGlobalMonitorForEvents`: Cannot block events, only observe. Rejected.
- `IOKit HID`: Too low-level, not App Store compatible. Rejected.

**Key Implementation Notes**:
```swift
// Event mask for keyboard monitoring
let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) |
                              (1 << CGEventType.keyUp.rawValue) |
                              (1 << CGEventType.flagsChanged.rawValue)

// Create tap at session level, head insert to intercept first
let tap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,  // Can modify/block events
    eventsOfInterest: eventMask,
    callback: keyboardCallback,
    userInfo: contextPointer
)
```

**Blocking Events**: Return `nil` from the callback to block an event, or `Unmanaged.passUnretained(event)` to pass through.

**Important**: Handle `tapDisabledByTimeout` in callback and re-enable the tap.

---

### 2. Permission Handling (Accessibility/Input Monitoring)

**Decision**: Use `CGPreflightListenEventAccess()` and `CGRequestListenEventAccess()` for permission management

**Rationale**:
- These are the official APIs for Input Monitoring permission
- Trigger the system permission dialog
- Work correctly with App Sandbox

**Implementation Pattern**:
```swift
func checkAndRequestPermission() -> Bool {
    if CGPreflightListenEventAccess() {
        return true
    }
    CGRequestListenEventAccess()  // Shows system dialog
    return false  // App typically needs restart after grant
}

// Open System Settings directly
func openPermissionSettings() {
    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
    NSWorkspace.shared.open(url)
}
```

**User Flow**:
1. Check permission on app launch
2. If denied, show explanation and button to open System Settings
3. Guide user to enable permission
4. App may need restart after permission granted

---

### 3. Keyboard Adjacency Mapping

**Decision**: Position-based adjacency calculation with 1.6 key-width threshold

**Rationale**:
- Physical keyboard layout is staggered (rows offset by ~0.25-0.75 key widths)
- Position-based calculation handles stagger correctly
- Threshold of 1.6 captures diagonal neighbors while excluding keys 2+ apart

**Layout Positions** (key-widths from left edge):
- Row 0 (numbers): ` 1 2 3 4 5 6 7 8 9 0 - = at positions 0-12
- Row 1 (QWERTY): Tab Q W E R T Y U I O P [ ] \ at positions 0, 1.5-13.5
- Row 2 (ASDF): Caps A S D F G H J K L ; ' Return at positions 0, 1.75-13
- Row 3 (ZXCV): Shift Z X C V B N M , . / at positions 0, 2.25-11.25
- Row 4: Space at position 5.5 (centered)

**Adjacency Algorithm**:
- Same row: horizontal distance ≤ 1.6
- Adjacent rows: 2D Euclidean distance ≤ 1.6 (accounting for 1.0 vertical separation)

**Connected Cluster Detection**:
- Use BFS/DFS to verify all pressed keys are connected through adjacency
- Cat paw creates connected cluster; random key combos typically don't

---

### 4. Key Code Mapping (CGKeyCode)

**Decision**: Use Carbon HIToolbox key codes (stable across macOS versions)

**Key Codes (hexadecimal)**:
```
Letters: A=0x00, S=0x01, D=0x02, F=0x03, G=0x05, H=0x04
         Z=0x06, X=0x07, C=0x08, V=0x09, B=0x0B
         Q=0x0C, W=0x0D, E=0x0E, R=0x0F, T=0x11, Y=0x10
         U=0x20, I=0x22, O=0x1F, P=0x23
         J=0x26, K=0x28, L=0x25
         N=0x2D, M=0x2E

Numbers: 1=0x12, 2=0x13, 3=0x14, 4=0x15, 5=0x17, 6=0x16
         7=0x1A, 8=0x1C, 9=0x19, 0=0x1D

Modifiers (exclude from detection):
         Cmd=0x37/0x36, Shift=0x38/0x3C, Option=0x3A/0x3D
         Control=0x3B/0x3E, Fn=0x3F, CapsLock=0x39
```

---

### 5. Popup Window (System-Level Overlay)

**Decision**: Use SwiftUI Window with `.alert` window level for system-wide overlay

**Rationale**:
- SwiftUI `Window` with custom window level appears above all apps
- Can display in full-screen mode using NSPanel with appropriate collection behavior
- Follows Apple HIG for notifications

**Implementation Approach**:
```swift
// Use NSPanel for floating window behavior
let panel = NSPanel(
    contentRect: rect,
    styleMask: [.borderless, .nonactivatingPanel],
    backing: .buffered,
    defer: false
)
panel.level = .floating  // or .statusBar for higher
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
panel.contentView = NSHostingView(rootView: CatLockPopupView())
```

---

### 6. Debounce and Timing

**Decision**: Use Swift async/await with Task-based debounce

**Rationale**:
- Modern Swift concurrency is Constitution requirement
- Task cancellation handles debounce elegantly
- Timer-based re-check during lock state

**Pattern**:
```swift
actor DetectionDebouncer {
    private var debounceTask: Task<Void, Never>?

    func patternDetected() async -> Bool {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))  // 200-500ms
            guard !Task.isCancelled else { return }
            // Pattern persisted - trigger lock
        }
        // Wait for debounce period
        return await debounceTask?.value != nil
    }
}
```

---

### 7. State Machine for Lock State

**Decision**: Explicit state machine with enum for clarity and testability

**States**:
- `monitoring`: Normal operation, checking for cat patterns
- `debouncing`: Pattern detected, waiting for persistence confirmation
- `locked`: Keyboard locked, blocking input, showing popup
- `cooldown`: After manual unlock, temporarily ignoring detection

**Transitions**:
```
monitoring -> debouncing: Cat pattern detected
debouncing -> monitoring: Pattern cleared within debounce period
debouncing -> locked: Pattern persisted past debounce
locked -> monitoring: Auto-unlock (no keys pressed at re-check)
locked -> cooldown: Manual unlock (dismiss button or menu)
cooldown -> monitoring: Cooldown period elapsed
```

---

## Resolved Clarifications

| Topic | Resolution |
|-------|------------|
| Keyboard monitoring API | CGEvent.tapCreate with defaultTap option |
| Permission model | Input Monitoring (com.apple.security.device.input-monitoring) |
| Adjacency calculation | Position-based with 1.6 threshold |
| Popup implementation | NSPanel with floating level and fullScreenAuxiliary |
| Timing mechanism | Swift async/await with Task cancellation |

## References

- Apple Developer: CGEvent.tapCreate documentation
- Apple Developer: CGPreflightListenEventAccess / CGRequestListenEventAccess
- Carbon HIToolbox/Events.h: Key code constants
- Apple HIG: Notifications and alerts
