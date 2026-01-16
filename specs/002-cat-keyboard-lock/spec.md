# Feature Specification: Cat Keyboard Lock

**Feature Branch**: `002-cat-keyboard-lock`
**Created**: 2026-01-16
**Status**: Draft
**Input**: User description: "Logic for detecting when a cat is on the keyboard and locking input to prevent unwanted keystrokes, with visual feedback and automatic unlock when the cat leaves."

## Clarifications

### Session 2026-01-16

- Q: How should the system handle brief accidental multi-key presses by humans? → A: Require pattern to persist for 200-500ms before locking
- Q: Can users interact with the notification popup to unlock? → A: Popup includes a dismiss/unlock button for immediate manual override
- Q: What happens when user dismisses lock but cat is still on keyboard? → A: Brief cooldown (5-10 seconds) before re-detection can trigger lock again

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cat Paw Detection (Priority: P1)

As a user working on my computer, I want the app to detect when my cat places a paw on the keyboard so that random keystrokes from the cat's paw don't interfere with my work.

**Why this priority**: This is the core detection mechanism. Without reliable paw detection, the entire feature cannot function. A single paw on the keyboard is the most common initial interaction.

**Independent Test**: Can be fully tested by pressing multiple adjacent non-modifier keys simultaneously and verifying detection triggers. Delivers immediate value by preventing the most common cat-keyboard interaction.

**Acceptance Scenarios**:

1. **Given** the app is running and monitoring keyboard input, **When** 3 or more adjacent non-modifier keys are pressed simultaneously, **Then** the system detects this as potential cat presence.
2. **Given** the app is running, **When** a user presses 2 modifier keys (e.g., Shift+Control), **Then** the system does NOT flag this as cat presence.
3. **Given** the app is running, **When** a user types normally (sequential single key presses), **Then** the system does NOT flag this as cat presence.

---

### User Story 2 - Keyboard Lock Activation (Priority: P1)

As a user, I want the keyboard to be locked immediately when a cat is detected so that no unwanted input reaches my active application.

**Why this priority**: Equally critical as detection - once a cat is detected, the system must prevent keystrokes from reaching applications immediately.

**Independent Test**: Can be tested by triggering cat detection and verifying that subsequent keystrokes are blocked from reaching any application.

**Acceptance Scenarios**:

1. **Given** the cat detection has triggered, **When** any key is pressed on the keyboard, **Then** the keystroke is NOT forwarded to the active application.
2. **Given** the keyboard is locked, **When** the cat continues pressing keys, **Then** no input reaches any application.
3. **Given** the keyboard is locked, **When** the user attempts to type, **Then** the input is blocked until the lock is released.

---

### User Story 3 - Visual Notification (Priority: P2)

As a user, I want to see a clear visual indicator when the keyboard is locked so that I understand why my typing isn't working.

**Why this priority**: Important for user experience but not critical for the core functionality. Users need feedback to understand the system state.

**Independent Test**: Can be tested by triggering keyboard lock and verifying a popup notification appears on screen with appropriate messaging.

**Acceptance Scenarios**:

1. **Given** the cat detection triggers and keyboard locks, **When** the lock activates, **Then** a popup notification appears on screen indicating the keyboard is locked due to cat detection.
2. **Given** the popup is displayed, **When** the keyboard remains locked, **Then** the popup stays visible on screen.
3. **Given** the popup is displayed, **When** the keyboard unlocks, **Then** the popup disappears.
4. **Given** the popup is displayed with a dismiss/unlock button, **When** the user clicks the button, **Then** the keyboard immediately unlocks and the popup disappears.
5. **Given** the user has manually dismissed the lock, **When** a cat pattern is still detected within the cooldown period (5-10 seconds), **Then** the system does NOT re-lock the keyboard.

---

### User Story 4 - Automatic Unlock (Priority: P1)

As a user, I want the keyboard to automatically unlock when the cat leaves so that I can resume working without manual intervention.

**Why this priority**: Critical for usability - without automatic unlock, users would need to manually intervene every time, defeating the purpose of automatic detection.

**Independent Test**: Can be tested by triggering keyboard lock, releasing all keys, waiting for the re-check interval, and verifying the keyboard unlocks automatically.

**Acceptance Scenarios**:

1. **Given** the keyboard is locked, **When** all keys are released and no cat-like pattern is detected for the configured interval, **Then** the keyboard automatically unlocks.
2. **Given** the keyboard is locked, **When** the system performs periodic re-checks and detects no keys pressed, **Then** the keyboard unlocks.
3. **Given** the keyboard has unlocked, **When** the user types normally, **Then** keystrokes are forwarded to applications as expected.

---

### User Story 5 - Multi-Paw and Full Cat Detection (Priority: P2)

As a user, I want the system to detect when my cat is sitting or lying on the keyboard (multiple paws or body contact) so that even extensive keyboard coverage is handled.

**Why this priority**: Extends the core detection to handle more extreme cases. Single-paw detection handles most scenarios; this adds robustness.

**Independent Test**: Can be tested by pressing a large number of keys (10+) across the keyboard simultaneously and verifying detection triggers.

**Acceptance Scenarios**:

1. **Given** the app is running, **When** multiple clusters of adjacent keys are pressed simultaneously (simulating multiple paws), **Then** the system detects cat presence.
2. **Given** the app is running, **When** a very large number of keys (10+) are pressed simultaneously, **Then** the system detects this as a cat sitting/lying on the keyboard.
3. **Given** any cat detection pattern is identified, **When** the pattern persists, **Then** the keyboard remains locked.

---

### Edge Cases

- What happens when the user needs to override the lock? (User can unlock via popup dismiss button or menu bar app interaction)
- How does the system handle rapid key presses that might briefly look like cat patterns? (Assumption: Brief accidental patterns that resolve within the re-check interval will auto-unlock)
- What happens if the system is overwhelmed by excessive key presses? (Assumption: System handles gracefully without crashing)
- How does detection work with external keyboards? (Assumption: Detection works with any connected keyboard)
- What happens if the popup cannot be displayed (e.g., full-screen app)? (Assumption: Popup uses system-level overlay that appears above all content)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST monitor all keyboard input events at the system level.
- **FR-002**: System MUST detect cat-like patterns defined as: 3 or more adjacent non-modifier keys pressed simultaneously.
- **FR-002a**: System MUST require detected patterns to persist for 200-500ms before triggering keyboard lock (debounce to prevent false positives from brief accidental touches).
- **FR-003**: System MUST detect large key press events defined as: 10 or more keys pressed simultaneously, indicating cat sitting/lying.
- **FR-004**: System MUST NOT flag modifier-only key combinations (Shift, Control, Option, Command) as cat patterns regardless of adjacency.
- **FR-005**: System MUST NOT flag normal sequential typing (single keys pressed one after another) as cat patterns.
- **FR-006**: System MUST block all keyboard input from reaching applications when locked.
- **FR-007**: System MUST display a popup notification when keyboard lock activates, including a dismiss/unlock button for immediate manual override.
- **FR-008**: System MUST periodically re-check keyboard state while locked (default interval: 2 seconds).
- **FR-009**: System MUST automatically unlock when no keys are detected during a re-check.
- **FR-010**: System MUST dismiss the popup notification when keyboard unlocks.
- **FR-011**: System MUST allow manual unlock through both the popup dismiss button and the menu bar application interface.
- **FR-011a**: System MUST implement a cooldown period (5-10 seconds) after manual unlock, during which re-detection will not trigger a new lock.
- **FR-012**: System MUST maintain keyboard adjacency mapping to determine which keys are neighbors.

### Key Entities

- **KeyboardState**: Represents the current state of all pressed keys, their adjacency relationships, and whether modifier keys are involved.
- **DetectionEvent**: Represents a detected cat pattern, including the type (single paw, multiple paws, sitting/lying) and timestamp.
- **LockState**: Represents whether the keyboard is currently locked, when it was locked, the reason for locking, and cooldown status after manual unlock.
- **Notification**: Represents the visual popup shown to the user, including its visibility state and displayed message.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: System correctly identifies cat-paw patterns (3+ adjacent non-modifier keys) in 95% of test cases.
- **SC-002**: System allows legitimate modifier key combinations (Shift+Control, Option+Command, etc.) without false positives in 100% of test cases.
- **SC-003**: System blocks keyboard input within 100 milliseconds of detecting a cat pattern.
- **SC-004**: Users can see the notification popup within 500 milliseconds of keyboard lock activating.
- **SC-005**: System automatically unlocks within one re-check interval (default 2 seconds) after all keys are released.
- **SC-006**: Normal typing workflow is unaffected when no cat is present (zero false positives during standard typing sessions).
- **SC-007**: Users report the feature successfully prevents unwanted cat-caused input in 90% of real-world usage scenarios.

## Assumptions

- The app has system-level keyboard monitoring permissions (Accessibility permissions on macOS).
- The app is running as a menu bar application as defined in the existing project structure.
- A standard QWERTY keyboard layout is used for adjacency mapping (can be extended to other layouts in future iterations).
- The re-check interval of 2 seconds provides a good balance between responsiveness and avoiding premature unlocks.
- Users understand they can manually unlock via the menu bar if needed.
- The popup uses a system-level overlay mechanism that works across all applications including full-screen mode.
