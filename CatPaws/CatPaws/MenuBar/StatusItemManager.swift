//
//  StatusItemManager.swift
//  CatPaws
//
//  Created on 2026-01-15.
//
//  Note: This file is kept for potential future use but is currently unused.
//  The app uses SwiftUI's MenuBarExtra instead.
//

import AppKit
import SwiftUI

final class StatusItemManager: NSObject, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?

    override init() {
        super.init()
        setupStatusItem()
        setupPopover()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            // Use custom asset from Assets.xcassets
            if let image = NSImage(named: "MenuBarIcon") {
                image.isTemplate = true
                button.image = image
            }
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 280, height: 200)
        popover?.behavior = .applicationDefined
        popover?.delegate = self
        popover?.contentViewController = NSHostingController(rootView: PopoverView())
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            closePopover()
        } else {
            showPopover(relativeTo: button)
        }
    }

    private func showPopover(relativeTo button: NSStatusBarButton) {
        guard let popover = popover else { return }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        startEventMonitor()
    }

    private func closePopover() {
        popover?.close()
        stopEventMonitor()
    }

    private func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - NSPopoverDelegate

    func popoverDidClose(_ notification: Notification) {
        stopEventMonitor()
    }
}
