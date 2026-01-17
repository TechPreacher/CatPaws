# Feature Specification: CatPaws App Polish & Improvements

**Feature Branch**: `003-app-polish-improvements`
**Created**: 2026-01-16
**Status**: Draft
**Input**: User description: "Improvements including launch at login, permission handling, onboarding, keyboard layout support, statistics, popup positioning, app icon, SwiftLint, logging, and performance optimization"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Launch at Login (Priority: P1)

As a user, I want CatPaws to automatically start when I log into my Mac so that my keyboard is protected from my cat without me having to remember to launch the app manually.

**Why this priority**: This is fundamental for a utility app. If users must manually launch the app each time, they will forget and lose protection when they need it most.

**Independent Test**: Toggle "Launch at Login" in Settings and restart the Mac. Verify the app starts automatically and appears in the menu bar.

**Acceptance Scenarios**:

1. **Given** the "Launch at Login" setting is enabled, **When** the user logs into macOS, **Then** CatPaws automatically launches and appears in the menu bar
2. **Given** the "Launch at Login" setting is disabled, **When** the user logs into macOS, **Then** CatPaws does not launch automatically
3. **Given** the "Launch at Login" setting is enabled, **When** the user disables the setting, **Then** CatPaws is removed from the login items list immediately

---

### User Story 2 - Permission Denial Handling (Priority: P1)

As a user who hasn't granted Input Monitoring permission, I want clear guidance on why the permission is needed and how to grant it, so that I can enable the app's protection features without frustration.

**Why this priority**: Without Input Monitoring permission, the app cannot function. A poor permission experience leads to uninstalls. This is critical for first-time user success.

**Independent Test**: Launch the app without Input Monitoring permission and verify the guidance is clear and actionable.

**Acceptance Scenarios**:

1. **Given** CatPaws is launched without Input Monitoring permission, **When** the app starts, **Then** a prominent explanation appears describing why the permission is needed
2. **Given** the permission explanation is displayed, **When** the user clicks "Open System Settings", **Then** the correct Privacy & Security pane opens directly to Input Monitoring
3. **Given** permission was previously denied, **When** the user returns to the app, **Then** the permission guidance remains visible until permission is granted
4. **Given** the user grants permission in System Settings, **When** they return to CatPaws, **Then** the app detects the new permission status and enables protection (may require app restart)

---

### User Story 3 - First-Run Onboarding (Priority: P1)

As a new user, I want a brief introduction explaining what CatPaws does and guiding me through setup, so that I understand the app's value and can configure it correctly.

**Why this priority**: First impressions determine whether users keep or uninstall an app. Without onboarding, users may not understand the permission request or how to test the app.

**Independent Test**: Delete app preferences and launch CatPaws. Verify the onboarding flow appears and guides the user through setup.

**Acceptance Scenarios**:

1. **Given** CatPaws is launched for the first time, **When** the app starts, **Then** an onboarding window appears explaining the app's purpose
2. **Given** the onboarding is shown, **When** the user progresses through it, **Then** they are guided to grant Input Monitoring permission
3. **Given** the onboarding is shown, **When** the user completes it, **Then** they are shown how to test the detection (e.g., "Press A, S, D, F together")
4. **Given** the user has completed onboarding, **When** they launch the app again, **Then** the onboarding does not appear

---

### User Story 4 - Statistics Dashboard (Priority: P2)

As a user, I want to see statistics about how many times CatPaws has protected my keyboard, so that I can appreciate the app's value and verify it's working.

**Why this priority**: Statistics provide feedback that the app is working and justify its existence. This is important for user engagement but not critical for core functionality.

**Independent Test**: Trigger several cat detections and verify the statistics update correctly.

**Acceptance Scenarios**:

1. **Given** the app is running, **When** I open the menu bar popover, **Then** I see a summary of protection statistics
2. **Given** a cat detection event occurs, **When** the keyboard is locked, **Then** the "blocks today" counter increments
3. **Given** it's a new day, **When** I check statistics, **Then** the "today" counter resets but lifetime statistics persist
4. **Given** I want more detail, **When** I click on statistics, **Then** I see a breakdown (today, this week, all-time)

---

### User Story 5 - Keyboard Layout Support (Priority: P2)

As a user with a non-QWERTY keyboard (AZERTY, QWERTZ, Dvorak), I want CatPaws to correctly detect cat paw patterns on my keyboard layout, so that the protection works accurately for me.

**Why this priority**: International users represent a significant portion of potential users. Without layout support, the app provides poor detection accuracy for them.

**Independent Test**: Switch to a non-QWERTY keyboard layout in System Settings and verify cat detection works correctly.

**Acceptance Scenarios**:

1. **Given** I use an AZERTY keyboard layout, **When** I press adjacent keys on my layout, **Then** CatPaws correctly detects them as adjacent
2. **Given** I use a QWERTZ keyboard layout, **When** a cat walks on my keyboard, **Then** the detection triggers appropriately
3. **Given** I switch keyboard layouts while the app is running, **When** the layout changes, **Then** CatPaws adapts to the new layout

---

### User Story 6 - Popup Multi-Monitor Support (Priority: P2)

As a user with multiple monitors, I want the lock notification popup to appear on the screen where I'm actively working, so that I can see and dismiss it easily.

**Why this priority**: Multi-monitor setups are common among professionals. A popup appearing on the wrong screen is frustrating and delays unlocking.

**Independent Test**: Connect multiple monitors, work on a secondary screen, trigger a lock, and verify the popup appears on the active screen.

**Acceptance Scenarios**:

1. **Given** I have multiple monitors, **When** the keyboard locks, **Then** the popup appears on the screen with the active window
2. **Given** I'm in a full-screen application, **When** the keyboard locks, **Then** the popup appears above the full-screen app
3. **Given** the popup is displayed, **When** I click the dismiss button, **Then** it dismisses correctly regardless of which screen it's on

---

### User Story 7 - Diagnostic Logging (Priority: P3)

As a user experiencing issues, I want to be able to enable diagnostic logging, so that I can provide useful information when reporting problems.

**Why this priority**: Support and debugging are essential for long-term maintenance but not for initial functionality.

**Independent Test**: Enable diagnostic logging, trigger various app behaviors, and verify logs are written.

**Acceptance Scenarios**:

1. **Given** I enable "Debug Logging" in Settings, **When** app events occur, **Then** they are logged to Console.app with the CatPaws subsystem
2. **Given** logging is enabled, **When** I look at the logs, **Then** they contain useful information without sensitive data
3. **Given** I want to report a bug, **When** I export logs, **Then** I can easily share them with support

---

### User Story 8 - Custom App Icon (Priority: P3)

As a user, I want CatPaws to have a distinctive, professional app icon, so that it looks polished and is easy to identify.

**Why this priority**: Visual polish matters for perceived quality but doesn't affect functionality.

**Independent Test**: Install the app and verify the custom icon appears in Finder, Dock, and Spotlight.

**Acceptance Scenarios**:

1. **Given** CatPaws is installed, **When** I view it in Finder or Spotlight, **Then** I see a custom cat paw icon (not a generic SF Symbol)
2. **Given** the app is in my Dock, **When** I look at it, **Then** the icon is distinctive and recognizable at small sizes

---

### Edge Cases

- What happens when the user has multiple keyboard layouts configured and switches between them?
- How does the app behave if Input Monitoring permission is revoked while the app is running?
- What happens if the app is launched both at login and manually (double instance)?
- How are statistics handled if the system clock changes (e.g., timezone travel)?
- What happens if the popup should appear but all screens are disconnected?

## Requirements *(mandatory)*

### Functional Requirements

**Launch at Login**
- **FR-001**: System MUST register/unregister the app as a login item when the setting is toggled
- **FR-002**: System MUST persist the launch-at-login preference across app updates
- **FR-003**: System MUST prevent multiple instances from running simultaneously

**Permission Handling**
- **FR-004**: System MUST display a persistent permission guidance view when Input Monitoring is not granted
- **FR-005**: System MUST provide a one-click button to open the correct System Settings pane
- **FR-006**: System MUST periodically check permission status while the guidance is displayed
- **FR-007**: System MUST gracefully handle permission being revoked during operation

**Onboarding**
- **FR-008**: System MUST display onboarding only on first launch (tracked via persistent flag)
- **FR-009**: System MUST allow users to skip onboarding at any point
- **FR-010**: System MUST include a "Test Detection" step showing users how to verify the app works

**Statistics**
- **FR-011**: System MUST track the count of detection events (lock triggers)
- **FR-012**: System MUST track statistics for today, this week, and all-time periods
- **FR-013**: System MUST persist statistics across app restarts with unlimited retention (no automatic expiration)
- **FR-014**: System MUST reset daily/weekly counters at appropriate boundaries
- **FR-015**: System MUST provide a user-accessible option to reset all statistics

**Keyboard Layout Support**
- **FR-016**: System MUST detect the current keyboard layout from the operating system
- **FR-017**: System MUST provide adjacency maps for QWERTY, AZERTY, QWERTZ, and Dvorak layouts
- **FR-018**: System MUST update the active adjacency map when the keyboard layout changes

**Popup Positioning**
- **FR-019**: System MUST display the lock popup on the screen containing the currently focused window
- **FR-020**: System MUST display the popup above full-screen applications
- **FR-021**: System MUST center the popup on the target screen

**Diagnostic Logging**
- **FR-022**: System MUST provide an option to enable/disable diagnostic logging
- **FR-023**: System MUST log significant events (detection, lock, unlock, permission changes) when enabled
- **FR-024**: System MUST NOT log keystroke content or any personally identifiable information
- **FR-025**: System MUST use the system logging facility (unified logging)

**App Icon**
- **FR-026**: App MUST have a custom icon asset for the App Icon catalog
- **FR-027**: Icon MUST be provided in all required sizes for macOS (16x16 through 1024x1024)

**Technical Debt (Code Quality)**
- **FR-028**: Project MUST integrate SwiftLint with a zero-violation policy
- **FR-029**: Project MUST configure build settings to treat warnings as errors
- **FR-030**: Project MUST remove duplicate test files and consolidate test organization

### Key Entities

- **AppStatistics**: Tracks detection events with timestamps. Attributes: total count, today count, week count, last detection date
- **KeyboardLayoutMap**: Represents key positions for a specific layout. Attributes: layout identifier, key-position mapping, adjacency data
- **OnboardingState**: Tracks onboarding completion. Attributes: has completed onboarding, current step (if in progress)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 95% of users who enable "Launch at Login" have the app running after their next login
- **SC-002**: Users can grant Input Monitoring permission within 60 seconds of seeing the guidance
- **SC-003**: 90% of first-time users complete onboarding without skipping
- **SC-004**: Statistics accurately reflect detection events with zero data loss across app restarts
- **SC-005**: Detection accuracy on supported non-QWERTY layouts matches QWERTY accuracy (within 5% variance)
- **SC-006**: Lock popup appears on the correct screen 100% of the time in multi-monitor setups
- **SC-007**: App CPU usage remains below 1% during idle monitoring
- **SC-008**: Zero SwiftLint violations in the codebase
- **SC-009**: Zero compiler warnings in release builds

## Clarifications

### Session 2026-01-16

- Q: How long should "all-time" statistics data be retained? → A: Unlimited retention (persist forever until user resets)

### Session 2026-01-17

- Q: How do users export logs for bug reports (US7-AC3)? → A: Via macOS Console.app using filter `subsystem:com.catpaws.app`. No custom export feature needed - this leverages the system's built-in unified logging capabilities.

## Assumptions

- macOS 14+ is the minimum deployment target (enables use of SMAppService for login items)
- Users have standard keyboard hardware (physical keyboards, not on-screen)
- The app icon will be created as a design asset (not generated programmatically)
- Statistics do not need cloud sync - local persistence is sufficient
- Keyboard layout detection uses the system's reported input source, not hardware detection

## Out of Scope

- Cloud sync for statistics or settings
- Support for non-Latin keyboard layouts (Japanese, Chinese, Korean IME)
- Support for custom/non-standard keyboard layouts beyond QWERTY, AZERTY, QWERTZ, Dvorak
- Automatic false positive learning/adjustment
- Battery usage optimization beyond reasonable implementation
- App Store submission process (this spec covers functionality only)
