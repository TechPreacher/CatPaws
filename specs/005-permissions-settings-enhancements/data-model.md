# Data Model: Permissions & Settings Enhancements

**Feature**: 005-permissions-settings-enhancements
**Date**: 2026-01-19

## Entities

### 1. OnboardingStep (Enum - Modified)

**Purpose**: Represents steps in the first-run onboarding flow.

| Value | Raw | Description |
|-------|-----|-------------|
| welcome | 0 | Initial welcome screen |
| permissionExplanation | 1 | Why permissions are needed |
| **grantAccessibility** | **2** | **NEW: Request Accessibility permission** |
| grantInputMonitoring | 3 | Request Input Monitoring permission (renamed from grantPermission) |
| testDetection | 4 | Test cat detection |
| complete | 5 | Onboarding finished |

**Migration**: One-time migration for users with persisted step >= 2: increment stored value by 1.

### 2. PermissionStatus (New Struct)

**Purpose**: Represents the state of a single system permission.

```swift
struct PermissionStatus {
    let type: PermissionType
    let isGranted: Bool
    let settingsURL: URL
    
    var displayName: String { type.displayName }
    var statusText: String { isGranted ? "OK" : "Needs Permission" }
}

enum PermissionType: String, CaseIterable {
    case accessibility
    case inputMonitoring
    
    var displayName: String {
        switch self {
        case .accessibility: return "Accessibility"
        case .inputMonitoring: return "Input Monitoring"
        }
    }
    
    var settingsURL: URL {
        switch self {
        case .accessibility:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        case .inputMonitoring:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
        }
    }
}
```

### 3. PermissionState (New Observable)

**Purpose**: Tracks current state of both permissions, published for UI binding.

```swift
@Observable
final class PermissionState {
    var accessibility: PermissionStatus
    var inputMonitoring: PermissionStatus
    
    var allGranted: Bool { accessibility.isGranted && inputMonitoring.isGranted }
    var anyMissing: Bool { !allGranted }
}
```

### 4. Configuration (Modified)

**Changes**: Add `resetAll()` method.

```swift
extension Configuration {
    /// Resets all settings to factory defaults
    func resetAll() {
        guard let bundleId = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: bundleId)
        registerDefaults()  // Re-register default values
    }
}
```

### 5. OnboardingState (Modified)

**Changes**: Add migration support and reset method.

```swift
extension OnboardingState {
    private static let migrationKey = "catpaws.onboarding.v2Migration"
    
    /// Migrates step values for users who were mid-onboarding during update
    static func migrateIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migrationKey) else { return }
        
        let currentRaw = defaults.integer(forKey: currentStepKey)
        if currentRaw >= 2 {
            defaults.set(currentRaw + 1, forKey: currentStepKey)
        }
        defaults.set(true, forKey: migrationKey)
    }
    
    /// Clears all onboarding state (for reset)
    mutating func reset() {
        UserDefaults.standard.removeObject(forKey: Self.completedKey)
        UserDefaults.standard.removeObject(forKey: Self.skippedKey)
        UserDefaults.standard.removeObject(forKey: Self.currentStepKey)
    }
}
```

## State Relationships

```text
┌─────────────────────────────────────────────────────────────────┐
│                         AppViewModel                             │
├─────────────────────────────────────────────────────────────────┤
│  @Published permissionState: PermissionState                     │
│  @Published showPermissionRevokedBanner: Bool                    │
│                                                                  │
│  ┌──────────────────┐    ┌───────────────────────────────────┐  │
│  │ PermissionState  │◄───│ PermissionService (1s polling)    │  │
│  │  .accessibility  │    │  - checkAccessibility()           │  │
│  │  .inputMonitoring│    │  - checkInputMonitoring()         │  │
│  └──────────────────┘    └───────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                      OnboardingViewModel                         │
├─────────────────────────────────────────────────────────────────┤
│  @Published currentStep: OnboardingStep                          │
│  @Published hasAccessibility: Bool                               │
│  @Published hasInputMonitoring: Bool                             │
│                                                                  │
│  Steps: welcome → explanation → accessibility → inputMonitoring  │
│         → testDetection → complete                               │
└─────────────────────────────────────────────────────────────────┘
```

## UserDefaults Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| catpaws.onboarding.completed | Bool | false | Onboarding finished |
| catpaws.onboarding.skipped | Bool | false | User skipped onboarding |
| catpaws.onboarding.currentStep | Int | 0 | Current step raw value |
| catpaws.onboarding.v2Migration | Bool | false | Migration flag for step shift |
| catpaws.isEnabled | Bool | true | App protection enabled |
| catpaws.debounceMs | Int | 300 | Detection debounce |
| catpaws.recheckIntervalSec | Double | 2.0 | Auto-unlock check interval |
| catpaws.cooldownSec | Double | 7.0 | Cooldown after unlock |
| catpaws.minimumKeyCount | Int | 3 | Keys to trigger detection |
| catpaws.playSoundOnLock | Bool | true | Audio feedback on lock |
| catpaws.playSoundOnUnlock | Bool | true | Audio feedback on unlock |
| catpaws.launchAtLogin | Bool | false | Launch at login |
| catpaws.debugLogging | Bool | false | Enable debug logs |

## Validation Rules

1. **OnboardingStep**: Must be valid enum case (0-5); invalid values default to `.welcome`
2. **PermissionStatus**: Read-only from system APIs; cannot be set programmatically
3. **Reset**: Must show confirmation before execution; disabled during onboarding
