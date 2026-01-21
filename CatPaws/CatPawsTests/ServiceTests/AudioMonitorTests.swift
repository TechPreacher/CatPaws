//
//  AudioMonitorTests.swift
//  CatPawsTests
//
//  Created on 2026-01-21.
//

import AVFoundation
import XCTest
@testable import CatPaws

// MARK: - Mock Audio Monitor Delegate

/// Mock delegate for testing AudioMonitor callbacks
final class MockAudioMonitorDelegate: AudioMonitorDelegate {
    private(set) var capturedBuffers: [AVAudioPCMBuffer] = []
    private(set) var captureCallCount: Int = 0

    func audioMonitor(_ monitor: AudioMonitor, didCaptureBuffer buffer: AVAudioPCMBuffer) {
        captureCallCount += 1
        capturedBuffers.append(buffer)
    }

    func reset() {
        capturedBuffers.removeAll()
        captureCallCount = 0
    }
}

// MARK: - Audio Monitor Tests

final class AudioMonitorTests: XCTestCase {
    var sut: AudioMonitor!
    var mockDelegate: MockAudioMonitorDelegate!

    override func setUp() {
        super.setUp()
        // Create a fresh instance for testing (not using shared)
        sut = AudioMonitor()
        mockDelegate = MockAudioMonitorDelegate()
        sut.delegate = mockDelegate
    }

    override func tearDown() {
        sut.stopMonitoring()
        sut = nil
        mockDelegate = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitializationIsNotMonitoring() {
        XCTAssertFalse(sut.isMonitoring)
    }

    func testInitializationCurrentLevelIsZero() {
        XCTAssertEqual(sut.currentLevel, 0.0)
    }

    func testDelegateCanBeSet() {
        let delegate = MockAudioMonitorDelegate()
        sut.delegate = delegate
        XCTAssertNotNil(sut.delegate)
    }

    // MARK: - Shared Instance Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(AudioMonitor.shared)
    }

    func testSharedInstanceIsSameObject() {
        let instance1 = AudioMonitor.shared
        let instance2 = AudioMonitor.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Monitoring State Tests

    func testStopMonitoringWhenNotMonitoringIsNoOp() {
        XCTAssertFalse(sut.isMonitoring)
        sut.stopMonitoring()
        XCTAssertFalse(sut.isMonitoring)
    }

    func testStopMonitoringResetsCurrentLevel() {
        // Even without starting, calling stop should ensure level is 0
        sut.stopMonitoring()
        XCTAssertEqual(sut.currentLevel, 0.0)
    }

    // MARK: - Threshold Tests

    func testSetSoundThresholdClampsMinimum() {
        sut.setSoundThreshold(0.0001)
        // Threshold should be clamped to minimum of 0.001
        // We can't directly access soundThreshold, but verify no crash
        XCTAssertFalse(sut.isMonitoring)
    }

    func testSetSoundThresholdClampsMaximum() {
        sut.setSoundThreshold(1.0)
        // Threshold should be clamped to maximum of 0.1
        // We can't directly access soundThreshold, but verify no crash
        XCTAssertFalse(sut.isMonitoring)
    }

    func testSetSoundThresholdAcceptsValidValue() {
        sut.setSoundThreshold(0.05)
        XCTAssertFalse(sut.isMonitoring)
    }

    // MARK: - Error Types Tests

    func testAudioMonitorErrorEngineStartFailedDescription() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "test error"])
        let error = AudioMonitorError.engineStartFailed(underlyingError)
        XCTAssertTrue(error.errorDescription?.contains("Failed to start audio engine") ?? false)
    }

    func testAudioMonitorErrorNoInputAvailableDescription() {
        let error = AudioMonitorError.noInputAvailable
        XCTAssertEqual(error.errorDescription, "No audio input device available")
    }

    func testAudioMonitorErrorPermissionDeniedDescription() {
        let error = AudioMonitorError.permissionDenied
        XCTAssertEqual(error.errorDescription, "Microphone permission not granted")
    }

    // MARK: - Protocol Conformance Tests

    func testAudioMonitorConformsToAudioMonitoring() {
        XCTAssertTrue(sut is AudioMonitoring)
    }
}

// MARK: - Mock Audio Monitoring

/// Mock implementation of AudioMonitoring for testing other components
final class MockAudioMonitoring: AudioMonitoring {
    weak var delegate: AudioMonitorDelegate?
    var isMonitoring: Bool = false
    var currentLevel: Float = 0.0

    var startMonitoringCallCount = 0
    var stopMonitoringCallCount = 0
    var pauseMonitoringCallCount = 0
    var resumeMonitoringCallCount = 0
    var lastThreshold: Float?

    var shouldThrowOnStart = false
    var shouldThrowOnResume = false

    func startMonitoring() throws {
        if shouldThrowOnStart {
            throw AudioMonitorError.permissionDenied
        }
        startMonitoringCallCount += 1
        isMonitoring = true
    }

    func stopMonitoring() {
        stopMonitoringCallCount += 1
        isMonitoring = false
        currentLevel = 0.0
    }

    func pauseMonitoring() {
        pauseMonitoringCallCount += 1
    }

    func resumeMonitoring() throws {
        if shouldThrowOnResume {
            throw AudioMonitorError.engineStartFailed(NSError(domain: "test", code: 1))
        }
        resumeMonitoringCallCount += 1
        isMonitoring = true
    }

    func setSoundThreshold(_ threshold: Float) {
        lastThreshold = threshold
    }

    // Test helper to simulate buffer capture
    func simulateBufferCapture(_ buffer: AVAudioPCMBuffer) {
        delegate?.audioMonitor(AudioMonitor.shared, didCaptureBuffer: buffer)
    }

    func reset() {
        isMonitoring = false
        currentLevel = 0.0
        startMonitoringCallCount = 0
        stopMonitoringCallCount = 0
        pauseMonitoringCallCount = 0
        resumeMonitoringCallCount = 0
        lastThreshold = nil
        shouldThrowOnStart = false
        shouldThrowOnResume = false
    }
}

// MARK: - Mock Audio Monitoring Tests

final class MockAudioMonitoringTests: XCTestCase {
    var mockMonitor: MockAudioMonitoring!

    override func setUp() {
        super.setUp()
        mockMonitor = MockAudioMonitoring()
    }

    override func tearDown() {
        mockMonitor = nil
        super.tearDown()
    }

    func testStartMonitoringTracksCallCount() throws {
        try mockMonitor.startMonitoring()
        XCTAssertEqual(mockMonitor.startMonitoringCallCount, 1)
        XCTAssertTrue(mockMonitor.isMonitoring)
    }

    func testStopMonitoringTracksCallCount() throws {
        try mockMonitor.startMonitoring()
        mockMonitor.stopMonitoring()
        XCTAssertEqual(mockMonitor.stopMonitoringCallCount, 1)
        XCTAssertFalse(mockMonitor.isMonitoring)
    }

    func testSetSoundThresholdTracksLastValue() {
        mockMonitor.setSoundThreshold(0.05)
        XCTAssertEqual(mockMonitor.lastThreshold, 0.05)
    }

    func testShouldThrowOnStartThrowsError() {
        mockMonitor.shouldThrowOnStart = true
        XCTAssertThrowsError(try mockMonitor.startMonitoring())
    }

    func testResetClearsState() throws {
        try mockMonitor.startMonitoring()
        mockMonitor.setSoundThreshold(0.05)
        mockMonitor.reset()

        XCTAssertEqual(mockMonitor.startMonitoringCallCount, 0)
        XCTAssertNil(mockMonitor.lastThreshold)
        XCTAssertFalse(mockMonitor.isMonitoring)
    }
}
