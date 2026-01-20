# API Contract: Configuration Reset

**Feature**: 005-permissions-settings-enhancements
**Date**: 2026-01-19
**Type**: Internal Service Extension

## Method Signature

```swift
extension Configuration {
    /// Resets all app settings to factory defaults
    /// - Warning: This clears ALL UserDefaults for the app bundle
    /// - Note: Call only after user confirmation
    func resetAll()
}
```

## Behavior Contract

### Pre-conditions
- User has confirmed reset action via confirmation dialog
- App is NOT in onboarding flow (reset option disabled during onboarding)

### Post-conditions
- All `catpaws.*` UserDefaults keys removed
- Default values re-registered
- Onboarding state cleared (will show on next launch)
- Statistics reset to zero
- Login item state preserved (system-managed, not in UserDefaults)

### Side Effects
1. `UserDefaults.standard.removePersistentDomain(forName:)` called
2. `registerDefaults()` called to restore default values
3. Observers notified via `objectWillChange`

## UI Integration

```swift
// In SettingsView
Button("Reset All Settings") {
    showingResetConfirmation = true
}
.disabled(onboardingInProgress) // Disabled during onboarding

.alert("Reset All Settings?", isPresented: $showingResetConfirmation) {
    Button("Cancel", role: .cancel) {}
    Button("Reset", role: .destructive) {
        configuration.resetAll()
        // Optionally: quit and relaunch app
    }
} message: {
    Text("This will reset all settings to defaults and clear your onboarding progress. You will need to grant permissions again.")
}
```

## Keys Affected

| Key | Action | New Value |
|-----|--------|-----------|
| catpaws.onboarding.completed | Removed | false (default) |
| catpaws.onboarding.skipped | Removed | false (default) |
| catpaws.onboarding.currentStep | Removed | 0 (default) |
| catpaws.isEnabled | Removed | true (default) |
| catpaws.debounceMs | Removed | 300 (default) |
| catpaws.recheckIntervalSec | Removed | 2.0 (default) |
| catpaws.cooldownSec | Removed | 7.0 (default) |
| catpaws.minimumKeyCount | Removed | 3 (default) |
| catpaws.playSoundOnLock | Removed | true (default) |
| catpaws.playSoundOnUnlock | Removed | true (default) |
| catpaws.launchAtLogin | Removed | false (default) |
| catpaws.debugLogging | Removed | false (default) |
| catpaws.statistics.* | Removed | 0 (default) |
