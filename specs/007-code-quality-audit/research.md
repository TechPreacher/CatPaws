# Research: Code Quality Audit Findings

**Feature**: 007-code-quality-audit  
**Date**: 2026-01-20  
**Status**: Complete

## Executive Summary

| Category | Critical | Warning | Info | Total |
|----------|----------|---------|------|-------|
| Dead Code | 3 | 10 | 6 | 19 |
| Duplicate Code | 2 | 5 | 5 | 12 |
| Swift Best Practices | 0 | 7 | 6 | 13 |
| Test Quality | 4 | 10 | 3 | 17 |
| **Total** | **9** | **32** | **20** | **61** |

The codebase is well-structured and follows Swift conventions. Most issues are maintenance-related (unused code, missing tests) rather than correctness problems. The application is working correctly; all remediations must be behavior-preserving.

---

## 1. Dead Code Findings

### 1.1 Unused Types (Critical - Remove)

| ID | Type | File | Reason |
|----|------|------|--------|
| DC-001 | `StatusItemManager` | [StatusItemManager.swift](../../CatPaws/CatPaws/MenuBar/StatusItemManager.swift) | Never instantiated. File header states "kept for potential future use but is currently unused." App uses SwiftUI `MenuBarExtra` instead. |
| DC-002 | `MenuBarView` | [MenuBarView.swift](../../CatPaws/CatPaws/MenuBar/MenuBarView.swift) | Only used in `#Preview`. App uses `MenuBarContentView` with `MenuBarExtra`. |
| DC-003 | `PopoverView` | [PopoverView.swift](../../CatPaws/CatPaws/Views/PopoverView.swift) | Only referenced by unused `StatusItemManager` and in `#Preview`. |

**Decision**: Remove all three files. They form an interconnected set representing an alternative menu bar implementation that was superseded.

### 1.2 Unused Functions/Methods (Warning - Remove)

| ID | Method | File | Reason |
|----|--------|------|--------|
| DC-004 | `refreshLayout()` | [KeyboardLayoutDetector.swift#L81](../../CatPaws/CatPaws/Services/KeyboardLayoutDetector.swift#L81) | Never called. Detector uses automatic notification-based updates. |
| DC-005 | `recordRecheck()` | [LockState.swift#L108](../../CatPaws/CatPaws/Models/LockState.swift#L108) | Never called in production. Feature not implemented. |
| DC-006 | `distance(between:and:)` | [KeyboardAdjacencyMap.swift#L432](../../CatPaws/CatPaws/Services/KeyboardAdjacencyMap.swift#L432) | Non-layout version never called directly. |
| DC-007 | `areAdjacent(_:_:)` | [KeyboardAdjacencyMap.swift#L448](../../CatPaws/CatPaws/Services/KeyboardAdjacencyMap.swift#L448) | Non-layout version never called. Only layout-aware version used. |
| DC-008 | `adjacentKeys(for:)` | [KeyboardAdjacencyMap.swift#L458](../../CatPaws/CatPaws/Services/KeyboardAdjacencyMap.swift#L458) | Non-layout version never called. |
| DC-009 | `buildAdjacencyGraph(for:)` | [KeyboardAdjacencyMap.swift#L475](../../CatPaws/CatPaws/Services/KeyboardAdjacencyMap.swift#L475) | Both versions never called anywhere. |
| DC-010 | `checkPermission()` | [OnboardingViewModel.swift#L211](../../CatPaws/CatPaws/ViewModels/OnboardingViewModel.swift#L211) | Only used in tests. |
| DC-011 | `checkAccessibilityPermission()` | [OnboardingViewModel.swift#L217](../../CatPaws/CatPaws/ViewModels/OnboardingViewModel.swift#L217) | Never called anywhere. |
| DC-012 | `resetState()` | [AppViewModel.swift#L124](../../CatPaws/CatPaws/ViewModels/AppViewModel.swift#L124) | Only used in tests. |
| DC-013 | `openPermissionSettings()` | [AppViewModel.swift#L149](../../CatPaws/CatPaws/ViewModels/AppViewModel.swift#L149) | Never called. App uses `openSettings(for:)` instead. |
| DC-014 | `openPermissionSettings()` | [KeyboardMonitor.swift#L47](../../CatPaws/CatPaws/Services/KeyboardMonitor.swift#L47) | Never called. Permission settings opened via `PermissionService`. |

**Decision**: Keep DC-010 and DC-012 (test helpers). Remove all others.

### 1.3 Unused Properties (Info - Review)

| ID | Property | File | Reason |
|----|----------|------|--------|
| DC-015 | `lastActivityDate` | [AppState.swift#L16](../../CatPaws/CatPaws/Models/AppState.swift#L16) | Never written/read in production. |
| DC-016 | `lastRecheckAt` | [LockState.swift#L42](../../CatPaws/CatPaws/Models/LockState.swift#L42) | Never read. Associated with unused `recordRecheck()`. |
| DC-017 | `status` | [LoginItemService.swift#L27](../../CatPaws/CatPaws/Services/LoginItemService.swift#L27) | Never accessed. Only `isEnabled` is used. |
| DC-018 | `lastError` | [LoginItemService.swift#L15](../../CatPaws/CatPaws/Services/LoginItemService.swift#L15) | Set internally but never read. |
| DC-019 | `launchAtLogin` | [Configuration.swift#L149](../../CatPaws/CatPaws/Models/Configuration.swift#L149) | Never read. Settings uses `LoginItemService.isEnabled` directly. |

**Decision**: Remove after verifying no future plans for these features.

---

## 2. Duplicate Code Findings

### 2.1 High-Impact Duplicates (Critical - Consolidate)

| ID | Pattern | Locations | Lines Saved |
|----|---------|-----------|-------------|
| DUP-001 | Permission check via event tap creation | [PermissionService.swift#L46-L64](../../CatPaws/CatPaws/Services/PermissionService.swift#L46-L64), [OnboardingViewModel.swift#L254-L273](../../CatPaws/CatPaws/ViewModels/OnboardingViewModel.swift#L254-L273) | ~20 |
| DUP-002 | Permission polling timer setup | [AppViewModel.swift#L183-L194](../../CatPaws/CatPaws/ViewModels/AppViewModel.swift#L183-L194), [OnboardingViewModel.swift#L207-L220](../../CatPaws/CatPaws/ViewModels/OnboardingViewModel.swift#L207-L220), [PermissionService.swift#L91-L103](../../CatPaws/CatPaws/Services/PermissionService.swift#L91-L103) | ~30 |

**Recommendation**: 
- DUP-001: Have `OnboardingViewModel` use `PermissionService.checkInputMonitoring()` instead of duplicating the event tap logic.
- DUP-002: Centralize polling in `PermissionService` and have view models observe via Combine publishers.

### 2.2 Medium-Impact Duplicates (Warning - Consider)

| ID | Pattern | Locations | Recommendation |
|----|---------|-----------|----------------|
| DUP-003 | Async task sleep timer pattern | [LockStateManager.swift#L80-L93](../../CatPaws/CatPaws/Services/LockStateManager.swift#L80-L93) (debounce), [LockStateManager.swift#L119-L133](../../CatPaws/CatPaws/Services/LockStateManager.swift#L119-L133) (cooldown) | Create `scheduleDelayed(seconds:action:)` helper |
| DUP-004 | Timer invalidation pattern | Multiple files (4 locations) | Consider Combine Timer or wrapper type |
| DUP-005 | Configuration property boilerplate | [Configuration.swift#L63-L164](../../CatPaws/CatPaws/Models/Configuration.swift#L63-L164) (9 properties) | Create `@UserDefaultsBacked` property wrapper |
| DUP-006 | Onboarding step view structure | [OnboardingView.swift](../../CatPaws/CatPaws/Views/OnboardingView.swift) (6 step views) | Create `OnboardingStepTemplate` view |
| DUP-007 | Detection type UI switch statements | [CatLockPopupView.swift#L48-L80](../../CatPaws/CatPaws/Views/CatLockPopupView.swift#L48-L80) (4 switches) | Add computed properties to `DetectionType` enum |

### 2.3 Low-Impact Patterns (Info - Optional)

| ID | Pattern | Locations | Notes |
|----|---------|-----------|-------|
| DUP-008 | Status indicator (Circle + text) | MenuBarContentView, PopoverView | Create `StatusIndicator` view |
| DUP-009 | Footer pattern (Settings + Quit) | MenuBarContentView, PopoverView | PopoverView is unused |
| DUP-010 | Rounded rectangle background | 5 locations | Create `.cardBackground()` view modifier |
| DUP-011 | MainActor Task in delegate | AppViewModel, OnboardingViewModel | Common async pattern |
| DUP-012 | UserDefaults key enums | Configuration, OnboardingState, StatisticsService | Consider centralizing |

---

## 3. Swift Best Practices Findings

### 3.1 Access Control (Warning - Fix)

| ID | Symbol | File | Current | Recommended |
|----|--------|------|---------|-------------|
| BP-001 | Service properties | [AppViewModel.swift#L73-L80](../../CatPaws/CatPaws/ViewModels/AppViewModel.swift#L73-L80) | `internal` (default) | `private` |
| BP-002 | `GeneralSettingsView` | [SettingsView.swift#L25](../../CatPaws/CatPaws/Views/SettingsView.swift#L25) | `internal` | `private` |
| BP-003 | `DetectionSettingsView` | [SettingsView.swift#L119](../../CatPaws/CatPaws/Views/SettingsView.swift#L119) | `internal` | `private` |
| BP-004 | `AboutView` | [SettingsView.swift#L163](../../CatPaws/CatPaws/Views/SettingsView.swift#L163) | `internal` | `private` |
| BP-005 | `KeyPosition` | [KeyboardAdjacencyMap.swift#L14](../../CatPaws/CatPaws/Services/KeyboardAdjacencyMap.swift#L14) | `internal` | `private` |
| BP-006 | Helper methods | [KeyboardMonitor.swift](../../CatPaws/CatPaws/Services/KeyboardMonitor.swift) | `internal` | `fileprivate` |
| BP-007 | `PermissionStepRow` | [PermissionGuideView.swift#L116](../../CatPaws/CatPaws/Views/PermissionGuideView.swift#L116) | `internal` | `private` (also unused) |

### 3.2 Force Unwraps (Info - Acceptable)

| ID | Location | Code | Status |
|----|----------|------|--------|
| BP-008 | [PermissionType.swift#L27](../../CatPaws/CatPaws/Models/PermissionType.swift#L27) | `URL(string:)!` | ✅ Has SwiftLint disable comment |
| BP-009 | [PermissionType.swift#L30](../../CatPaws/CatPaws/Models/PermissionType.swift#L30) | `URL(string:)!` | ✅ Has SwiftLint disable comment |

**Summary**: All force unwraps are justified with comments. No action required.

### 3.3 Naming (Info - Minor)

| ID | Symbol | File | Suggestion |
|----|--------|------|------------|
| BP-010 | `Keys` enum | Configuration.swift | More descriptive: `UserDefaultsKeys` |
| BP-011 | `Defaults` enum | Configuration.swift | More descriptive: `DefaultValues` |
| BP-012 | `debounceMs`, `cooldownSec` | LockStateManager.swift | Consider using `Duration` type |
| BP-013 | `Keys` enum | StatisticsService.swift | Same as BP-010 |

---

## 4. Test Quality Findings

### 4.1 Invalid/Trivial Tests (Critical - Fix)

| ID | Test | File | Issue |
|----|------|------|-------|
| TQ-001 | `testCheckAccessibilityReturnsBoolean` | [PermissionServiceTests.swift#L25](../../CatPaws/CatPawsTests/ServiceTests/PermissionServiceTests.swift#L25) | Assertion `result == true \|\| result == false` always passes |
| TQ-002 | `testCheckInputMonitoringReturnsBoolean` | [PermissionServiceTests.swift#L30](../../CatPaws/CatPawsTests/ServiceTests/PermissionServiceTests.swift#L30) | Same trivial assertion |
| TQ-003 | `testHasAccessibilityIsInitialized` | [OnboardingViewModelTests.swift#L101](../../CatPaws/CatPawsTests/ViewModelTests/OnboardingViewModelTests.swift#L101) | Same trivial assertion |
| TQ-004 | `testHasInputMonitoringIsInitialized` | [OnboardingViewModelTests.swift#L107](../../CatPaws/CatPawsTests/ViewModelTests/OnboardingViewModelTests.swift#L107) | Same trivial assertion |

**Decision**: Remove or replace with meaningful assertions (e.g., test state consistency).

### 4.2 Missing Test Coverage (Warning - Add Tests)

#### Services Without Tests:
| Service | Missing Coverage |
|---------|------------------|
| `StatisticsService` | `recordBlock()`, `resetAll()`, daily/weekly reset logic |
| `LoginItemService` | Entirely untested |
| `KeyboardMonitor` | No unit tests (only indirect via integration) |
| `KeyboardLayoutDetector` | Entirely untested |
| `NotificationWindowController` | Entirely untested (including emergency shortcut) |

#### ViewModels Without Tests:
| ViewModel | Missing Coverage |
|-----------|------------------|
| `AppViewModel` | Delegate callbacks, permission handling, manual unlock |

#### Critical Untested Logic:
- Emergency shortcut (Cmd+Option+Escape held 2 seconds)
- Multi-monitor notification positioning
- Sound playback (`playLockSound()`, `playUnlockSound()`)
- AZERTY/QWERTZ keyboard layout adjacency

### 4.3 Mock Issues (Warning - Fix)

| ID | Issue | Impact |
|----|-------|--------|
| TQ-005 | `MockNotificationPresenter` lacks error state simulation | Can't test failure handling |
| TQ-006 | No mock for `KeyboardLocking` protocol | Tests use real service |
| TQ-007 | No mock for `CatDetecting` protocol | Tests use real service |
| TQ-008 | No mock for `ConfigurationProviding` protocol | Can't isolate timing config |
| TQ-009 | Mocks defined in test files | Should be in `Mocks/` directory |

### 4.4 Duplicate Tests (Info - Consider Removing)

| ID | Tests | Overlap |
|----|-------|---------|
| TQ-010 | `testTransitionLockedToCooldown` / `testLockedAtClearedOnManualUnlock` | Both test `manualUnlock()` clears state |

### 4.5 Missing Test Files (Warning - Create)

- `StatisticsServiceTests.swift`
- `LoginItemServiceTests.swift`
- `KeyboardMonitorTests.swift`
- `KeyboardLayoutDetectorTests.swift`
- `NotificationWindowControllerTests.swift`

---

## Remediation Priority

### Phase 1: Quick Wins (Low Risk, High Impact)

1. Remove unused files: `StatusItemManager.swift`, `MenuBarView.swift`, `PopoverView.swift`
2. Remove unused methods in `KeyboardAdjacencyMap.swift` (non-layout versions)
3. Fix trivial tests (TQ-001 through TQ-004)
4. Add `private` access modifiers (BP-001 through BP-007)

### Phase 2: Code Consolidation (Medium Risk, Medium Impact)

1. Consolidate permission checking (DUP-001)
2. Centralize permission polling (DUP-002)
3. Move mocks to `Mocks/` directory (TQ-009)

### Phase 3: Test Coverage (Low Risk, High Impact)

1. Add `StatisticsServiceTests.swift`
2. Add `LoginItemServiceTests.swift`
3. Add tests for emergency shortcut
4. Create missing mock protocols

### Phase 4: Optional Improvements (Low Priority)

1. Create `@UserDefaultsBacked` property wrapper
2. Create `OnboardingStepTemplate` view
3. Add computed properties to `DetectionType` enum
