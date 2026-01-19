//
//  AppViewModel.swift
//  CatPaws
//
//  Created on 2026-01-15.
//

import Foundation
import Combine
import CoreGraphics

/// Menu bar icon state
enum MenuBarIconState {
    /// Unlocked state - outlined paw
    case unlocked
    /// Locked state - filled paw
    case locked
    /// Disabled state - grayed paw
    case disabled

    var systemImageName: String {
        switch self {
        case .unlocked:
            return "pawprint"
        case .locked:
            return "pawprint.fill"
        case .disabled:
            return "pawprint"
        }
    }

    var isGrayed: Bool {
        self == .disabled
    }
}

/// Main view model for the application
@MainActor
final class AppViewModel: ObservableObject {
    // MARK: - Published State

    @Published var appState: AppState
    @Published private(set) var iconState: MenuBarIconState = .unlocked
    @Published private(set) var hasPermission: Bool = false
    @Published private(set) var isLocked: Bool = false
    @Published private(set) var isMonitoring: Bool = false

    // MARK: - Services

    let keyboardMonitor: KeyboardMonitor
    let configuration: Configuration
    let catDetectionService: CatDetectionService
    let lockStateManager: LockStateManager
    let lockService: KeyboardLockService
    let notificationController: NotificationWindowController
    let statisticsService: StatisticsService

    // MARK: - Private

    private var keyboardState = KeyboardState()
    private var cancellables = Set<AnyCancellable>()
    private var permissionPollingTimer: Timer?
    private static let permissionPollingInterval: TimeInterval = 2.0

    // MARK: - Initialization

    init() {
        self.appState = AppState()

        // Initialize services
        self.keyboardMonitor = KeyboardMonitor.shared
        self.configuration = Configuration()
        self.catDetectionService = CatDetectionService()
        self.lockStateManager = LockStateManager()
        self.lockService = KeyboardLockService()
        self.notificationController = NotificationWindowController()
        self.statisticsService = StatisticsService()

        // Wire up services
        setupServices()
        setupBindings()

        // Check permission and start polling if needed
        hasPermission = hasInputMonitoringPermission()
        updateIconState()
        updatePermissionPolling()
    }

    deinit {
        permissionPollingTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// Toggle the active state of the application
    func toggleActive() {
        appState.isActive.toggle()

        if appState.isActive {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }

    /// Reset the application state to defaults
    func resetState() {
        appState = AppState()
        configuration.resetToDefaults()
    }

    /// Check if Input Monitoring permission is granted
    func hasInputMonitoringPermission() -> Bool {
        CGPreflightListenEventAccess()
    }

    /// Request accessibility permission
    func requestPermission() {
        keyboardMonitor.requestPermission()
        // Check again after a delay
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                self.hasPermission = self.hasInputMonitoringPermission()
                self.updateIconState()
                self.updatePermissionPolling()
            }
        }
    }

    /// Open System Settings to grant permission
    func openPermissionSettings() {
        PermissionGuideView.openInputMonitoringSettings()
    }

    /// Manually unlock the keyboard
    func manualUnlock() {
        lockStateManager.manualUnlock()
    }

    // MARK: - Private Methods

    private func setupServices() {
        // Connect lock service to keyboard monitor
        keyboardMonitor.lockService = lockService

        // Connect lock service to state manager
        lockStateManager.lockService = lockService
        lockStateManager.notificationPresenter = notificationController
        lockStateManager.configuration = configuration
        lockStateManager.statisticsService = statisticsService
        lockStateManager.delegate = self

        // Configure detection service
        catDetectionService.minimumKeyCount = configuration.minimumKeyCount
    }

    private func setupBindings() {
        // Observe configuration changes
        configuration.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.catDetectionService.minimumKeyCount = self?.configuration.minimumKeyCount ?? 3
            }
            .store(in: &cancellables)
    }

    private func startMonitoring() {
        guard hasPermission else {
            requestPermission()
            return
        }

        do {
            keyboardMonitor.delegate = self
            try keyboardMonitor.startMonitoring()
            isMonitoring = true
            updateIconState()
        } catch {
            // Monitoring failed - likely permission issue
            isMonitoring = false
            appState.isActive = false
        }
    }

    private func stopMonitoring() {
        keyboardMonitor.stopMonitoring()
        keyboardMonitor.delegate = nil
        keyboardState.clearAll()
        isMonitoring = false
        updateIconState()
    }

    private func updateIconState() {
        if !appState.isActive || !hasPermission {
            iconState = .disabled
        } else if isLocked {
            iconState = .locked
        } else {
            iconState = .unlocked
        }
    }

    /// Start or stop permission polling based on current permission status
    private func updatePermissionPolling() {
        if hasPermission {
            // Permission granted - stop polling
            stopPermissionPolling()
        } else {
            // Permission not granted - start polling
            startPermissionPolling()
        }
    }

    /// Start polling for permission status changes
    private func startPermissionPolling() {
        guard permissionPollingTimer == nil else { return }

        permissionPollingTimer = Timer.scheduledTimer(
            withTimeInterval: Self.permissionPollingInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermissionStatus()
            }
        }
    }

    /// Stop polling for permission status changes
    private func stopPermissionPolling() {
        permissionPollingTimer?.invalidate()
        permissionPollingTimer = nil
    }

    /// Check current permission status and handle changes
    private func checkPermissionStatus() {
        let currentPermission = hasInputMonitoringPermission()

        if currentPermission != hasPermission {
            hasPermission = currentPermission
            updateIconState()

            if currentPermission {
                // Permission was granted - stop polling
                stopPermissionPolling()
            } else {
                // Permission was revoked - stop monitoring
                handlePermissionRevoked()
            }
        }
    }

    /// Handle permission being revoked while the app is running
    private func handlePermissionRevoked() {
        // Stop monitoring if active
        if appState.isActive {
            stopMonitoring()
            appState.isActive = false
        }

        // Start polling to detect when permission is re-granted
        startPermissionPolling()
    }

    private func analyzeCurrentKeys() {
        // Filter non-modifier keys
        let nonModifierKeys = keyboardState.nonModifierKeys

        // Run detection
        if let detection = catDetectionService.analyzePattern(pressedKeys: nonModifierKeys) {
            lockStateManager.handleDetection(detection)
        } else if lockStateManager.state.status == .debouncing &&
                    nonModifierKeys.count < configuration.minimumKeyCount {
            // Not enough keys anymore, cancel debounce
            lockStateManager.handleKeysReleased()
        }
    }
}

// MARK: - KeyboardMonitorDelegate

extension AppViewModel: KeyboardMonitorDelegate {
    nonisolated func keyDidPress(_ keyCode: UInt16, at timestamp: Date) {
        Task { @MainActor in
            keyboardState.keyPressed(keyCode)
            analyzeCurrentKeys()
        }
    }

    nonisolated func keyDidRelease(_ keyCode: UInt16, at timestamp: Date) {
        Task { @MainActor in
            keyboardState.keyReleased(keyCode)

            // Check for auto-unlock if we're locked
            if lockStateManager.state.status == .locked {
                lockStateManager.performRecheck(pressedKeyCount: keyboardState.nonModifierKeys.count)
            }
        }
    }

    nonisolated func modifiersDidChange(_ modifiers: Set<UInt16>, at timestamp: Date) {
        Task { @MainActor in
            keyboardState.updateModifiers(modifiers)
        }
    }
}

// MARK: - LockStateManagerDelegate

extension AppViewModel: LockStateManagerDelegate {
    nonisolated func lockStateManagerDidLock(_ manager: LockStateManager) {
        Task { @MainActor in
            isLocked = true
            updateIconState()
        }
    }

    nonisolated func lockStateManagerDidUnlock(_ manager: LockStateManager) {
        Task { @MainActor in
            isLocked = false
            updateIconState()
        }
    }
}
