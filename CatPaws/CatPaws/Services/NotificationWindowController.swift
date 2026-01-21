//
//  NotificationWindowController.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import AppKit
import SwiftUI

/// Controller for the floating notification window
final class NotificationWindowController: NotificationPresenting {
    // MARK: - Properties

    private var window: NSPanel?
    private var hostingView: NSHostingView<CatLockPopupView>?
    private var currentDismissCallback: (() -> Void)?

    // ESC unlock properties
    private var localEventMonitor: Any?
    private var escPressCount: Int = 0
    private var lastEscPressTime: Date?
    private let escTimeoutSeconds: TimeInterval = 2.0
    private let requiredEscPresses: Int = 5

    // MARK: - NotificationPresenting

    func show(detectionType: DetectionType, onDismiss: @escaping () -> Void) {
        // Store callback
        currentDismissCallback = onDismiss

        // Create the SwiftUI view
        let popupView = CatLockPopupView(detectionType: detectionType) { [weak self] in
            self?.handleDismiss()
        }

        // Create hosting view
        let hosting = NSHostingView(rootView: popupView)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        hostingView = hosting

        // Create the panel
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Configure panel appearance
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true

        // Set content view
        panel.contentView = hosting

        // Size to fit content
        hosting.frame = hosting.bounds
        let fittingSize = hosting.fittingSize
        panel.setContentSize(fittingSize)

        // Center on active screen (supports multi-monitor setups)
        let screen = activeScreen()
        let screenFrame = screen.visibleFrame
        let panelFrame = panel.frame
        let xPos = screenFrame.midX - panelFrame.width / 2
        let yPos = screenFrame.midY - panelFrame.height / 2
        panel.setFrameOrigin(NSPoint(x: xPos, y: yPos))

        // Show the panel
        panel.orderFrontRegardless()
        window = panel

        // Start monitoring for emergency shortcut
        startEmergencyShortcutMonitoring()
    }

    func hide() {
        stopEmergencyShortcutMonitoring()
        window?.close()
        window = nil
        hostingView = nil
        currentDismissCallback = nil
    }

    // MARK: - Private Methods

    private func handleDismiss() {
        let callback = currentDismissCallback
        hide()
        callback?()
    }

    // MARK: - Emergency Shortcut Monitoring

    /// Start monitoring for ESC key presses (5 consecutive presses within 2 seconds to unlock)
    private func startEmergencyShortcutMonitoring() {
        // Reset ESC counter state
        escPressCount = 0
        lastEscPressTime = nil

        // Monitor key down events for Escape globally (since our panel doesn't take focus)
        let eventMask: NSEvent.EventTypeMask = [.keyDown]
        localEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handleEmergencyShortcutEvent(event)
        }
    }

    /// Stop monitoring for emergency shortcut and reset state
    private func stopEmergencyShortcutMonitoring() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        escPressCount = 0
        lastEscPressTime = nil
    }

    /// Handle keyboard events to detect ESC key presses for emergency unlock
    private func handleEmergencyShortcutEvent(_ event: NSEvent) {
        let escapeKeyCode: UInt16 = 53

        if event.type == .keyDown {
            if event.keyCode == escapeKeyCode {
                // ESC key pressed
                let now = Date()

                // Check if within timeout from last ESC press
                if let lastTime = lastEscPressTime,
                   now.timeIntervalSince(lastTime) <= escTimeoutSeconds {
                    // Within timeout - increment counter
                    escPressCount += 1
                } else {
                    // Timeout expired or first press - reset counter to 1
                    escPressCount = 1
                }

                lastEscPressTime = now

                // Check if we've reached the required number of presses
                if escPressCount >= requiredEscPresses {
                    handleDismiss()
                }
            } else {
                // Non-ESC key pressed - reset counter
                escPressCount = 0
                lastEscPressTime = nil
            }
        }
    }

    /// Determine the active screen where the user is working
    /// Uses the frontmost app's window location to find the correct screen
    /// - Returns: The screen where the user is actively working
    private func activeScreen() -> NSScreen {
        // Try to get screen of key window first
        if let keyWindow = NSApp.keyWindow, let screen = keyWindow.screen {
            return screen
        }

        // Try frontmost app's main window
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            let pid = frontApp.processIdentifier
            let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
            if let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
                for window in windowList {
                    if let ownerPID = window[kCGWindowOwnerPID as String] as? Int32,
                       ownerPID == pid,
                       let bounds = window[kCGWindowBounds as String] as? [String: CGFloat] {
                        let point = CGPoint(x: bounds["X"] ?? 0, y: bounds["Y"] ?? 0)
                        if let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) {
                            return screen
                        }
                    }
                }
            }
        }

        // Default to main screen or first available screen
        return NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }
}
