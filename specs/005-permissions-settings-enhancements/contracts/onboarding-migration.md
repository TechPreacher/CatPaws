# API Contract: OnboardingStep Migration

**Feature**: 005-permissions-settings-enhancements
**Date**: 2026-01-19
**Type**: Data Migration

## Migration Purpose

Insert new `grantAccessibility` step at position 2, shifting subsequent steps.

## Before/After Mapping

| Step Name | Old Raw Value | New Raw Value |
|-----------|---------------|---------------|
| welcome | 0 | 0 |
| permissionExplanation | 1 | 1 |
| **grantAccessibility** | N/A | **2** (NEW) |
| grantPermission → grantInputMonitoring | 2 | 3 |
| testDetection | 3 | 4 |
| complete | 4 | 5 |

## Migration Logic

```swift
extension OnboardingState {
    private static let migrationKey = "catpaws.onboarding.v2Migration"
    
    /// Call once at app launch, before accessing currentStep
    static func migrateIfNeeded() {
        let defaults = UserDefaults.standard
        
        // Skip if already migrated
        guard !defaults.bool(forKey: migrationKey) else { return }
        
        // Get current stored step
        let storedStep = defaults.integer(forKey: currentStepKey)
        
        // If user was on grantPermission (2), testDetection (3), or complete (4),
        // increment to account for new step insertion
        if storedStep >= 2 {
            defaults.set(storedStep + 1, forKey: currentStepKey)
        }
        
        // Mark migration complete
        defaults.set(true, forKey: migrationKey)
    }
}
```

## Execution Point

```swift
// In AppDelegate or CatPawsApp init
@main
struct CatPawsApp: App {
    init() {
        OnboardingState.migrateIfNeeded()
    }
    // ...
}
```

## Edge Cases

| Scenario | Stored Value | Action | Result |
|----------|--------------|--------|--------|
| Fresh install | 0 (default) | No change | Starts at welcome |
| User on welcome | 0 | No change | Stays at welcome |
| User on explanation | 1 | No change | Stays at explanation |
| User on old grantPermission | 2 | +1 | Now at grantInputMonitoring (3) |
| User on old testDetection | 3 | +1 | Now at testDetection (4) |
| User completed | 4 | +1 | Now at complete (5) |
| Already migrated | Any | Skip | No change |

## Rollback Strategy

Not applicable - forward-only migration. The migration flag prevents re-execution.
