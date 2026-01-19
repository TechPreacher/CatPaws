# Feature Specification: Onboarding UI Fixes

**Feature Branch**: `004-onboarding-ui-fixes`
**Created**: 2026-01-19
**Status**: Draft
**Input**: User description: "Fix onboarding UI issues: window height, permission listing, text overflow, test key pattern, and quit option in permission-required menu"

## Clarifications

### Session 2026-01-19

- Q: Which specific keys should be displayed for the test key pattern? → A: S-E-D (triangular cluster, center-left)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Complete Onboarding Flow Without UI Issues (Priority: P1)

A new user launches CatPaws for the first time and navigates through the onboarding experience. All content is fully visible, instructions are complete, and the user can successfully set up the app.

**Why this priority**: The onboarding flow is the user's first impression of the app. UI issues during onboarding create confusion and may cause users to abandon setup before the app is functional.

**Independent Test**: Can be fully tested by launching the app with a fresh state and navigating through all onboarding steps, verifying all text is visible and all buttons are accessible.

**Acceptance Scenarios**:

1. **Given** a user on onboarding step 2 (Permission Explanation), **When** the window is displayed, **Then** all content including title, description, and buttons is fully visible without scrolling or clipping.
2. **Given** a user on onboarding step 4 (Test Detection), **When** the window is displayed, **Then** all instructional text is fully visible without truncation or overflow.
3. **Given** a user on onboarding step 4 (Test Detection), **When** the user sees the test key pattern, **Then** the pattern displays the keys "S", "E", "D" forming a triangular cat-paw cluster rather than a horizontal row.

---

### User Story 2 - Grant Accessibility Permission Successfully (Priority: P1)

A user on the permission granting step clicks "Open System Settings" and is taken to the correct location where they can find and enable CatPaws in the Input Monitoring list.

**Why this priority**: Without proper accessibility permissions, the core cat-detection functionality cannot work. Users must be able to successfully grant this permission.

**Independent Test**: Can be tested by clicking "Open System Settings" on step 3 and verifying CatPaws appears in the Input Monitoring list.

**Acceptance Scenarios**:

1. **Given** a user on onboarding step 3 (Grant Permission), **When** the user clicks "Open System Settings", **Then** System Settings opens to Privacy & Security > Input Monitoring.
2. **Given** the user is viewing Input Monitoring settings, **When** the user looks for CatPaws, **Then** CatPaws is listed as an app that can be granted permission.

---

### User Story 3 - Exit App When Permission Not Granted (Priority: P2)

A user who has not granted accessibility permission and sees the "Permission Required" dropdown in the menu bar wants to quit the app rather than grant permission at this time.

**Why this priority**: Users should always have a clear way to exit the application. Currently, users without permission may feel trapped if they cannot find a quit option.

**Independent Test**: Can be tested by launching the app without accessibility permission and verifying a "Quit" option appears in the menu bar dropdown.

**Acceptance Scenarios**:

1. **Given** a user has launched CatPaws without accessibility permission, **When** the user clicks the menu bar icon, **Then** the dropdown includes a "Quit" option alongside the permission-related content.
2. **Given** the permission-required dropdown is showing with a "Quit" option, **When** the user clicks "Quit", **Then** the application terminates.

---

### Edge Cases

- What happens if the onboarding window is displayed on a very small screen? The window should have a minimum size but content should remain readable.
- What happens if the user resizes the onboarding window (if resizable)? Content should adapt gracefully.
- What happens if CatPaws is not registered for Input Monitoring at the OS level? The app should still open System Settings to the correct location, allowing the user to manually add it via the "+" button.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Onboarding step 2 (Permission Explanation) window MUST be tall enough to display all content without clipping or scrolling.
- **FR-002**: Onboarding step 4 (Test Detection) MUST display complete instructional text without truncation or overflow.
- **FR-003**: Onboarding step 4 MUST display the test key pattern "S-E-D" (triangular cluster) rather than a horizontal row (like A-S-D-F).
- **FR-004**: The "Open System Settings" button on step 3 MUST open System Settings to the correct Input Monitoring privacy pane.
- **FR-005**: CatPaws MUST be listed in System Settings > Privacy & Security > Input Monitoring after the app has been launched.
- **FR-006**: The menu bar dropdown shown when permission is not granted MUST include a "Quit CatPaws" option.
- **FR-007**: The "Quit" option in the permission-required dropdown MUST terminate the application when clicked.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of onboarding step content is visible without scrolling when the window is displayed at its default size.
- **SC-002**: Users can read complete instructions on all onboarding steps without text being cut off or requiring horizontal scrolling.
- **SC-003**: The test key pattern on step 4 displays "S-E-D" in a triangular arrangement representing a realistic cat-paw cluster.
- **SC-004**: CatPaws appears in Input Monitoring settings after first launch, allowing users to grant permission without manual app addition.
- **SC-005**: Users can quit the app from any state using the menu bar, including when permission has not been granted.

## Assumptions

- The onboarding window has a fixed or minimum size that can accommodate the required content height adjustments.
- The app properly registers itself for Input Monitoring entitlement during build/signing.
- The test key pattern change (from ASDF to S-E-D) does not require changes to the underlying detection logic, only the UI display.
- The permission-required menu bar state is a distinct view/state that can be modified independently.
