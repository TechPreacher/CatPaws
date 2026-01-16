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
        hosting.frame = panel.contentView!.bounds
        let fittingSize = hosting.fittingSize
        panel.setContentSize(fittingSize)

        // Center on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelFrame = panel.frame
            let x = screenFrame.midX - panelFrame.width / 2
            let y = screenFrame.midY - panelFrame.height / 2
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // Show the panel
        panel.orderFrontRegardless()
        window = panel
    }

    func hide() {
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
}
