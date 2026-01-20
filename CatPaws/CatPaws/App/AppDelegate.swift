//
//  AppDelegate.swift
//  CatPaws
//
//  Created on 2026-01-15.
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var onboardingWindow: NSWindow?
    private var onboardingViewModel: OnboardingViewModel?
    private var isTerminating = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check for duplicate instances and quit if another is already running
        if !checkSingleInstance() {
            NSApp.terminate(nil)
            return
        }

        // Migrate onboarding state for users updating from versions without Accessibility step
        OnboardingState.migrateIfNeeded()

        // Ensure the app is properly activated (important when relaunched by System Settings)
        NSApp.activate(ignoringOtherApps: true)

        // Show onboarding if not completed
        showOnboardingIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        isTerminating = true
    }

    // MARK: - Single Instance Check

    /// Check if this is the only running instance of CatPaws
    /// - Returns: true if this is the only instance, false if another is already running
    private func checkSingleInstance() -> Bool {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            return true
        }
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)

        // Filter to only count apps that are not terminating and not this instance
        let activeInstances = runningApps.filter { app in
            !app.isTerminated && app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        }

        // Allow if no other active instances
        return activeInstances.isEmpty
    }

    // MARK: - Onboarding

    /// Show onboarding window if the user hasn't completed it
    private func showOnboardingIfNeeded() {
        let onboardingState = OnboardingState()
        guard !onboardingState.hasCompletedOnboarding else { return }

        Task { @MainActor in
            showOnboardingWindow()
        }
    }

    /// Present the onboarding window
    @MainActor
    func showOnboardingWindow() {
        // Create view model
        let viewModel = OnboardingViewModel()
        viewModel.onComplete = { [weak self] in
            self?.closeOnboardingWindow()
        }
        self.onboardingViewModel = viewModel

        // Create the SwiftUI view
        let onboardingView = OnboardingView(viewModel: viewModel)

        // Create and configure window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to CatPaws"
        window.contentView = NSHostingView(rootView: onboardingView)
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self

        self.onboardingWindow = window

        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Close the onboarding window
    private func closeOnboardingWindow() {
        onboardingWindow?.close()
        onboardingWindow = nil
        onboardingViewModel = nil
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window === onboardingWindow else { return }

        // If window is closed without completing, mark as skipped
        // BUT only if the app is not terminating (user manually closed the window)
        if !isTerminating, let viewModel = onboardingViewModel {
            if viewModel.currentStep != .complete {
                var state = OnboardingState()
                state.skip()
            }
        }

        onboardingWindow = nil
        onboardingViewModel = nil
    }
}
