# Research: Permissions & Settings Enhancements

**Feature**: 005-permissions-settings-enhancements
**Date**: 2026-01-19

## Research Tasks

### 1. Accessibility Permission API (macOS)

**Question**: How to check and request Accessibility permission in macOS?

**Findings**:
- **API**: `AXIsProcessTrusted()` from ApplicationServices framework
- **Header**: `#import <ApplicationServices/ApplicationServices.h>` or use CoreGraphics
- **Swift Usage**: Direct C function call, returns `Bool`
- **Polling**: Safe to call repeatedly; no performance concerns at 1-second intervals
- **Deep Link**: `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`

**Decision**: Use `AXIsProcessTrusted()` for Accessibility permission checking, mirroring the existing `CGPreflightListenEventAccess()` pattern for Input Monitoring.

**Rationale**: Standard macOS API used by all apps requiring Accessibility permission. No alternatives exist.

### 2. Input Monitoring vs Accessibility Permissions

**Question**: What's the difference and do we need both?

**Findings**:
- **Input Monitoring** (`com.apple.security.device.input-monitoring`): Required for `CGEvent` tap to receive keyboard events
- **Accessibility** (`com.apple.security.device.accessibility`): Required for `AXIsProcessTrusted()` and some event manipulation
- **CatPaws Usage**: Currently uses Input Monitoring for `CGPreflightListenEventAccess()` and event tap
- **Requirement Analysis**: The app needs Input Monitoring to receive events; Accessibility is checked but not strictly required for current functionality

**Decision**: Add Accessibility permission step for future-proofing (may be needed for event blocking) and to provide complete permission guidance to users.

**Rationale**: Better user experience to request all potentially-needed permissions upfront rather than surprising users later.

**Alternatives Considered**:
- Only request Input Monitoring → Rejected: May need Accessibility for full event blocking capabilities
- Request both silently → Rejected: Constitution requires clear user explanations

### 3. Onboarding Step Insertion Pattern

**Question**: How to modify `OnboardingStep` enum without breaking existing state?

**Findings**:
- Current enum uses raw Int values: `welcome=0`, `permissionExplanation=1`, `grantPermission=2`, `testDetection=3`, `complete=4`
- UserDefaults stores `currentStep` as integer
- Risk: Users mid-onboarding could have wrong step after update

**Decision**: Insert new step at raw value 2 (between `permissionExplanation=1` and current `grantPermission`), shift subsequent values:
```swift
case welcome = 0
case permissionExplanation = 1
case grantAccessibility = 2      // NEW
case grantInputMonitoring = 3    // Was: grantPermission = 2
case testDetection = 4           // Was: 3
case complete = 5                // Was: 4
```

**Rationale**: Clean insertion preserves logical flow. Migration handles edge case of users mid-onboarding.

**Migration Strategy**: On app launch, if stored step >= 2, increment by 1 (one-time migration flag in UserDefaults).

### 4. UserDefaults Reset Pattern

**Question**: Best practice for clearing all app UserDefaults?

**Findings**:
- **Option A**: `UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)`
  - Clears ALL keys including system-managed ones
  - Clean but aggressive
- **Option B**: Enumerate and remove only app-specific keys
  - More controlled
  - Requires key prefix convention
- **Option C**: Use suite-specific UserDefaults
  - Not applicable to existing codebase

**Decision**: Option A (removePersistentDomain) for complete reset, followed by re-registration of defaults.

**Rationale**: User explicitly requested "factory defaults" behavior. All current keys use `catpaws.` prefix anyway.

### 5. Non-Modal Notification Banner (Permission Revocation)

**Question**: How to implement non-modal notification in menu bar app?

**Findings**:
- **Option A**: macOS User Notifications (`UNUserNotificationCenter`)
  - System-managed display
  - Can include action button
  - Requires notification permission (ironic for a permission app)
- **Option B**: In-app banner in menu bar popover
  - No additional permission needed
  - Always visible when popover opens
  - Can include inline "Open Settings" button
- **Option C**: Floating window
  - Intrusive
  - Non-standard for menu bar apps

**Decision**: Option B - In-app banner within menu bar content view.

**Rationale**: Avoids notification permission complexity; provides immediate context when user interacts with app.

### 6. Menu Bar Dropdown Sizing

**Question**: How to ensure dropdown fits all content?

**Findings**:
- Current: Fixed frame in `MenuBarContentView`
- SwiftUI: Can use `.fixedSize()` or dynamic height with constraints
- Best practice: Set minimum size, allow dynamic expansion up to reasonable max

**Decision**: Use `.frame(minHeight: 400)` with dynamic content sizing, capped at screen-appropriate maximum.

**Rationale**: Accommodates both permission states while preventing excessive height.

### 7. Tooltip Implementation in SwiftUI

**Question**: How to show full text on hover for truncated text?

**Findings**:
- **SwiftUI**: `.help("Full text here")` modifier - native tooltip
- **Behavior**: Appears after ~1 second hover delay (system standard)
- **Accessibility**: Automatically announced by VoiceOver

**Decision**: Use `.help()` modifier on any text that may truncate.

**Rationale**: Native SwiftUI solution; no custom implementation needed.

## Summary

All research questions resolved. Key technical decisions:
1. `AXIsProcessTrusted()` for Accessibility permission checking
2. Enum migration strategy for existing onboarding users
3. `removePersistentDomain()` for complete settings reset
4. In-app banner for permission revocation notification
5. Dynamic frame sizing for menu bar dropdown
6. Native `.help()` modifier for tooltips
