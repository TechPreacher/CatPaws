# Quickstart: Permissions & Settings Enhancements

**Feature**: 005-permissions-settings-enhancements
**Date**: 2026-01-19

## Overview

This feature adds Accessibility permission to the onboarding flow, displays individual permission status in the menu bar, fixes UI sizing issues, and provides a settings reset option.

## Key Files to Modify

| File | Changes |
|------|---------|
| `Models/OnboardingState.swift` | Add `grantAccessibility` step, migration logic |
| `ViewModels/OnboardingViewModel.swift` | Dual permission polling, step handling |
| `Views/OnboardingView.swift` | New Accessibility permission step UI |
| `Views/PermissionGuideView.swift` | Individual permission status display |
| `Views/SettingsView.swift` | Reset button, fix frame sizing |
| `MenuBar/MenuBarContentView.swift` | Adjust dropdown height |
| `Models/Configuration.swift` | Add `resetAll()` method |
| **NEW** `Services/PermissionService.swift` | Unified permission checking |

## Implementation Order

### Phase 1: Core Infrastructure
1. Create `PermissionService.swift` with `AXIsProcessTrusted()` and `CGPreflightListenEventAccess()`
2. Add `PermissionType` enum and `PermissionStatus` struct
3. Update `OnboardingStep` enum with new case and migration

### Phase 2: Onboarding Flow
4. Update `OnboardingViewModel` for dual permission handling
5. Create Accessibility permission step UI in `OnboardingView`
6. Update navigation logic for new step sequence

### Phase 3: Menu Bar & Permissions Display
7. Update `PermissionGuideView` for individual permission status
8. Add permission revocation banner to `MenuBarContentView`
9. Fix dropdown sizing with dynamic height

### Phase 4: Settings & Reset
10. Add `resetAll()` to `Configuration`
11. Add reset button with confirmation to `SettingsView`
12. Fix settings window sizing

### Phase 5: Polish & Tests
13. Add tooltips for truncated text (`.help()` modifier)
14. Write unit tests for `PermissionService`
15. Write tests for `Configuration.resetAll()`
16. Update onboarding tests for new step

## Quick Code Snippets

### Check Accessibility Permission
```swift
import ApplicationServices

func checkAccessibility() -> Bool {
    AXIsProcessTrusted()
}
```

### Open Accessibility Settings
```swift
let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
NSWorkspace.shared.open(url)
```

### Reset All Settings
```swift
func resetAll() {
    guard let bundleId = Bundle.main.bundleIdentifier else { return }
    UserDefaults.standard.removePersistentDomain(forName: bundleId)
    registerDefaults()
}
```

### Dynamic Dropdown Height
```swift
VStack { /* content */ }
    .frame(minWidth: 300, minHeight: 400)
    .fixedSize(horizontal: false, vertical: true)
```

## Testing Checklist

- [ ] Fresh install shows Accessibility step before Input Monitoring
- [ ] Granting Accessibility updates UI within 1-2 seconds
- [ ] Menu bar shows individual status for both permissions
- [ ] Revoking permission shows notification banner
- [ ] Reset clears all settings and onboarding state
- [ ] Reset is disabled during onboarding
- [ ] All text visible without cropping in dropdown
- [ ] Truncated text shows full content on hover

## Dependencies

- **macOS 14+**: Required for SwiftUI features
- **ApplicationServices**: For `AXIsProcessTrusted()`
- **CoreGraphics**: For `CGPreflightListenEventAccess()`
- **AppKit**: For `NSWorkspace.shared.open()`
