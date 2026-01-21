# Quickstart: Code Quality Audit Remediation

**Feature**: 007-code-quality-audit  
**Date**: 2026-01-20

## Prerequisites

Before starting remediation:

```bash
# Ensure all tests pass (baseline)
xcodebuild -scheme CatPaws -configuration Debug test

# Check for compiler warnings
xcodebuild -scheme CatPaws -configuration Debug build 2>&1 | grep -i warning
```

## Phase 1: Quick Wins

**Risk**: Low | **Impact**: High | **Time**: ~30 minutes

### 1.1 Remove Unused Files (DC-001, DC-002, DC-003)

```bash
cd CatPaws/CatPaws

# Remove unused menu bar implementation
rm MenuBar/StatusItemManager.swift
rm MenuBar/MenuBarView.swift
rm Views/PopoverView.swift

# Update Xcode project (remove file references)
# Do this manually in Xcode or update project.pbxproj

# Verify build
xcodebuild -scheme CatPaws -configuration Debug build
```

### 1.2 Remove Unused Methods in KeyboardAdjacencyMap (DC-006 through DC-009)

Delete these methods from `KeyboardAdjacencyMap.swift`:

- `distance(between:and:)` (non-layout version, ~line 432)
- `areAdjacent(_:_:)` (non-layout version, ~line 448)  
- `adjacentKeys(for:)` (non-layout version, ~line 458)
- `buildAdjacencyGraph(for:)` (both versions, ~lines 475 and 550)

### 1.3 Fix Trivial Tests (TQ-001 through TQ-004)

Replace these trivial assertions:

```swift
// BEFORE (PermissionServiceTests.swift)
func testCheckAccessibilityReturnsBoolean() {
    let result = service.checkAccessibility()
    XCTAssertTrue(result == true || result == false) // Always passes!
}

// AFTER - Remove or replace with meaningful test
func testCheckAccessibilityPermissionCheck() {
    // Test actual behavior, not that booleans are booleans
    // This test may be unnecessary - permission state depends on system
    // Consider removing entirely or testing state consistency
}
```

### 1.4 Add Private Access Modifiers (BP-001 through BP-007)

```swift
// AppViewModel.swift - Make service properties private
private let keyboardMonitor: KeyboardMonitoring
private let configuration: Configuration
private let catDetectionService: CatDetecting
private let lockStateManager: LockStateManaging
private let lockService: KeyboardLocking
private let notificationController: NotificationPresenting
private let statisticsService: StatisticsService
private let permissionService: PermissionService

// SettingsView.swift - Make nested views private
private struct GeneralSettingsView: View { ... }
private struct DetectionSettingsView: View { ... }
private struct AboutView: View { ... }

// KeyboardAdjacencyMap.swift - Make internal type private
private struct KeyPosition { ... }
```

### 1.5 Verify Phase 1

```bash
# Build
xcodebuild -scheme CatPaws -configuration Debug build

# Run all tests
xcodebuild -scheme CatPaws -configuration Debug test
```

---

## Phase 2: Code Consolidation

**Risk**: Medium | **Impact**: Medium | **Time**: ~1 hour

### 2.1 Consolidate Permission Checking (DUP-001)

In `OnboardingViewModel.swift`, replace duplicated event tap code:

```swift
// BEFORE - Duplicated code
private func checkInputMonitoringPermission() -> Bool {
    let eventMask: CGEventMask = 1 << CGEventType.keyDown.rawValue
    guard let tap = CGEvent.tapCreate(...) else { return false }
    CFMachPortInvalidate(tap)
    return true
}

// AFTER - Use existing service
private func checkInputMonitoringPermission() -> Bool {
    return permissionService.checkInputMonitoring()
}
```

### 2.2 Move Mocks to Proper Location (TQ-009)

```bash
# Move MockPermissionService from PermissionServiceTests.swift
# to CatPawsTests/Mocks/MockPermissionService.swift
```

Create new file:
```swift
// CatPawsTests/Mocks/MockPermissionService.swift
import Foundation
@testable import CatPaws

final class MockPermissionService: PermissionService {
    var mockAccessibilityGranted = false
    var mockInputMonitoringGranted = false
    
    override func checkAccessibility() -> Bool {
        return mockAccessibilityGranted
    }
    
    override func checkInputMonitoring() -> Bool {
        return mockInputMonitoringGranted
    }
}
```

### 2.3 Verify Phase 2

```bash
xcodebuild -scheme CatPaws -configuration Debug test
```

---

## Phase 3: Test Coverage

**Risk**: Low | **Impact**: High | **Time**: ~2 hours

### 3.1 Create Missing Test Files

Create these test files with basic test structure:

1. `CatPawsTests/ServiceTests/StatisticsServiceTests.swift`
2. `CatPawsTests/ServiceTests/LoginItemServiceTests.swift`

Example template:
```swift
import XCTest
@testable import CatPaws

final class StatisticsServiceTests: XCTestCase {
    var sut: StatisticsService!
    
    override func setUp() {
        super.setUp()
        sut = StatisticsService()
        sut.resetAll() // Start with clean state
    }
    
    override func tearDown() {
        sut.resetAll()
        sut = nil
        super.tearDown()
    }
    
    func testRecordBlockIncrementsCounter() {
        let initialCount = sut.statistics.totalBlockedCount
        sut.recordBlock()
        XCTAssertEqual(sut.statistics.totalBlockedCount, initialCount + 1)
    }
    
    func testResetAllClearsStatistics() {
        sut.recordBlock()
        sut.resetAll()
        XCTAssertEqual(sut.statistics.totalBlockedCount, 0)
    }
}
```

### 3.2 Add Emergency Shortcut Test

```swift
// NotificationWindowControllerTests.swift
func testEmergencyShortcutRequiresHoldDuration() {
    // Test that Cmd+Option+Escape requires 2-second hold
    // This requires mocking the timer/duration
}
```

### 3.3 Verify Phase 3

```bash
xcodebuild -scheme CatPaws -configuration Debug test
```

---

## Phase 4: Optional Improvements

**Risk**: Low | **Priority**: Low | **Time**: Variable

### 4.1 Create @UserDefaultsBacked Property Wrapper

```swift
// Utilities/UserDefaultsBacked.swift
@propertyWrapper
struct UserDefaultsBacked<Value> {
    let key: String
    let defaultValue: Value
    let defaults: UserDefaults
    
    var wrappedValue: Value {
        get { defaults.object(forKey: key) as? Value ?? defaultValue }
        set { defaults.set(newValue, forKey: key) }
    }
}
```

### 4.2 Add Computed Properties to DetectionType

```swift
// Models/DetectionType.swift
extension DetectionType {
    var iconName: String {
        switch self {
        case .sitting: return "cat"
        case .walking: return "cat.walking"
        case .rapidFire: return "keyboard"
        case .adjacentKeys: return "rectangle.grid.2x2"
        }
    }
    
    var title: String { ... }
    var message: String { ... }
}
```

---

## Validation Checklist

After each phase, verify:

- [ ] `xcodebuild build` succeeds with zero warnings
- [ ] `xcodebuild test` passes all tests
- [ ] App launches and functions normally
- [ ] Menu bar icon appears and responds
- [ ] Keyboard lock/unlock works correctly

## Rollback

If issues arise:

```bash
git stash  # Save current changes
git checkout .  # Revert to last commit
```
