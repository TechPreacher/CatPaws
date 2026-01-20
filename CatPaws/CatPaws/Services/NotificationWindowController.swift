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

    // Emergency shortcut properties
    private var localEventMonitor: Any?
    private var emergencyShortcutTask: Task<Void, Never>?
    private let emergencyHoldDuration: TimeInterval = 2.0

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

    /// Start monitoring for emergency keyboard shortcut (Cmd+Option+Escape held for 2 seconds)
    private func startEmergencyShortcutMonitoring() {
        // Monitor key down events for Escape with modifiers
        let eventMask: NSEvent.EventTypeMask = [.keyDown, .keyUp, .flagsChanged]
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handleEmergencyShortcutEvent(event)
            return event
        }
    }

    /// Stop monitoring for emergency shortcut
    private func stopEmergencyShortcutMonitoring() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        cancelEmergencyShortcutTimer()
    }

    /// Handle keyboard events to detect emergency shortcut
    private func handleEmergencyShortcutEvent(_ event: NSEvent) {
        // Check for Escape key (keyCode 53) with Command+Option modifiers
        let escapeKeyCode: UInt16 = 53
        let requiredModifiers: NSEvent.ModifierFlags = [.command, .option]

        if event.type == .keyDown && event.keyCode == escapeKeyCode {
            // Check if Command+Option are held
            let currentModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if currentModifiers.contains(requiredModifiers) {
                // Start timer if not already running
                if emergencyShortcutTask == nil {
                    startEmergencyShortcutTimer()
                }
            }
        } else if event.type == .keyUp && event.keyCode == escapeKeyCode {
            // Escape released, cancel timer
            cancelEmergencyShortcutTimer()
        } else if event.type == .flagsChanged {
            // Modifier keys changed, check if Command+Option are still held
            let currentModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if !currentModifiers.contains(requiredModifiers) {
                cancelEmergencyShortcutTimer()
            }
        }
    }

    /// Start the 2-second timer for emergency unlock
    private func startEmergencyShortcutTimer() {
        emergencyShortcutTask = Task { @MainActor [weak self] in
            guard let self = self else { return }

            do {
                try await Task.sleep(nanoseconds: UInt64(self.emergencyHoldDuration * 1_000_000_000))

                // Timer completed - trigger emergency unlock
                if !Task.isCancelled {
                    self.handleDismiss()
                }
            } catch {
                // Task was cancelled, do nothing
            }
        }
    }

    /// Cancel the emergency shortcut timer
    private func cancelEmergencyShortcutTimer() {
        emergencyShortcutTask?.cancel()
        emergencyShortcutTask = nil
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
