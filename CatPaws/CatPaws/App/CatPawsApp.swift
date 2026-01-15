//
//  CatPawsApp.swift
//  CatPaws
//
//  Created on 2026-01-15.
//

import SwiftUI

@main
struct CatPawsApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(viewModel: viewModel)
        } label: {
            Image(systemName: "pawprint")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}

// Note: AppDelegate is kept for potential future use (e.g., handling URLs, notifications)
