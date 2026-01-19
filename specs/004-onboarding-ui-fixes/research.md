# Research: Onboarding UI Fixes

**Branch**: `004-onboarding-ui-fixes` | **Date**: 2026-01-19

## Research Topics

### 1. Window Height for Step 2 (Permission Explanation)

**Problem**: The current window height of 400pt is insufficient for the PermissionExplanationStepView content, which includes:
- 64pt icon
- Title text
- Multi-line description
- Three PermissionInfoRow items in a padded container
- Spacers

**Decision**: Increase onboarding window height from 400pt to 500pt.

**Rationale**:
- Current content in PermissionExplanationStepView requires approximately 450-480pt
- Adding 100pt buffer ensures content is visible with room for padding
- Must update both `AppDelegate.swift` (NSWindow creation) and `OnboardingView.swift` (.frame modifier)

**Alternatives Considered**:
- Dynamic height based on step: Rejected - adds complexity, inconsistent user experience
- Scrollable content: Rejected - poor UX for onboarding, content should always be visible
- Reduce font sizes/spacing: Rejected - would compromise readability

---

### 2. CatPaws Not Listed in Input Monitoring

**Problem**: After launching CatPaws, it does not appear in System Settings > Privacy & Security > Input Monitoring.

**Decision**: The app must actually attempt to access keyboard events to be added to the Input Monitoring list. This is macOS behavior - apps are only added when they first request event monitoring.

**Rationale**:
- macOS Input Monitoring list only shows apps that have *attempted* to monitor input
- The app has the entitlement (`com.apple.security.device.input-monitoring`) and usage description (`NSInputMonitoringUsageDescription`)
- The app must call `CGEvent.tapCreate()` or similar API to trigger the permission prompt and be added to the list
- Current implementation may defer event tap creation until after onboarding

**Implementation Approach**:
1. Verify the app attempts to create an event tap on launch (before permission check)
2. If not, add a check during onboarding step 3 that triggers the permission request
3. The `AXIsProcessTrusted()` check alone is insufficient - must attempt event monitoring

**Alternatives Considered**:
- Manual instruction for users to add via "+": Poor UX, error-prone
- Skip this verification: Would leave users confused during onboarding

---

### 3. Text Overflow on Step 4 (Test Detection)

**Problem**: The instruction text "Let's make sure CatPaws is working correctly. Press these four keys t..." is being truncated.

**Decision**: Add `.fixedSize(horizontal: false, vertical: true)` to the instruction text and potentially adjust spacing.

**Rationale**:
- The text lacks the fixedSize modifier that other steps have
- Line 307-310 in OnboardingView.swift does not have this modifier applied
- Other steps (Welcome, Permission Explanation) correctly use this modifier

**Implementation Approach**:
1. Add `.fixedSize(horizontal: false, vertical: true)` to the instruction Text view in TestDetectionStepView
2. Verify text displays fully: "Let's make sure CatPaws is working correctly. Press these four keys together:"

**Alternatives Considered**:
- Shorter text: Would lose clarity
- Smaller font: Would reduce readability

---

### 4. Test Key Pattern Change (ASDF → S-E-D)

**Problem**: The current test pattern "A-S-D-F" is a horizontal row that doesn't represent how a cat paw would press keys.

**Decision**: Change to "S-E-D" in a triangular arrangement representing a realistic cat-paw cluster.

**Rationale**:
- Cat paws press keys in clustered patterns, not horizontal rows
- S-E-D forms a triangular cluster:
  ```
      [E]
    [S] [D]
  ```
- This matches the app's actual detection algorithm (adjacent keys in clusters)
- Three keys is sufficient to trigger detection

**Implementation Approach**:
1. Replace the current HStack with 4 KeyCapViews (A, S, D, F) with a triangular layout
2. Use VStack + HStack combination:
   ```swift
   VStack(spacing: 8) {
       KeyCapView(letter: "E")
       HStack(spacing: 8) {
           KeyCapView(letter: "S")
           KeyCapView(letter: "D")
       }
   }
   ```
3. Update instruction text to reference "three keys" instead of "four keys"

**Alternatives Considered**:
- A-Q-W: Valid triangular cluster, but S-E-D is more central on keyboard
- Keep four keys in diamond: More complex layout, three keys sufficient for demo

---

### 5. Quit Option in Permission-Required Menu Bar Dropdown

**Problem**: When permission is not granted, the menu bar dropdown shows the PermissionGuideView but lacks a way to quit the application.

**Decision**: Add a "Quit CatPaws" button to the PermissionGuideView or ensure it's visible in MenuBarContentView when permission is missing.

**Rationale**:
- Looking at MenuBarContentView.swift, the Quit button is in the footer (lines 106-110)
- However, the PermissionGuideView at 200pt height may push the footer off-screen
- The calculateHeight() returns 380pt when permission is not granted (180 base + 200 permission guide)
- The fixed frame width of 280pt constrains horizontal space

**Implementation Approach**:
1. Review the menu bar popover height to ensure footer with Quit is visible
2. OR add a dedicated "Quit" button to PermissionGuideView itself for clarity
3. Best option: Add Quit button directly to PermissionGuideView below the "Open System Settings" button

**Alternatives Considered**:
- Keyboard shortcut only (Cmd+Q): Users may not discover it
- Reduce PermissionGuideView size: Would compromise clarity of instructions

---

## Summary of Changes

| Issue | File | Change |
|-------|------|--------|
| Window height | `AppDelegate.swift`, `OnboardingView.swift` | 400pt → 500pt |
| CatPaws not in list | Verify event tap creation on launch | May need timing adjustment |
| Text overflow | `OnboardingView.swift` | Add `.fixedSize()` modifier |
| Test key pattern | `OnboardingView.swift` | ASDF → S-E-D triangular layout |
| Quit option | `PermissionGuideView.swift` | Add "Quit CatPaws" button |
