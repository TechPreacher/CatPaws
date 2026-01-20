//
//  CatPawsApp.swift
//  CatPaws
//
//  Created on 2026-01-15.
//

import SwiftUI

@main
struct CatPawsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(viewModel: viewModel)
        } label: {
            MenuBarIconView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
        .onChange(of: appDelegate.onboardingDidComplete) { _, completed in
            if completed {
                viewModel.autoStartMonitoringIfNeeded()
            }
        }

        Settings {
            SettingsView()
        }
    }
}

/// Menu bar icon view that updates based on app state
struct MenuBarIconView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        Image(nsImage: menuBarImage)
    }

    private var menuBarImage: NSImage {
        let imageName: String
        if !viewModel.hasPermission {
            imageName = "MenuBarIconDisabled"
        } else if viewModel.isMonitoring {
            imageName = "MenuBarIconActive"
        } else {
            imageName = "MenuBarIcon"
        }

        if let image = NSImage(named: imageName) {
            // Mark as template so macOS applies proper menu bar styling
            image.isTemplate = true
            return image
        }

        // Fallback to SF Symbol if asset not found
        return NSImage(
            systemSymbolName: "pawprint",
            accessibilityDescription: "CatPaws"
        ) ?? NSImage()
    }
}

// AppDelegate handles onboarding, single-instance check, and other app lifecycle events
