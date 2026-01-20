# API Contract: PermissionService

**Feature**: 005-permissions-settings-enhancements
**Date**: 2026-01-19
**Type**: Internal Service Protocol

## Protocol Definition

```swift
/// Protocol for checking system permissions
protocol PermissionChecking {
    /// Check if Accessibility permission is granted
    /// - Returns: true if the process is trusted for Accessibility
    func checkAccessibility() -> Bool
    
    /// Check if Input Monitoring permission is granted
    /// - Returns: true if the process can listen to events
    func checkInputMonitoring() -> Bool
    
    /// Get current status of both permissions
    /// - Returns: PermissionState with both statuses
    func getCurrentState() -> PermissionState
    
    /// Open System Settings to the appropriate pane
    /// - Parameter type: The permission type to open settings for
    func openSettings(for type: PermissionType)
}
```

## Implementation Contract

```swift
/// Concrete implementation using macOS APIs
final class PermissionService: PermissionChecking {
    /// Singleton for app-wide access
    static let shared = PermissionService()
    
    /// Publisher for permission state changes
    @Published private(set) var state: PermissionState
    
    /// Timer for polling permission status
    private var pollingTimer: Timer?
    
    /// Polling interval in seconds
    static let pollingInterval: TimeInterval = 1.0
    
    // MARK: - PermissionChecking
    
    func checkAccessibility() -> Bool {
        // Uses AXIsProcessTrusted() from ApplicationServices
    }
    
    func checkInputMonitoring() -> Bool {
        // Uses CGPreflightListenEventAccess() from CoreGraphics
    }
    
    func getCurrentState() -> PermissionState {
        // Returns current snapshot of both permissions
    }
    
    func openSettings(for type: PermissionType) {
        // Opens appropriate System Settings pane via URL
    }
    
    // MARK: - Polling
    
    func startPolling() {
        // Starts 1-second polling timer
        // Updates @Published state on change
    }
    
    func stopPolling() {
        // Invalidates timer
    }
}
```

## Events/Callbacks

| Event | Trigger | Handler |
|-------|---------|---------|
| Permission state changed | Polling detects change | Update `@Published state`; notify observers |
| Permission revoked | Was granted, now denied | Set `showPermissionRevokedBanner = true` in AppViewModel |

## Usage Examples

```swift
// Check permissions on startup
let service = PermissionService.shared
if service.getCurrentState().allGranted {
    // Normal operation
} else {
    // Show permission guide
}

// Start polling during onboarding
service.startPolling()

// React to changes
service.$state
    .receive(on: DispatchQueue.main)
    .sink { state in
        // Update UI based on permission changes
    }
    .store(in: &cancellables)
```
