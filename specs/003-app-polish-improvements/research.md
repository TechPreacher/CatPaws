# Research: CatPaws App Polish & Improvements

**Feature**: 003-app-polish-improvements
**Date**: 2026-01-17
**Status**: Complete

## Research Tasks

### 1. SMAppService for Launch at Login (macOS 14+)

**Decision**: Use `SMAppService.mainApp` for login item registration

**Rationale**:
- SMAppService is Apple's modern replacement for deprecated login item APIs
- Available in macOS 13+ but simplified in macOS 14+ with better SwiftUI integration
- Automatically handles sandboxed apps without requiring helper bundles
- Status persists across app updates (handles FR-002)
- Clean API: `SMAppService.mainApp.register()` and `unregister()`

**Alternatives Considered**:
- LSSharedFileList (deprecated in macOS 10.11)
- LaunchServices/Login Items (legacy, requires helper app for sandbox)
- SMLoginItemSetEnabled (deprecated, requires helper bundle)

**Implementation Notes**:
```swift
import ServiceManagement

// Check status
let status = SMAppService.mainApp.status

// Register
try SMAppService.mainApp.register()

// Unregister
try SMAppService.mainApp.unregister()
```

---

### 2. Keyboard Layout Detection (Input Source)

**Decision**: Use Carbon `TISGetInputSourceProperty` to detect current keyboard layout

**Rationale**:
- Standard approach for detecting active input source
- Returns layout identifier (e.g., "com.apple.keylayout.AZERTY")
- Works with `DistributedNotificationCenter` to detect layout changes
- No deprecated APIs; Carbon framework still supported for this use case

**Alternatives Considered**:
- NSInputMethodController (private API, not App Store safe)
- Accessibility API (overkill for this use case)
- Hardcoding based on locale (doesn't handle user preferences)

**Implementation Notes**:
```swift
import Carbon

func currentKeyboardLayoutIdentifier() -> String? {
    guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
        return nil
    }
    guard let idRef = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
        return nil
    }
    return Unmanaged<CFString>.fromOpaque(idRef).takeUnretainedValue() as String
}

// Listen for changes
DistributedNotificationCenter.default().addObserver(
    self,
    selector: #selector(inputSourceChanged),
    name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
    object: nil
)
```

**Layout Identifier Patterns**:
- QWERTY (US): `com.apple.keylayout.US`, `com.apple.keylayout.ABC`
- AZERTY (French): `com.apple.keylayout.French`, `com.apple.keylayout.French-PC`
- QWERTZ (German): `com.apple.keylayout.German`
- Dvorak: `com.apple.keylayout.Dvorak`

---

### 3. os.Logger for Diagnostic Logging

**Decision**: Use `os.Logger` (unified logging) with subsystem and category

**Rationale**:
- Apple's recommended logging system since iOS 14/macOS 11
- Integrates with Console.app and `log` command line tool
- Privacy-aware: automatically redacts sensitive data
- Efficient: logging calls are compiled out at high log levels
- Supports structured logging with metadata

**Alternatives Considered**:
- print() (not persistent, not filterable)
- NSLog (legacy, less efficient)
- Third-party logging (OSLog-based anyway, adds dependency)

**Implementation Notes**:
```swift
import os

struct AppLogger {
    static let subsystem = "com.catpaws.app"

    static let detection = Logger(subsystem: subsystem, category: "detection")
    static let lock = Logger(subsystem: subsystem, category: "lock")
    static let permission = Logger(subsystem: subsystem, category: "permission")

    // Example usage
    static func logDetection(keyCount: Int) {
        detection.info("Cat pattern detected with \(keyCount) keys")
    }
}
```

**Console.app Filter**: `subsystem:com.catpaws.app`

---

### 4. Multi-Monitor Active Screen Detection

**Decision**: Use `NSApp.keyWindow?.screen` or `NSScreen.main` with frontmost app check

**Rationale**:
- `NSApp.keyWindow?.screen` gives the screen of the currently focused window
- Falls back to `NSScreen.main` if no key window
- Works correctly with full-screen apps

**Alternatives Considered**:
- Mouse cursor position (doesn't match user focus intent)
- NSScreen.screens enumeration with hit testing (complex, unnecessary)

**Implementation Notes**:
```swift
func activeScreen() -> NSScreen {
    // Try to get screen of key window
    if let keyWindow = NSApp.keyWindow, let screen = keyWindow.screen {
        return screen
    }
    // Try frontmost app's main window
    if let frontApp = NSWorkspace.shared.frontmostApplication,
       let pid = frontApp.processIdentifier {
        // Get windows for frontmost app
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        if let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
            for window in windowList {
                if let ownerPID = window[kCGWindowOwnerPID as String] as? Int32, ownerPID == pid,
                   let bounds = window[kCGWindowBounds as String] as? [String: CGFloat] {
                    let point = CGPoint(x: bounds["X"] ?? 0, y: bounds["Y"] ?? 0)
                    if let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) {
                        return screen
                    }
                }
            }
        }
    }
    // Default to main screen
    return NSScreen.main ?? NSScreen.screens.first!
}
```

---

### 5. Single Instance Prevention

**Decision**: Use `NSRunningApplication.runningApplications(withBundleIdentifier:)` check on launch

**Rationale**:
- Simple and reliable
- Standard pattern for macOS apps
- Works with sandboxed apps

**Alternatives Considered**:
- Lock file (problematic with crashes)
- Distributed notifications (race conditions)
- Unix socket (overkill)

**Implementation Notes**:
```swift
func checkSingleInstance() -> Bool {
    let bundleId = Bundle.main.bundleIdentifier!
    let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
    return running.count <= 1
}
```

---

### 6. SwiftLint Integration

**Decision**: Add SwiftLint via Swift Package Manager, configure as build phase

**Rationale**:
- SPM integration is cleaner than manual binary or Homebrew
- Build phase catches violations at compile time
- Configuration file allows project-specific rules

**Configuration (.swiftlint.yml)**:
```yaml
disabled_rules:
  - trailing_whitespace  # Xcode handles this
  - line_length          # Often too restrictive

opt_in_rules:
  - empty_count
  - explicit_init
  - first_where
  - force_unwrapping
  - implicit_return

excluded:
  - Pods
  - .build

line_length:
  warning: 120
  error: 150
```

**Build Phase Script**:
```bash
if command -v swiftlint >/dev/null 2>&1; then
    swiftlint
else
    echo "warning: SwiftLint not installed"
fi
```

---

### 7. Permission Status Polling

**Decision**: Use Timer-based polling (2-second interval) while permission guide is displayed

**Rationale**:
- Input Monitoring permission check via `AXIsProcessTrusted()` is lightweight
- No notification available for permission grant (unlike some other permissions)
- 2-second interval balances responsiveness vs. resource usage

**Alternatives Considered**:
- File system observation of TCC.db (sandboxed apps can't access)
- Continuous polling (wasteful)
- Manual refresh button only (poor UX)

**Implementation Notes**:
```swift
import ApplicationServices

func hasInputMonitoringPermission() -> Bool {
    return AXIsProcessTrusted()
}

// Open System Settings directly to Input Monitoring
func openInputMonitoringSettings() {
    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
    NSWorkspace.shared.open(url)
}
```

---

## Unresolved Questions

None - all technical approaches confirmed.

## Next Steps

1. Generate data-model.md with entity definitions
2. Generate quickstart.md with validation scenarios
3. Update tasks.md if any changes needed from research findings
