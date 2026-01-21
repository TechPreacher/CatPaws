# CatPaws Privacy Policy

**Last Updated**: January 21, 2026

## Overview

CatPaws ("the App") is a macOS menu bar application designed to detect when a cat is on your keyboard and temporarily lock keyboard input to protect your work. This privacy policy explains what data the App accesses, how it is used, and your rights regarding your information.

## Summary

**CatPaws does not collect, store, transmit, or share any personal data.** All processing occurs locally on your device.

## Data We Access

### Keyboard Input Monitoring

CatPaws requires macOS Input Monitoring permission to function. This permission allows the App to:

- **Detect key press patterns** - The App monitors for simultaneous multi-key presses that indicate a cat may be on your keyboard
- **Block keyboard input** - When cat-like patterns are detected, the App temporarily prevents keystrokes from reaching applications

### What We Do NOT Do

- ❌ **We do not record keystrokes** - The App only analyzes press patterns (number of keys, adjacency, timing), not the actual characters typed
- ❌ **We do not log or store keyboard data** - No keyboard input is saved to disk or memory beyond immediate pattern detection
- ❌ **We do not transmit any data** - The App operates entirely offline with no network communication
- ❌ **We do not capture passwords or sensitive input** - The App cannot and does not distinguish or record sensitive information
- ❌ **We do not share data with third parties** - There is no data to share

## Data Storage

CatPaws stores only your **preferences and settings** locally on your device using macOS UserDefaults. This includes:

- Detection sensitivity settings
- Lock cooldown duration preferences
- Launch at login preference
- App statistics (lock count, detection events) - stored locally only

This configuration data:
- Never leaves your device
- Can be reset at any time by removing the App
- Contains no personal or identifying information

## Permissions Required

| Permission | Purpose | Data Access |
|------------|---------|-------------|
| Input Monitoring (Accessibility) | Detect cat-like keyboard patterns | Key press events (not content) |

## Third-Party Services

CatPaws does not integrate with any third-party services, analytics platforms, or advertising networks. The App contains no tracking mechanisms.

## Children's Privacy

CatPaws does not collect any personal information from anyone, including children under 13 years of age.

## Data Security

Since CatPaws does not collect or transmit data, there is no data at risk. All keyboard pattern analysis occurs in real-time in memory and is immediately discarded after processing.

## Your Rights

You have the right to:

- **Revoke permissions** at any time through macOS System Settings → Privacy & Security → Input Monitoring
- **Uninstall the App** which removes all locally stored preferences
- **Reset preferences** using: `defaults delete com.corti.CatPaws`

## Changes to This Policy

We may update this Privacy Policy from time to time. We will notify you of any changes by updating the "Last Updated" date at the top of this policy.

## Open Source

CatPaws is open source software. You can review the complete source code to verify our privacy practices at:
https://github.com/TechPreacher/CatPaws

## Contact

If you have any questions about this Privacy Policy, please contact us by opening an issue on our GitHub repository.

---

## Technical Details for App Store Review

For Apple App Store reviewers, the following technical details explain our Input Monitoring usage:

### Why Input Monitoring is Required

CatPaws detects cats on keyboards by analyzing **key press patterns**, specifically:
1. Number of simultaneously pressed keys (3+ adjacent keys suggests a paw)
2. Spatial adjacency of pressed keys
3. Duration of the press pattern (200-500ms debounce)

This requires low-level keyboard event access that only Input Monitoring permission provides.

### How Keyboard Events Are Processed

```
Keyboard Event → Pattern Analyzer → Cat Detected? → Lock/Unlock
                        ↓
              [Discarded immediately]
              [No storage or logging]
```

### Code References

- Keyboard monitoring: `Services/KeyboardMonitorService.swift`
- Pattern detection: `Services/CatDetectionService.swift`
- Key adjacency mapping: `Services/KeyboardAdjacencyMap.swift`

The App never accesses the actual character values of keystrokes—only the key codes for adjacency calculation and the count of simultaneously pressed keys.
