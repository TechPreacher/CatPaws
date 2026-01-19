# Feature Specification: Permissions & Settings Enhancements

**Feature Branch**: `005-permissions-settings-enhancements`
**Created**: 2026-01-19
**Status**: Draft
**Input**: User description: "Add Accessibility permission onboarding step, enhanced permission status display, UI fixes for menu bar dropdown and settings window, and reset settings option"

## Clarifications

### Session 2026-01-19

- Q: Can users proceed past a permission step without granting it? → A: Yes, users can click "Continue Anyway" to proceed without granting each permission (non-blocking), matching existing Input Monitoring behavior.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Complete Onboarding with Both Permissions (Priority: P1)

As a new user, I want to be guided through granting both Accessibility and Input Monitoring permissions during onboarding so that CatPaws can function properly without me having to figure out which permissions are needed.

**Why this priority**: Without both permissions, CatPaws cannot function. This is the core onboarding flow that every new user must complete.

**Independent Test**: Launch app with fresh state, navigate through all onboarding steps, grant both permissions, verify app becomes fully functional.

**Acceptance Scenarios**:

1. **Given** I am on the onboarding permission explanation step, **When** I click Next, **Then** I see the Accessibility permission step first
2. **Given** I am on the Accessibility permission step, **When** I click "Open System Settings", **Then** the Accessibility pane opens with CatPaws listed
3. **Given** I have granted Accessibility permission, **When** I click Next, **Then** I advance to the Input Monitoring permission step
4. **Given** I am on the Input Monitoring permission step, **When** I click "Open System Settings", **Then** the Input Monitoring pane opens with CatPaws listed
5. **Given** Accessibility permission was just granted (no app restart), **When** the onboarding UI updates, **Then** the step shows "Permission Granted!" status immediately

---

### User Story 2 - View Permission Status in Menu Bar (Priority: P1)

As a user who hasn't granted all permissions, I want to see clearly which permissions are missing in the menu bar dropdown so that I know exactly what I need to enable.

**Why this priority**: Users need clear guidance on missing permissions to complete setup. Without this, they may be confused about why the app isn't working.

**Independent Test**: Revoke one or both permissions in System Settings, click menu bar icon, verify permission status display shows correct state for each permission.

**Acceptance Scenarios**:

1. **Given** Accessibility is not granted but Input Monitoring is granted, **When** I click the menu bar icon, **Then** I see Accessibility marked as "Needs Permission" and Input Monitoring marked as "OK"
2. **Given** Input Monitoring is not granted but Accessibility is granted, **When** I click the menu bar icon, **Then** I see Input Monitoring marked as "Needs Permission" and Accessibility marked as "OK"
3. **Given** both permissions are not granted, **When** I click the menu bar icon, **Then** I see both permissions marked as "Needs Permission"
4. **Given** both permissions are granted, **When** I click the menu bar icon, **Then** the permission guide is not shown (normal app interface displayed)

---

### User Story 3 - Menu Bar Dropdown Displays All Content (Priority: P2)

As a user, I want the menu bar dropdown to be tall enough to display all content without cropping so that I can read all information and instructions.

**Why this priority**: UI usability issue that affects comprehension but doesn't block core functionality.

**Independent Test**: Open menu bar dropdown in various permission states, verify all text is fully visible without scrolling or cropping.

**Acceptance Scenarios**:

1. **Given** I am missing permissions, **When** I open the menu bar dropdown, **Then** all permission status text and buttons are fully visible
2. **Given** the permission guide is showing both permission statuses, **When** I view the dropdown, **Then** no text is cropped or cut off
3. **Given** I scroll within the dropdown (if needed), **When** content extends beyond initial view, **Then** scrolling works smoothly

---

### User Story 4 - Access All Settings Content (Priority: P2)

As a user, I want the settings window to be large enough to display all settings options so that I can see and configure all available options.

**Why this priority**: UI usability issue that prevents users from accessing all settings, but existing settings still function.

**Independent Test**: Open Settings window, verify all setting controls are visible and accessible without cropping.

**Acceptance Scenarios**:

1. **Given** I open the Settings window, **When** it appears, **Then** all settings are visible without scrolling or cropping
2. **Given** all settings are displayed, **When** I interact with any setting, **Then** the control is fully accessible and functional

---

### User Story 5 - Reset All App Settings (Priority: P3)

As a user, I want to reset all app settings to defaults from within the app so that I can start fresh without using terminal commands.

**Why this priority**: Nice-to-have feature for troubleshooting; users can alternatively reinstall or use terminal commands.

**Independent Test**: Change some settings, use reset option, verify all settings return to defaults and onboarding state is cleared.

**Acceptance Scenarios**:

1. **Given** I have modified various settings, **When** I click "Reset All Settings", **Then** I see a confirmation dialog warning that this will clear all data
2. **Given** I confirm the reset action, **When** the reset completes, **Then** all settings return to their default values
3. **Given** I have completed onboarding, **When** I reset all settings, **Then** the onboarding completed state is also cleared
4. **Given** I reset all settings, **When** I restart the app, **Then** the onboarding flow appears again as if it's a fresh install

---

### Edge Cases

- What happens when user grants Accessibility but revokes it before completing onboarding?
- What happens when user has Input Monitoring but not Accessibility after a system update?
- How does the app handle permission being revoked while the app is running?
- What happens if user clicks "Reset All Settings" while onboarding is in progress?
- How does the dropdown handle extremely long system-generated text or localized strings?

## Requirements *(mandatory)*

### Functional Requirements

**Onboarding Permissions Flow**:
- **FR-001**: System MUST include an Accessibility permission step in the onboarding flow before the Input Monitoring step
- **FR-002**: System MUST detect Accessibility permission status without requiring an app restart
- **FR-003**: System MUST provide a button to open System Settings directly to the Accessibility pane
- **FR-004**: System MUST update the permission status display when Accessibility permission is granted (no restart needed)
- **FR-005**: System MUST maintain the existing Input Monitoring permission step after the Accessibility step

**Menu Bar Permission Display**:
- **FR-006**: System MUST display individual status for both Accessibility and Input Monitoring permissions in the menu bar dropdown
- **FR-007**: System MUST show which specific permissions are granted ("OK" status) and which need attention ("Needs Permission" status)
- **FR-008**: System MUST provide "Open System Settings" buttons for each missing permission that opens the correct settings pane
- **FR-009**: System MUST show the permission guide view when either or both permissions are missing
- **FR-010**: System MUST hide the permission guide view when both permissions are granted

**UI Size Fixes**:
- **FR-011**: System MUST size the menu bar dropdown to accommodate all permission status content without text cropping
- **FR-012**: System MUST size the Settings window to display all settings controls without requiring scrolling or cropping

**Reset Settings**:
- **FR-013**: System MUST provide a "Reset All Settings" option in the Settings window
- **FR-014**: System MUST show a confirmation dialog before resetting settings
- **FR-015**: System MUST clear all stored preferences when reset is confirmed (equivalent to clearing app defaults)
- **FR-016**: System MUST clear the onboarding completed state when reset is performed

### Key Entities

- **Permission Status**: Represents the state of a specific system permission (Accessibility or Input Monitoring) - granted or not granted
- **App Settings**: User-configurable options stored in the app's preferences (detection sensitivity, cooldown duration, etc.)
- **Onboarding State**: Tracks whether onboarding has been completed and which step the user is on

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete the full onboarding flow including both permission grants in under 5 minutes
- **SC-002**: 100% of permission status text is visible without cropping in the menu bar dropdown
- **SC-003**: 100% of settings controls are visible and accessible in the Settings window without scrolling
- **SC-004**: Users can identify which specific permissions are missing within 3 seconds of opening the menu bar dropdown
- **SC-005**: Reset settings action returns app to factory defaults with 100% of stored preferences cleared
- **SC-006**: Accessibility permission status updates within 2 seconds of being granted (no app restart required)

## Assumptions

- The app already has the necessary entitlements to request both Accessibility and Input Monitoring permissions
- Users understand the distinction between Accessibility and Input Monitoring permissions in macOS
- The existing permission polling mechanism can be extended to check Accessibility permission status
- The confirmation dialog for reset settings follows standard macOS design patterns
