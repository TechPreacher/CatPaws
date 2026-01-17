# Data Model: CatPaws App Polish & Improvements

**Feature**: 003-app-polish-improvements
**Date**: 2026-01-17

## Entity Overview

This feature introduces 3 new data entities and extends 1 existing entity.

```
┌─────────────────┐     ┌─────────────────┐
│  AppStatistics  │     │ OnboardingState │
│  (UserDefaults) │     │  (UserDefaults) │
└─────────────────┘     └─────────────────┘

┌─────────────────────────────────────────────────┐
│           KeyboardLayoutMap (Memory)             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────┐ │
│  │  QWERTY  │ │  AZERTY  │ │  QWERTZ  │ │Dvork│ │
│  └──────────┘ └──────────┘ └──────────┘ └─────┘ │
└─────────────────────────────────────────────────┘

┌─────────────────┐
│  Configuration  │  ← Extended with new keys
│  (UserDefaults) │
└─────────────────┘
```

---

## New Entities

### AppStatistics

**Purpose**: Track detection/lock events for statistics display

**Storage**: UserDefaults (via StatisticsService)

| Field | Type | Description | Persistence Key |
|-------|------|-------------|-----------------|
| totalBlocks | Int | All-time count of keyboard locks | `catpaws.stats.totalBlocks` |
| todayBlocks | Int | Locks triggered today | `catpaws.stats.todayBlocks` |
| weekBlocks | Int | Locks triggered this week | `catpaws.stats.weekBlocks` |
| lastBlockDate | Date? | Timestamp of most recent lock | `catpaws.stats.lastBlockDate` |
| lastResetDate | Date | Date counters were last reset | `catpaws.stats.lastResetDate` |

**Swift Definition**:
```swift
struct AppStatistics: Codable, Equatable {
    var totalBlocks: Int = 0
    var todayBlocks: Int = 0
    var weekBlocks: Int = 0
    var lastBlockDate: Date?
    var lastResetDate: Date = Date()

    mutating func recordBlock() {
        totalBlocks += 1
        todayBlocks += 1
        weekBlocks += 1
        lastBlockDate = Date()
    }

    mutating func resetDaily() {
        todayBlocks = 0
    }

    mutating func resetWeekly() {
        weekBlocks = 0
    }

    mutating func resetAll() {
        totalBlocks = 0
        todayBlocks = 0
        weekBlocks = 0
        lastBlockDate = nil
        lastResetDate = Date()
    }
}
```

**State Transitions**:
- `recordBlock()`: Called when keyboard lock is triggered
- `resetDaily()`: Called at midnight local time
- `resetWeekly()`: Called at start of new week (Monday)
- `resetAll()`: Called when user chooses "Reset Statistics" in Settings

---

### OnboardingState

**Purpose**: Track first-run onboarding completion

**Storage**: UserDefaults

| Field | Type | Description | Persistence Key |
|-------|------|-------------|-----------------|
| hasCompletedOnboarding | Bool | True after user finishes or skips onboarding | `catpaws.onboarding.completed` |
| currentStep | Int? | Current step index if onboarding in progress | (not persisted) |
| wasSkipped | Bool | True if user skipped instead of completing | `catpaws.onboarding.skipped` |

**Swift Definition**:
```swift
struct OnboardingState {
    private static let completedKey = "catpaws.onboarding.completed"
    private static let skippedKey = "catpaws.onboarding.skipped"

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Self.completedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.completedKey) }
    }

    var wasSkipped: Bool {
        get { UserDefaults.standard.bool(forKey: Self.skippedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.skippedKey) }
    }

    // In-memory only during onboarding flow
    var currentStep: OnboardingStep = .welcome

    mutating func complete() {
        hasCompletedOnboarding = true
    }

    mutating func skip() {
        hasCompletedOnboarding = true
        wasSkipped = true
    }

    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: completedKey)
        UserDefaults.standard.removeObject(forKey: skippedKey)
    }
}

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case permissionExplanation = 1
    case grantPermission = 2
    case testDetection = 3
    case complete = 4
}
```

---

### KeyboardLayoutMap (Extended)

**Purpose**: Provide key position and adjacency data for different keyboard layouts

**Storage**: Memory (static data)

**Existing**: QWERTY layout (US) is already implemented in `KeyboardAdjacencyMap.swift`

**New Layouts to Add**:

| Layout | Identifier Pattern | Key Differences from QWERTY |
|--------|-------------------|----------------------------|
| AZERTY | `com.apple.keylayout.French*` | A↔Q, Z↔W, M moved to right of L |
| QWERTZ | `com.apple.keylayout.German*` | Y↔Z |
| Dvorak | `com.apple.keylayout.Dvorak*` | Complete rearrangement for typing efficiency |

**Swift Extension**:
```swift
extension KeyboardAdjacencyMap {
    enum Layout: String, CaseIterable {
        case qwerty = "qwerty"
        case azerty = "azerty"
        case qwertz = "qwertz"
        case dvorak = "dvorak"

        static func from(inputSourceId: String) -> Layout {
            let lower = inputSourceId.lowercased()
            if lower.contains("french") || lower.contains("azerty") {
                return .azerty
            } else if lower.contains("german") {
                return .qwertz
            } else if lower.contains("dvorak") {
                return .dvorak
            }
            return .qwerty // Default
        }
    }

    static func keyPositions(for layout: Layout) -> [UInt16: KeyPosition] {
        switch layout {
        case .qwerty: return keyPositions // Existing
        case .azerty: return azertyKeyPositions
        case .qwertz: return qwertzKeyPositions
        case .dvorak: return dvorakKeyPositions
        }
    }
}
```

**Note**: Key codes remain the same across layouts (they're hardware-based). The physical positions change, which affects adjacency calculations.

---

## Extended Entities

### Configuration (Extended)

**New Keys Added**:

| Field | Type | Default | Persistence Key |
|-------|------|---------|-----------------|
| launchAtLogin | Bool | false | `catpaws.launchAtLogin` |
| debugLoggingEnabled | Bool | false | `catpaws.debugLogging` |

**Note**: `launchAtLogin` is read/write but the actual login item state is managed by `SMAppService`. The Configuration stores user intent; LoginItemService syncs with system.

---

## Relationships

```
StatisticsService ───manages──→ AppStatistics
       │
       └───notified by──→ LockStateManager (when lock triggered)

OnboardingViewModel ───manages──→ OnboardingState
       │
       └───checks──→ KeyboardMonitor (permission status)

KeyboardLayoutDetector ───provides──→ KeyboardLayoutMap.Layout
       │
       └───used by──→ CatDetectionService (adjacency calculations)

LoginItemService ───wraps──→ SMAppService.mainApp
       │
       └───syncs with──→ Configuration.launchAtLogin
```

---

## Validation Rules

### AppStatistics
- `totalBlocks >= todayBlocks >= 0`
- `totalBlocks >= weekBlocks >= 0`
- `lastResetDate <= lastBlockDate` (when lastBlockDate exists)

### OnboardingState
- `currentStep` only valid during active onboarding flow
- `hasCompletedOnboarding` is permanent once set (no undo)

### KeyboardLayoutMap
- Layout detection falls back to QWERTY if unknown input source
- All layouts must provide positions for at least the standard alpha-numeric keys

---

## Migration Notes

No data migration required. All new fields have sensible defaults:
- Statistics start at 0
- Onboarding shows on first launch (completed=false)
- Launch at login defaults to disabled
- Debug logging defaults to disabled
