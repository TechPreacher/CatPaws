# Quickstart & Validation: CatPaws App Polish & Improvements

**Feature**: 003-app-polish-improvements
**Date**: 2026-01-17

## Prerequisites

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Swift 5.9+
- SwiftLint installed (via Homebrew: `brew install swiftlint`)

## Build & Run

```bash
# Navigate to project
cd CatPaws/CatPaws

# Open in Xcode
open CatPaws.xcodeproj

# Build (Cmd+B) and Run (Cmd+R)
```

---

## Validation Scenarios

### User Story 1: Launch at Login

**Setup**: None (clean state)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Launch CatPaws | Menu bar icon appears |
| 2 | Open Settings (click menu bar → Settings) | Settings window opens |
| 3 | Toggle "Launch at Login" ON | No immediate visible change |
| 4 | Open System Settings → General → Login Items | CatPaws appears in the list |
| 5 | Log out and log back in | CatPaws launches automatically |
| 6 | Toggle "Launch at Login" OFF | - |
| 7 | Check System Settings → Login Items | CatPaws removed from list |

**Edge Case**: Launch CatPaws twice manually → second instance should quit immediately

---

### User Story 2: Permission Denial Handling

**Setup**: Remove CatPaws from System Settings → Privacy & Security → Input Monitoring

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Launch CatPaws (without permission) | Permission guidance view appears |
| 2 | Read the guidance text | Clear explanation of why permission needed |
| 3 | Click "Open System Settings" | System Settings opens directly to Input Monitoring pane |
| 4 | Enable CatPaws in Input Monitoring | App detects permission (may require restart) |
| 5 | Verify protection works | Press A+S+D+F → lock triggers |

**Edge Case**: Revoke permission while app running → guidance view appears, monitoring stops

---

### User Story 3: First-Run Onboarding

**Setup**: Clear preferences: `defaults delete com.yourcompany.CatPaws`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Launch CatPaws (first time) | Onboarding window appears |
| 2 | Read welcome screen | App purpose explained |
| 3 | Click "Next" | Permission explanation shown |
| 4 | Click "Grant Permission" | System Settings opens to Input Monitoring |
| 5 | Grant permission, return to app | Onboarding shows "Test Detection" step |
| 6 | Press A+S+D+F together | Lock popup appears, confirming it works |
| 7 | Complete onboarding | Main app ready |
| 8 | Quit and relaunch | Onboarding does NOT appear again |

**Edge Case**: Click "Skip" at any point → onboarding closes, app usable but user may miss setup

---

### User Story 4: Statistics Dashboard

**Setup**: App running with permission granted

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click menu bar icon | Popover shows statistics: "0 blocks today" |
| 2 | Trigger cat detection (A+S+D+F) | Lock popup appears |
| 3 | Dismiss popup, click menu bar | "1 block today" shown |
| 4 | Trigger 2 more detections | "3 blocks today" shown |
| 5 | Click statistics area | Detailed view: today, week, all-time |
| 6 | Open Settings → Reset Statistics | Counters reset to 0 |

**Edge Case**: Leave app running overnight → "today" count resets at midnight

---

### User Story 5: Keyboard Layout Support

**Setup**: Have multiple keyboard layouts configured

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set keyboard to French (AZERTY) | (via menu bar input source) |
| 2 | Press adjacent AZERTY keys (Q+S+D+F) | Detection triggers (Q is where A would be on QWERTY) |
| 3 | Switch to German (QWERTZ) | - |
| 4 | Press adjacent QWERTZ keys | Detection triggers correctly |
| 5 | Switch to Dvorak | - |
| 6 | Press adjacent Dvorak keys | Detection triggers correctly |

**Verification**: The detection algorithm should use key PHYSICAL positions, not logical characters.

---

### User Story 6: Popup Multi-Monitor Support

**Setup**: Connect 2+ monitors

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Move a window to secondary monitor | Window is active on secondary |
| 2 | Trigger cat detection | Lock popup appears on SECONDARY monitor |
| 3 | Move focus back to primary monitor | - |
| 4 | Trigger cat detection | Lock popup appears on PRIMARY monitor |
| 5 | Enter full-screen app on any monitor | - |
| 6 | Trigger cat detection | Lock popup appears ABOVE full-screen app |

---

### User Story 7: Diagnostic Logging

**Setup**: None

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open Settings → Enable "Debug Logging" | Toggle turns on |
| 2 | Trigger cat detection | Lock triggers |
| 3 | Open Console.app | - |
| 4 | Filter by "com.catpaws" | Detection and lock events visible |
| 5 | Verify logs contain NO keystroke content | Only "detected X keys", not which keys |
| 6 | Disable "Debug Logging" | New events not logged |

---

### User Story 8: Custom App Icon

**Setup**: Build and install app

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | View CatPaws in Finder | Custom cat paw icon visible |
| 2 | Add CatPaws to Dock | Icon renders correctly at small size |
| 3 | Search "CatPaws" in Spotlight | App appears with custom icon |

---

## Code Quality Validation

### SwiftLint

```bash
cd CatPaws/CatPaws
swiftlint
# Expected: 0 violations
```

### Compiler Warnings

1. In Xcode, select Product → Build (Cmd+B)
2. Check Issues navigator (Cmd+5)
3. Expected: 0 warnings (with warnings-as-errors enabled)

### Test Suite

```bash
# Run from Xcode: Product → Test (Cmd+U)
# Or command line:
xcodebuild test -project CatPaws.xcodeproj -scheme CatPaws -destination 'platform=macOS'
```

Expected: All tests pass

---

## Performance Validation

### CPU Usage (SC-007)

1. Launch CatPaws
2. Open Activity Monitor
3. Let app idle for 60 seconds
4. Check CPU usage for "CatPaws"
5. Expected: < 1% average CPU

---

## Cleanup Commands

```bash
# Reset all preferences (simulates first launch)
defaults delete com.yourcompany.CatPaws

# Remove login item
SMAppService.mainApp.unregister() # (via app or debug)

# Clear statistics
# Use "Reset Statistics" in Settings UI
```
