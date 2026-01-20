# Feature Specification: Persistent Keyboard Lock

**Feature Branch**: `006-persistent-keyboard-lock`  
**Created**: 2026-01-20  
**Status**: Draft  
**Input**: User description: "Change keyboard lock behavior to persist until user dismisses with mouse, remove timer-based unlock, and auto-enable CatPaws on app start or after onboarding"

## Clarifications

### Session 2026-01-20

- Q: Should an emergency keyboard shortcut be provided to unlock when no mouse/trackpad is available? → A: Yes, add emergency shortcut (Cmd+Option+Escape held for 2 seconds)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Persistent Lock Until Mouse Dismiss (Priority: P1)

As a user with cats, when CatPaws detects cat paw activity on my keyboard and locks it, I want the lock to remain active until I explicitly dismiss it using my mouse. This prevents the cat from accidentally dismissing the lock notification by continuing to press keys.

**Why this priority**: This is the core behavior change - the current behavior allows cats to inadvertently dismiss the lock screen by pressing more keys, defeating the purpose of keyboard protection.

**Independent Test**: Start CatPaws, trigger a cat detection (press 3+ adjacent keys), observe the lock screen appears and remains visible even when additional keys are pressed. Lock only clears when clicking the dismiss button with mouse.

**Acceptance Scenarios**:

1. **Given** CatPaws is enabled and monitoring, **When** a cat paw pattern is detected (3+ adjacent keys pressed simultaneously), **Then** the keyboard lock screen appears and keyboard input is blocked.

2. **Given** the keyboard is locked with the lock screen displayed, **When** additional keys are pressed, **Then** the lock screen remains visible and keyboard remains locked (no dismissal or re-activation cycle).

3. **Given** the keyboard is locked with the lock screen displayed, **When** the user clicks the dismiss button using the mouse, **Then** the lock screen closes and keyboard input is restored.

4. **Given** the keyboard is locked with the lock screen displayed, **When** the user moves the mouse or clicks anywhere other than dismiss, **Then** the lock screen remains visible and keyboard remains locked.

---

### User Story 2 - Remove Timer-Based Auto-Unlock (Priority: P1)

As a user, I want the keyboard lock to only be dismissed by explicit mouse action, not by any automatic timer or key-release detection. This ensures maximum protection while the lock is active.

**Why this priority**: Timer-based unlock creates unpredictable behavior and may allow cats to continue pressing keys after auto-unlock, causing unwanted input.

**Independent Test**: Trigger a lock, wait for several minutes without touching mouse - lock should persist indefinitely until mouse dismiss.

**Acceptance Scenarios**:

1. **Given** the keyboard is locked, **When** all keys are released (no keys currently pressed), **Then** the lock screen remains displayed and keyboard remains locked.

2. **Given** the keyboard is locked, **When** a timer interval elapses (any configured recheck interval), **Then** the lock screen remains displayed and no automatic unlock occurs.

3. **Given** the keyboard is locked for an extended period (5+ minutes), **When** no mouse action is taken, **Then** the lock persists indefinitely until manual mouse dismissal.

---

### User Story 3 - Auto-Enable on App Start (Priority: P2)

As a user, when I launch CatPaws (either manually or via login item), I want the cat detection monitoring to automatically be enabled without requiring me to manually toggle it on. This ensures protection is active by default.

**Why this priority**: Users install CatPaws specifically for cat protection - requiring manual activation creates friction and risk of forgetting to enable it.

**Independent Test**: Launch CatPaws fresh (or after reset), observe the monitoring is immediately active in the menu bar without any user interaction.

**Acceptance Scenarios**:

1. **Given** CatPaws is installed and has never been launched before, **When** the app is launched for the first time, **Then** monitoring should be enabled automatically after onboarding is completed or skipped.

2. **Given** CatPaws was previously running with monitoring enabled, **When** the app is quit and relaunched, **Then** monitoring should be enabled automatically on startup.

3. **Given** CatPaws was previously running with monitoring manually disabled, **When** the app is quit and relaunched, **Then** monitoring should remain disabled (respecting user's explicit choice).

---

### User Story 4 - Auto-Enable After Onboarding Completion (Priority: P2)

As a new user completing the onboarding flow, I want CatPaws monitoring to automatically be enabled when I finish onboarding so I'm immediately protected.

**Why this priority**: Completing onboarding indicates user intent to use the app - automatic enablement provides immediate value.

**Independent Test**: Complete onboarding flow, observe that monitoring is active immediately upon reaching the completion state.

**Acceptance Scenarios**:

1. **Given** the user is in the onboarding flow, **When** the user completes all onboarding steps and finishes, **Then** monitoring is automatically enabled.

2. **Given** the user is in the onboarding flow, **When** the user skips onboarding, **Then** monitoring is automatically enabled (assuming permissions are granted).

3. **Given** the user completes onboarding but permissions are not granted, **When** onboarding finishes, **Then** monitoring state reflects that it cannot start due to missing permissions (but isEnabled flag is true).

---

### Edge Cases

- What happens if the user force-quits while locked? Lock state should not persist across app restarts - app starts fresh in monitoring state.
- How does the system handle multiple displays? Lock notification should appear on the display with keyboard focus.
- What happens if mouse is disconnected while locked? User can use trackpad, touch input, or the emergency keyboard shortcut (Cmd+Option+Escape held for 2 seconds) as alternative dismiss methods.
- What if the user disables monitoring while locked? Lock should be dismissed and keyboard unlocked.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST keep the keyboard locked until the user explicitly dismisses the lock notification using a mouse click on the dismiss action.
- **FR-002**: System MUST NOT dismiss or hide the lock notification when additional keyboard input is detected while locked.
- **FR-003**: System MUST NOT automatically unlock based on key release detection (removing the "keys released" auto-unlock).
- **FR-004**: System MUST NOT automatically unlock based on any timer interval (removing recheck-based auto-unlock).
- **FR-005**: System MUST maintain the cooldown period after manual dismiss to prevent immediate re-locking if cat is still on keyboard.
- **FR-006**: System MUST enable monitoring automatically when the app starts, unless the user has explicitly disabled it previously.
- **FR-007**: System MUST enable monitoring automatically when onboarding is completed or skipped.
- **FR-008**: System MUST persist the user's explicit choice to disable monitoring (if they manually toggle it off).
- **FR-009**: System MUST continue to show visual feedback (lock notification) while locked.
- **FR-010**: System MUST continue to play sound effects (if enabled) when locking and unlocking.
- **FR-011**: System MUST provide an emergency keyboard shortcut (Cmd+Option+Escape held for 2 seconds) to unlock when mouse/trackpad is unavailable.
- **FR-012**: System MUST display the emergency keyboard shortcut (Cmd+Option+Escape) on the lock dialog so users know how to unlock without a mouse.

### Key Entities

- **LockState**: Represents the current state of the keyboard lock system (monitoring, debouncing, locked, cooldown). Modified to remove auto-unlock transitions.
- **LockStateManager**: Manages lock state transitions and timers. Modified to remove recheck/auto-unlock timer logic.
- **Configuration**: Stores user preferences including isEnabled state. Modified to track explicit user disable vs. default state.
- **AppState**: Represents whether the app is actively monitoring. Auto-enabled on startup/onboarding completion.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can dismiss the lock notification only via mouse interaction or emergency keyboard shortcut (Cmd+Option+Escape held for 2 seconds), with 100% reliability.
- **SC-002**: Lock screen remains visible indefinitely when locked, regardless of keyboard activity or time elapsed.
- **SC-003**: New users have monitoring enabled within 2 seconds of completing onboarding.
- **SC-004**: Existing users have monitoring enabled within 2 seconds of app launch (if not explicitly disabled).
- **SC-005**: Users who explicitly disabled monitoring have their preference preserved across app restarts.
- **SC-006**: Zero instances of automatic unlock without user mouse interaction (excluding app quit/disable scenarios).
