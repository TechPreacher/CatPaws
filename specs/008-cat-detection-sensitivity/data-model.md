# Data Model: Cat Detection Sensitivity Improvements

**Feature**: 008-cat-detection-sensitivity  
**Date**: 2026-01-21

## Entity Changes

### 1. TimestampedKeyEvent (NEW)

Represents a single key press event with its timestamp for time window tracking.

| Field | Type | Description |
|-------|------|-------------|
| keyCode | UInt16 | The key code of the pressed key |
| timestamp | Date | When the key was pressed |

**Relationships**: Contained within KeyboardState's recentKeyPresses array

**Validation**: None required (immutable value type)

---

### 2. KeyboardState (MODIFIED)

Extended to track recent key presses within the rolling time window.

| Field | Type | Change | Description |
|-------|------|--------|-------------|
| pressedKeys | Set<UInt16> | Existing | Currently held keys |
| activeModifiers | Set<UInt16> | Existing | Currently active modifier keys |
| lastKeyEventTime | Date | Existing | Timestamp of most recent event |
| recentKeyPresses | [TimestampedKeyEvent] | **NEW** | Recent key presses within time window |
| timeWindowSeconds | TimeInterval | **NEW** | Configuration-injected window duration |

**New Computed Properties**:
- `keysInTimeWindow: Set<UInt16>` - Unique key codes from recent presses
- `keysForDetection: Set<UInt16>` - Union of pressedKeys and keysInTimeWindow (excluding modifiers)

**State Transitions**:
- `keyPressed(_:at:)` → Adds to pressedKeys, adds TimestampedKeyEvent, prunes old entries
- `keyReleased(_:)` → Removes from pressedKeys only (recent history preserved)
- `clearAll()` → Clears both pressedKeys and recentKeyPresses

---

### 3. Configuration (MODIFIED)

Extended with detection time window setting.

| Field | Type | Change | Description |
|-------|------|--------|-------------|
| detectionTimeWindowMs | Int | **NEW** | Rolling window duration in milliseconds (100-500, default 300) |

**Persistence**: UserDefaults key `catpaws.detectionTimeWindowMs`

**Validation**: Clamped to range 100-500ms

---

### 4. NotificationWindowController Internal State (MODIFIED)

Replaced emergency shortcut tracking with ESC counter.

| Field | Type | Change | Description |
|-------|------|--------|-------------|
| emergencyShortcutTask | Task | **REMOVED** | No longer needed |
| emergencyHoldDuration | TimeInterval | **REMOVED** | No longer needed |
| escPressCount | Int | **NEW** | Consecutive ESC press counter |
| lastEscPressTime | Date? | **NEW** | Timestamp of last ESC press |

**Constants**:
- `escTimeoutSeconds: TimeInterval = 2.0` - Maximum time between ESC presses
- `requiredEscPresses: Int = 5` - Number of ESC presses to unlock

**State Transitions**:
- ESC pressed within timeout → Increment counter
- ESC pressed after timeout → Reset counter to 1
- Non-ESC pressed → Reset counter to 0
- Counter reaches 5 → Trigger unlock

---

## Data Flow

```text
KeyboardMonitor
    │
    ▼ keyDidPress(keyCode, timestamp)
    │
AppViewModel
    │
    ▼ keyboardState.keyPressed(keyCode, at: timestamp)
    │
KeyboardState
    │ 1. Prune recentKeyPresses older than timeWindowSeconds
    │ 2. Add TimestampedKeyEvent to recentKeyPresses
    │ 3. Add keyCode to pressedKeys
    │
    ▼ keyboardState.keysForDetection
    │
AppViewModel
    │
    ▼ catDetectionService.analyzePattern(pressedKeys: keysForDetection)
    │
CatDetectionService
    │ (unchanged logic - receives Set<UInt16>)
    │
    ▼ DetectionEvent or nil
```

---

## Configuration Defaults

| Setting | Key | Default | Range | Unit |
|---------|-----|---------|-------|------|
| detectionTimeWindowMs | catpaws.detectionTimeWindowMs | 300 | 100-500 | milliseconds |

---

## Memory Considerations

- **recentKeyPresses array**: At 300ms window with rapid cat paw presses, typically <15 entries
- **Pruning**: Automatic on each keyPressed call, no timer overhead
- **Cleanup**: clearAll() clears history, called when monitoring stops
