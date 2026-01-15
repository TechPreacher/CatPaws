//
//  AppViewModel.swift
//  CatPaws
//
//  Created on 2026-01-15.
//

import Foundation
import Combine

/// Main view model for the application
@MainActor
final class AppViewModel: ObservableObject {
    @Published var appState: AppState

    init() {
        self.appState = AppState()
    }

    /// Toggle the active state of the application
    func toggleActive() {
        appState.isActive.toggle()
    }

    /// Reset the application state to defaults
    func resetState() {
        appState = AppState()
    }
}
