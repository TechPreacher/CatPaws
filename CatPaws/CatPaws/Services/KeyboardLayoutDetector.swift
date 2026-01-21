//
//  KeyboardLayoutDetector.swift
//  CatPaws
//
//  Created on 2026-01-18.
//

import Carbon
import Combine
import Foundation

/// Protocol for detecting keyboard layout changes
protocol KeyboardLayoutDetecting {
    /// The currently detected keyboard layout
    var currentLayout: KeyboardAdjacencyMap.Layout { get }

    /// Publisher that emits when the keyboard layout changes
    var layoutChanged: AnyPublisher<KeyboardAdjacencyMap.Layout, Never> { get }

    /// Start observing keyboard layout changes
    func startObserving()

    /// Stop observing keyboard layout changes
    func stopObserving()
}

/// Service that detects the current keyboard layout and monitors for changes
final class KeyboardLayoutDetector: KeyboardLayoutDetecting {
    // MARK: - Properties

    /// The currently detected keyboard layout
    private(set) var currentLayout: KeyboardAdjacencyMap.Layout = .qwerty

    /// Subject for publishing layout changes
    private let layoutChangedSubject = PassthroughSubject<KeyboardAdjacencyMap.Layout, Never>()

    /// Publisher that emits when the keyboard layout changes
    var layoutChanged: AnyPublisher<KeyboardAdjacencyMap.Layout, Never> {
        layoutChangedSubject.eraseToAnyPublisher()
    }

    /// Observer token for layout change notifications
    private var notificationObserver: NSObjectProtocol?

    // MARK: - Initialization

    init() {
        // Detect initial layout
        currentLayout = detectCurrentLayout()
    }

    deinit {
        stopObserving()
    }

    // MARK: - Public Methods

    /// Start observing keyboard layout changes
    func startObserving() {
        guard notificationObserver == nil else { return }

        // Listen for input source changes using DistributedNotificationCenter
        notificationObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleLayoutChange()
        }
    }

    /// Stop observing keyboard layout changes
    func stopObserving() {
        if let observer = notificationObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
            notificationObserver = nil
        }
    }

    // MARK: - Private Methods

    /// Handle layout change notification
    private func handleLayoutChange() {
        let newLayout = detectCurrentLayout()
        if newLayout != currentLayout {
            currentLayout = newLayout
            layoutChangedSubject.send(newLayout)
        }
    }

    /// Detect the current keyboard layout from the system
    /// - Returns: The detected layout type
    private func detectCurrentLayout() -> KeyboardAdjacencyMap.Layout {
        guard let identifier = currentKeyboardLayoutIdentifier() else {
            return .qwerty
        }
        return KeyboardAdjacencyMap.Layout.from(inputSourceId: identifier)
    }

    /// Get the current keyboard input source identifier
    /// - Returns: The input source ID string (e.g., "com.apple.keylayout.French")
    private func currentKeyboardLayoutIdentifier() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }
        guard let idRef = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
            return nil
        }
        return Unmanaged<CFString>.fromOpaque(idRef).takeUnretainedValue() as String
    }
}

// MARK: - Shared Instance

extension KeyboardLayoutDetector {
    /// Shared singleton instance
    static let shared = KeyboardLayoutDetector()
}
