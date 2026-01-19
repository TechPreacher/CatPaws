//
//  KeyboardMonitor.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Foundation
import CoreGraphics
import AppKit

/// Monitors keyboard events at the system level using CGEvent tap
final class KeyboardMonitor: KeyboardMonitoring {
    // MARK: - Properties

    weak var delegate: KeyboardMonitorDelegate?

    private(set) var isMonitoring: Bool = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// Currently pressed keys (for tracking state)
    private(set) var pressedKeys: Set<UInt16> = []

    /// Lock service reference for blocking events
    var lockService: KeyboardLocking?

    // MARK: - Singleton

    static let shared = KeyboardMonitor()

    private init() {}

    // MARK: - KeyboardMonitoring

    func hasPermission() -> Bool {
        let hasAccess = CGPreflightListenEventAccess()
        return hasAccess
    }

    func requestPermission() {
        AppLogger.logPermissionCheck("requesting input monitoring access")
        CGRequestListenEventAccess()
    }

    func openPermissionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }

    func startMonitoring() throws {
        guard !isMonitoring else { return }

        guard hasPermission() else {
            AppLogger.logPermissionChange(granted: false)
            throw PermissionError.accessibilityNotGranted
        }

        AppLogger.logPermissionChange(granted: true)

        // Event mask for keyboard events
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) |
                                      (1 << CGEventType.keyUp.rawValue) |
                                      (1 << CGEventType.flagsChanged.rawValue)

        // Store self reference for callback
        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        // Create event tap
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,  // Can modify/block events
            eventsOfInterest: eventMask,
            callback: keyboardCallback,
            userInfo: userInfo
        ) else {
            throw PermissionError.eventTapCreationFailed
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }

        CGEvent.tapEnable(tap: tap, enable: true)
        isMonitoring = true
    }

    func stopMonitoring() {
        guard isMonitoring else { return }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        pressedKeys.removeAll()
        isMonitoring = false
    }

    // MARK: - Internal Event Handling

    fileprivate func handleKeyDown(_ keyCode: UInt16) {
        pressedKeys.insert(keyCode)
        delegate?.keyDidPress(keyCode, at: Date())
    }

    fileprivate func handleKeyUp(_ keyCode: UInt16) {
        pressedKeys.remove(keyCode)
        delegate?.keyDidRelease(keyCode, at: Date())
    }

    fileprivate func handleModifierChange(_ keyCode: UInt16, flags: CGEventFlags) {
        // Determine which modifiers are currently active
        var activeModifiers: Set<UInt16> = []

        if flags.contains(.maskShift) {
            activeModifiers.insert(0x38)  // Left Shift
        }
        if flags.contains(.maskControl) {
            activeModifiers.insert(0x3B)  // Left Control
        }
        if flags.contains(.maskAlternate) {
            activeModifiers.insert(0x3A)  // Left Option
        }
        if flags.contains(.maskCommand) {
            activeModifiers.insert(0x37)  // Left Command
        }

        delegate?.modifiersDidChange(activeModifiers, at: Date())
    }

    fileprivate func reEnableTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }

    fileprivate func shouldBlockEvent() -> Bool {
        lockService?.isLocked ?? false
    }
}

// MARK: - CGEvent Callback

/// Global callback function for CGEvent tap
private func keyboardCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    // Handle tap being disabled by system timeout
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let userInfo = userInfo {
            let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(userInfo).takeUnretainedValue()
            monitor.reEnableTap()
        }
        return Unmanaged.passUnretained(event)
    }

    guard let userInfo = userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
    let flags = event.flags

    switch type {
    case .keyDown:
        monitor.handleKeyDown(keyCode)

        // Block event if keyboard is locked
        if monitor.shouldBlockEvent() {
            return nil
        }

    case .keyUp:
        monitor.handleKeyUp(keyCode)

        // Block event if keyboard is locked
        if monitor.shouldBlockEvent() {
            return nil
        }

    case .flagsChanged:
        monitor.handleModifierChange(keyCode, flags: flags)

        // Block modifier events if locked
        if monitor.shouldBlockEvent() {
            return nil
        }

    default:
        break
    }

    return Unmanaged.passUnretained(event)
}
