# Feature Specification: Cat Detection Sensitivity Improvements

**Feature Branch**: `008-cat-detection-sensitivity`  
**Created**: 2026-01-21  
**Status**: Draft  
**Input**: User description: "The app works great now but we need to make it a bit more sensitive to cat paws on the keyboard. Often, when 3 keys are pressed (not at the exact time together because the paw doesn't hit the keys dead center), the app leaves the keyboard unlocked. Also, please change the keyboard backup unlock to pressing 5 times the ESC key in a row."

## Summary

Improve cat paw detection sensitivity by implementing a rolling time window that captures rapid sequential key presses (typical of a cat paw landing on keys) rather than requiring all keys to be pressed simultaneously. Additionally, replace the current emergency unlock mechanism (Cmd+Option+Escape held for 2 seconds) with a simpler 5 consecutive ESC key press mechanism.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Improved Cat Paw Detection (Priority: P1)

When a cat paw lands on the keyboard, keys are pressed in rapid succession (within ~300ms) rather than simultaneously. Currently, if a key is released before the third key is pressed, the pattern is not detected. The app should recognize that rapid sequential presses within a short time window represent a single "paw landing" event.

**Why this priority**: This is the core functionality improvement that addresses the main pain point—cats walking on keyboards without triggering the lock.

**Independent Test**: Can be fully tested by rapidly pressing 3 adjacent keys within a short time window (simulating a cat paw) and verifying the lock triggers even if keys aren't held simultaneously.

**Acceptance Scenarios**:

1. **Given** monitoring is active and a user presses 3 adjacent keys within 300ms sequentially (pressing and releasing each one), **When** the keys are pressed rapidly but not simultaneously, **Then** the system detects a cat paw pattern and locks the keyboard.

2. **Given** monitoring is active, **When** a user types normally at regular human typing speed (keys pressed one at a time with >400ms between key presses), **Then** the system does NOT trigger a cat detection lock.

3. **Given** monitoring is active, **When** 3 adjacent keys are pressed simultaneously (all held down at same time), **Then** the system continues to detect this as a cat paw pattern (existing behavior preserved).

4. **Given** monitoring is active, **When** 3 non-adjacent keys are pressed rapidly within 300ms, **Then** the system does NOT trigger because the keys don't form an adjacent cluster.

---

### User Story 2 - ESC Key Emergency Unlock (Priority: P2)

Replace the current emergency unlock mechanism (Cmd+Option+Escape held for 2 seconds) with pressing the ESC key 5 times consecutively. This provides a simpler, more intuitive unlock method that doesn't require remembering a complex key combination.

**Why this priority**: Provides an essential safety mechanism for users to unlock the keyboard when they don't have access to a mouse, but is secondary to improving the detection itself.

**Independent Test**: Can be tested by locking the keyboard (simulating a cat detection), then pressing ESC 5 times rapidly to verify the unlock occurs.

**Acceptance Scenarios**:

1. **Given** the keyboard is locked with the lock popup displayed, **When** the user presses ESC 5 times consecutively (within 2 seconds), **Then** the keyboard unlocks and the popup dismisses.

2. **Given** the keyboard is locked, **When** the user presses ESC 4 times and then waits more than 2 seconds, **Then** the consecutive count resets and the keyboard remains locked.

3. **Given** the keyboard is locked, **When** the user presses ESC 3 times, then another key, then ESC 2 more times, **Then** the keyboard remains locked (non-ESC key resets the count).

4. **Given** the keyboard is locked, **When** the user dismisses via mouse click or trackpad, **Then** the keyboard unlocks as before (existing dismiss mechanism preserved).

---

### User Story 3 - Update Lock Popup Text (Priority: P3)

Update the lock popup to display the new ESC key unlock instructions instead of the old Cmd+Option+Escape instructions.

**Why this priority**: UI update that depends on Story 2 being implemented first.

**Independent Test**: Can be tested by triggering a lock and verifying the popup displays "Press ESC 5 times to unlock" text.

**Acceptance Scenarios**:

1. **Given** a cat paw detection triggers a keyboard lock, **When** the lock popup appears, **Then** it displays instructions indicating "Press ESC 5 times to unlock" alongside the mouse dismiss option.

---

### Edge Cases

- What happens when the user presses ESC exactly 5 times but takes longer than 2 seconds total? Count resets after 2 seconds of no ESC presses; they need to start over.
- What happens if keys are pressed at the exact boundary of the time window (e.g., exactly 300ms apart)? Keys pressed within 300ms inclusive count as part of the rolling window.
- What happens if a user presses many keys rapidly but they're spread across the keyboard (not adjacent)? No lock triggers because the adjacency requirement is not met.
- What if the cat sits on the keyboard (10+ keys)? Existing sitting detection continues to work as before.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST implement a rolling time window (default 300ms) for aggregating rapid sequential key presses into a single detection analysis.
- **FR-002**: System MUST consider all keys pressed within the time window when analyzing for cat paw patterns, even if some keys have been released before others are pressed.
- **FR-003**: System MUST preserve existing detection behavior for keys that are held simultaneously (current behavior remains supported).
- **FR-004**: System MUST maintain the adjacency requirement—keys within the time window must still form a connected cluster to trigger detection.
- **FR-005**: System MUST implement a 5-consecutive-ESC-press unlock mechanism for the lock popup.
- **FR-006**: System MUST reset the consecutive ESC counter if more than 2 seconds pass between ESC presses.
- **FR-007**: System MUST reset the consecutive ESC counter if any non-ESC key is pressed.
- **FR-008**: System MUST display updated unlock instructions on the lock popup indicating "Press ESC 5 times" method.
- **FR-009**: System MUST preserve the existing mouse/trackpad click dismiss functionality.
- **FR-010**: System MUST remove the previous Cmd+Option+Escape hold mechanism.
- **FR-011**: System MUST make the rolling time window configurable (stored in Configuration).

### Key Entities *(include if feature involves data)*

- **KeyboardState**: Extended to track recent key presses within the rolling window, including timestamps for each key event.
- **Configuration**: Extended to include `detectionTimeWindowMs` setting for the rolling window duration.
- **NotificationWindowController**: Modified to handle ESC key counting instead of Cmd+Option+Escape monitoring.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Cat paw patterns are detected when 3+ adjacent keys are pressed within a 300ms window, regardless of whether keys are held simultaneously.
- **SC-002**: Normal human typing at standard speeds (typically >400ms between keypresses) does not trigger false positive cat detections.
- **SC-003**: Users can successfully unlock the keyboard by pressing ESC 5 times within 2 seconds, with 100% reliability.
- **SC-004**: Existing detection patterns (sitting, multi-paw) continue to function correctly.
- **SC-005**: Lock popup clearly communicates the new unlock method.

## Assumptions

- The 300ms time window is appropriate for distinguishing cat paw presses from normal human typing. This value should be configurable for user tuning.
- 5 ESC presses is a balance between being easy enough for users to remember and difficult enough that a cat won't accidentally trigger it.
- The 2-second timeout for consecutive ESC presses provides enough time for users to complete the sequence without being so long that accidental unlocks become more likely.
