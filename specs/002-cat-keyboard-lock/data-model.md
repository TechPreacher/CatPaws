# Data Model: Cat Keyboard Lock

**Feature**: 002-cat-keyboard-lock
**Date**: 2026-01-16

## Entities

### KeyboardState

Tracks the current state of all pressed keys for pattern detection.

| Field | Type | Description |
|-------|------|-------------|
| pressedKeys | Set<UInt16> | Set of currently pressed key codes (CGKeyCode) |
| activeModifiers | Set<UInt16> | Set of currently active modifier key codes |
| lastKeyEventTime | Date | Timestamp of most recent key event |

**Validation Rules**:
- pressedKeys may be empty (no keys pressed)
- activeModifiers is a subset of the defined modifier key codes
- lastKeyEventTime is updated on every key down/up event

**Computed Properties**:
- `nonModifierKeys: Set<UInt16>` - pressedKeys minus modifiers
- `pressedKeyCount: Int` - count of non-modifier keys
- `hasModifiersOnly: Bool` - true if only modifier keys are pressed

---

### DetectionEvent

Represents a detected cat pattern event.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier for the detection event |
| type | DetectionType | Type of detection (paw, multiPaw, sitting) |
| keyCount | Int | Number of non-modifier keys involved |
| timestamp | Date | When the pattern was first detected |
| triggeredLock | Bool | Whether this event triggered a keyboard lock |

**DetectionType Enum**:
```swift
enum DetectionType {
    case paw         // 3-9 adjacent non-modifier keys
    case multiPaw    // Multiple clusters of adjacent keys
    case sitting     // 10+ keys pressed (cat sitting/lying)
}
```

**Validation Rules**:
- keyCount >= 3 for valid detection
- type is determined by keyCount and cluster analysis
- triggeredLock is false until debounce period completes

---

### LockState

Represents the keyboard lock state machine.

| Field | Type | Description |
|-------|------|-------------|
| status | LockStatus | Current state of the lock system |
| lockedAt | Date? | Timestamp when lock was activated (nil if not locked) |
| lockReason | DetectionEvent? | The detection event that triggered the lock |
| cooldownUntil | Date? | When cooldown expires after manual unlock |
| lastRecheckAt | Date? | Timestamp of last periodic re-check |

**LockStatus Enum**:
```swift
enum LockStatus {
    case monitoring   // Normal operation, watching for patterns
    case debouncing   // Pattern detected, waiting for persistence
    case locked       // Keyboard locked, blocking input
    case cooldown     // After manual unlock, ignoring detection
}
```

**State Transitions**:

| From | To | Trigger |
|------|----|---------|
| monitoring | debouncing | Cat pattern detected |
| debouncing | monitoring | Pattern cleared within 200-500ms |
| debouncing | locked | Pattern persisted past debounce period |
| locked | monitoring | Auto-unlock: no keys at re-check |
| locked | cooldown | Manual unlock via popup or menu |
| cooldown | monitoring | 5-10 second cooldown elapsed |

**Validation Rules**:
- lockedAt is non-nil only when status is .locked
- lockReason is non-nil only when status is .locked
- cooldownUntil is non-nil only when status is .cooldown
- lastRecheckAt is updated every 2 seconds while locked

---

### Notification (UI State)

Represents the lock notification popup state.

| Field | Type | Description |
|-------|------|-------------|
| isVisible | Bool | Whether the popup is currently displayed |
| message | String | Message shown in the popup |
| showDismissButton | Bool | Whether to show the dismiss/unlock button |
| detectionType | DetectionType? | Type of detection for icon/messaging |

**Validation Rules**:
- isVisible is true only when LockState.status is .locked
- showDismissButton is always true when visible
- detectionType matches the triggering DetectionEvent.type

---

### Configuration (UserDefaults)

User-configurable settings stored in UserDefaults.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| isEnabled | Bool | true | Whether cat detection is active |
| debounceMs | Int | 300 | Debounce period in milliseconds (200-500) |
| recheckIntervalSec | Double | 2.0 | Seconds between re-checks while locked |
| cooldownSec | Double | 7.0 | Cooldown seconds after manual unlock (5-10) |
| minimumKeyCount | Int | 3 | Minimum adjacent keys to trigger detection |
| playSoundOnLock | Bool | true | Play sound when keyboard locks |
| playSoundOnUnlock | Bool | true | Play sound when keyboard unlocks |

**Validation Rules**:
- debounceMs must be in range 200-500
- recheckIntervalSec must be in range 1.0-5.0
- cooldownSec must be in range 5.0-10.0
- minimumKeyCount must be in range 3-5

---

## Relationships

```
┌─────────────────┐      triggers       ┌─────────────────┐
│  KeyboardState  │─────────────────────│ DetectionEvent  │
└─────────────────┘                     └─────────────────┘
                                               │
                                               │ causes
                                               ▼
┌─────────────────┐      controls       ┌─────────────────┐
│   Notification  │◄────────────────────│   LockState     │
└─────────────────┘                     └─────────────────┘
                                               │
                                               │ reads
                                               ▼
                                        ┌─────────────────┐
                                        │ Configuration   │
                                        └─────────────────┘
```

- **KeyboardState → DetectionEvent**: Key state changes trigger pattern analysis, which may create DetectionEvent
- **DetectionEvent → LockState**: Detection events transition LockState from monitoring to debouncing/locked
- **LockState → Notification**: Lock state changes control notification visibility
- **Configuration → LockState**: Configuration values determine timing thresholds

---

## Key Adjacency Data

The keyboard adjacency map is a static data structure (not persisted):

```swift
// Position-based adjacency calculation
// Row positions (key-widths from left):
// Row 0 (numbers): 0-12
// Row 1 (QWERTY):  1.5-13.5 (offset 0.25 from row 0)
// Row 2 (ASDF):    1.75-13 (offset 0.5 from row 1)
// Row 3 (ZXCV):    2.25-11.25 (offset 0.75 from row 2)

// Adjacency threshold: 1.6 key-widths (captures diagonal neighbors)
```

**Modifier Key Codes (excluded from detection)**:
- Command: 0x37, 0x36
- Shift: 0x38, 0x3C
- Option: 0x3A, 0x3D
- Control: 0x3B, 0x3E
- Function: 0x3F
- Caps Lock: 0x39
