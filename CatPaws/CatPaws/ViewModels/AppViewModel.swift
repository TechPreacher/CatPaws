//
//  AppViewModel.swift
//  CatPaws
//
//  Created on 2026-01-15.
//

import Foundation
import AVFoundation
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

    /// Current state of both permissions (Accessibility and Input Monitoring)
    @Published private(set) var permissionState = PermissionState()

    /// Whether to show the permission revocation banner
    @Published var showPermissionRevokedBanner: Bool = false

    // MARK: - Services

    private let keyboardMonitor: KeyboardMonitor
    private let configuration: Configuration
    private let catDetectionService: CatDetectionService
    private let lockStateManager: LockStateManager
    private let lockService: KeyboardLockService
    private let notificationController: NotificationWindowController
    let statisticsService: StatisticsService
    private let permissionService: PermissionService

    // MARK: - Purr Detection Services

    private let audioMonitor: AudioMonitor
    private let purrDetectionService: PurrDetectionService
    private var isPurrDetectionInitialized: Bool = false

    // MARK: - Private

    private var keyboardState: KeyboardState
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
        self.permissionService = PermissionService.shared
        self.audioMonitor = AudioMonitor.shared
        self.purrDetectionService = PurrDetectionService()

        // Initialize KeyboardState with time window from configuration
        let timeWindowSeconds = TimeInterval(configuration.detectionTimeWindowMs) / 1000.0
        self.keyboardState = KeyboardState(timeWindowSeconds: timeWindowSeconds)

        // Wire up services
        setupServices()
        setupBindings()
        setupPermissionMonitoring()
        setupPurrDetection()

        // Check permission and start polling if needed
        hasPermission = hasInputMonitoringPermission()
        updatePermissionState()
        updateIconState()
        updatePermissionPolling()

        // Auto-start monitoring if conditions are met
        autoStartMonitoringIfNeeded()
    }

    deinit {
        permissionPollingTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// Toggle the active state of the application
    func toggleActive() {
        appState.isActive.toggle()

        if appState.isActive {
            // User explicitly enabled - clear the disabled flag
            configuration.hasUserExplicitlyDisabled = false
            startMonitoring()
        } else {
            // User explicitly disabled - set the flag
            configuration.hasUserExplicitlyDisabled = true
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

    /// Manually unlock the keyboard
    func manualUnlock() {
        lockStateManager.manualUnlock()
    }

    /// Auto-start monitoring if conditions are met (permission granted, not explicitly disabled)
    /// Called on app launch and after onboarding completion
    func autoStartMonitoringIfNeeded() {
        // Only auto-start if:
        // 1. User has not explicitly disabled monitoring
        // 2. Permission is granted
        // 3. Not already monitoring
        guard configuration.shouldAutoEnable,
              hasPermission,
              !appState.isActive else {
            return
        }

        // Auto-enable monitoring
        appState.isActive = true
        startMonitoring()
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
                guard let self = self else { return }
                self.catDetectionService.minimumKeyCount = self.configuration.minimumKeyCount

                // Update KeyboardState time window if it changed
                let newTimeWindowSeconds = TimeInterval(self.configuration.detectionTimeWindowMs) / 1000.0
                if self.keyboardState.timeWindowSeconds != newTimeWindowSeconds {
                    // Reinitialize KeyboardState with new time window, preserving current state
                    self.keyboardState = KeyboardState(
                        pressedKeys: self.keyboardState.pressedKeys,
                        activeModifiers: self.keyboardState.activeModifiers,
                        lastKeyEventTime: self.keyboardState.lastKeyEventTime,
                        recentKeyPresses: [],  // Clear recent presses as window changed
                        timeWindowSeconds: newTimeWindowSeconds
                    )
                }
            }
            .store(in: &cancellables)
    }

    /// Set up permission service to monitor for state changes
    private func setupPermissionMonitoring() {
        permissionService.onStateChange = { [weak self] newState in
            Task { @MainActor in
                self?.handlePermissionStateChange(newState)
            }
        }
        permissionService.startPolling()
    }

    /// Update the local permission state from the service
    private func updatePermissionState() {
        permissionState = permissionService.getCurrentState()
    }

    /// Handle permission state changes from the service
    private func handlePermissionStateChange(_ newState: PermissionState) {
        let previousAllGranted = permissionState.allGranted
        permissionState = newState
        hasPermission = newState.inputMonitoring.isGranted

        // Check for revocation
        if previousAllGranted && newState.anyMissing {
            showPermissionRevokedBanner = true
            handlePermissionRevoked()
        }

        updateIconState()
    }

    /// Dismiss the permission revocation banner
    func dismissPermissionRevokedBanner() {
        showPermissionRevokedBanner = false
    }

    /// Open settings for a specific permission type
    func openSettings(for type: PermissionType) {
        permissionService.openSettings(for: type)
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
        // Use keysForDetection which combines currently pressed keys with keys pressed
        // within the time window, enabling detection of rapid sequential cat paw presses
        let keysForDetection = keyboardState.keysForDetection

        // Run detection
        if let detection = catDetectionService.analyzePattern(pressedKeys: keysForDetection) {
            lockStateManager.handleDetection(detection)
        } else if lockStateManager.state.status == .debouncing &&
                    keysForDetection.count < configuration.minimumKeyCount {
            // Not enough keys anymore, cancel debounce
            lockStateManager.handleKeysReleased()
        }
    }

    // MARK: - Purr Detection

    /// Set up purr detection based on configuration
    private func setupPurrDetection() {
        // Set delegate for audio callbacks
        audioMonitor.delegate = self

        // Observe purr detection configuration changes
        configuration.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updatePurrDetectionState()
            }
            .store(in: &cancellables)

        // Initialize if already enabled
        if configuration.purrDetectionEnabled {
            Task {
                await initializePurrDetection()
            }
        }
    }

    /// Initialize the purr detection service
    private func initializePurrDetection() async {
        guard !isPurrDetectionInitialized else { return }

        do {
            try await purrDetectionService.initialize()
            isPurrDetectionInitialized = true
            purrDetectionService.setSensitivity(Float(configuration.purrSensitivity))
            audioMonitor.setSoundThreshold(Float(configuration.purrSoundThreshold))

            // Start monitoring if enabled and has microphone permission
            if configuration.purrDetectionEnabled && permissionService.checkMicrophone() {
                startPurrDetection()
            }
        } catch {
            // Log error but don't crash
            if configuration.debugLoggingEnabled {
                print("[CatPaws] Failed to initialize purr detection: \(error)")
            }
        }
    }

    /// Update purr detection state based on configuration
    private func updatePurrDetectionState() {
        purrDetectionService.setSensitivity(Float(configuration.purrSensitivity))
        audioMonitor.setSoundThreshold(Float(configuration.purrSoundThreshold))

        if configuration.purrDetectionEnabled {
            if !isPurrDetectionInitialized {
                Task {
                    await initializePurrDetection()
                }
            } else if permissionService.checkMicrophone() {
                startPurrDetection()
            }
        } else {
            stopPurrDetection()
        }
    }

    /// Start purr detection audio monitoring
    private func startPurrDetection() {
        guard isPurrDetectionInitialized,
              configuration.purrDetectionEnabled,
              !audioMonitor.isMonitoring else { return }

        do {
            try audioMonitor.startMonitoring()
        } catch {
            if configuration.debugLoggingEnabled {
                print("[CatPaws] Failed to start purr detection: \(error)")
            }
        }
    }

    /// Stop purr detection audio monitoring
    private func stopPurrDetection() {
        if audioMonitor.isMonitoring {
            audioMonitor.stopMonitoring()
        }
    }

    /// Handle a purr detection event
    private func handlePurrDetection(_ result: PurrDetectionResult) {
        guard result.detected else { return }

        // Create a detection event for purr
        let detection = DetectionEvent(
            type: .purr,
            keyCount: 0,
            timestamp: result.timestamp,
            triggeredLock: false
        )

        // Send to lock state manager
        lockStateManager.handleDetection(detection)
    }
}

// MARK: - KeyboardMonitorDelegate

extension AppViewModel: KeyboardMonitorDelegate {
    nonisolated func keyDidPress(_ keyCode: UInt16, at timestamp: Date) {
        Task { @MainActor in
            keyboardState.keyPressed(keyCode, at: timestamp)
            analyzeCurrentKeys()
        }
    }

    nonisolated func keyDidRelease(_ keyCode: UInt16, at timestamp: Date) {
        Task { @MainActor in
            keyboardState.keyReleased(keyCode)
            // Lock persists until manual dismiss - no auto-unlock on key release
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

// MARK: - AudioMonitorDelegate

extension AppViewModel: AudioMonitorDelegate {
    nonisolated func audioMonitor(_ monitor: AudioMonitor, didCaptureBuffer buffer: AVAudioPCMBuffer) {
        Task { @MainActor in
            // Analyze buffer for purr detection
            let result = await purrDetectionService.detectPurr(audioBuffer: buffer)
            handlePurrDetection(result)
        }
    }
}
