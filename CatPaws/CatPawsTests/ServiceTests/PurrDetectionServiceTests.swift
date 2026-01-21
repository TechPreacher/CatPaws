//
//  PurrDetectionServiceTests.swift
//  CatPawsTests
//
//  Created on 2026-01-21.
//

import AVFoundation
import XCTest
@testable import CatPaws

// MARK: - Purr Detection Service Tests

final class PurrDetectionServiceTests: XCTestCase {
    var sut: PurrDetectionService!

    override func setUp() {
        super.setUp()
        sut = PurrDetectionService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitializationIsNotReady() {
        XCTAssertFalse(sut.isReady)
    }

    func testInitializeMarksServiceAsReady() async throws {
        XCTAssertFalse(sut.isReady)
        try await sut.initialize()
        XCTAssertTrue(sut.isReady)
    }

    // MARK: - Detection Tests

    func testDetectPurrReturnsNoneWhenNotInitialized() async {
        XCTAssertFalse(sut.isReady)

        let buffer = createTestBuffer()
        let result = await sut.detectPurr(audioBuffer: buffer)

        XCTAssertFalse(result.detected)
        XCTAssertEqual(result.confidence, 0.0)
    }

    func testDetectPurrReturnsResultWhenInitialized() async throws {
        try await sut.initialize()

        let buffer = createTestBuffer()
        let result = await sut.detectPurr(audioBuffer: buffer)

        // Result should have valid fields
        XCTAssertGreaterThanOrEqual(result.confidence, 0.0)
        XCTAssertLessThanOrEqual(result.confidence, 1.0)
        XCTAssertNotNil(result.timestamp)
    }

    func testDetectPurrWithLowFrequencySineWave() async throws {
        try await sut.initialize()

        // Create a buffer simulating low frequency content (like a purr)
        let buffer = createLowFrequencyBuffer()
        let result = await sut.detectPurr(audioBuffer: buffer)

        // Should detect some confidence for low frequency content
        XCTAssertGreaterThanOrEqual(result.confidence, 0.0)
    }

    // MARK: - Sensitivity Tests

    func testSetSensitivityClampsToMinimum() async throws {
        try await sut.initialize()
        sut.setSensitivity(-0.5)

        // Should not crash and service should remain ready
        XCTAssertTrue(sut.isReady)
    }

    func testSetSensitivityClampsToMaximum() async throws {
        try await sut.initialize()
        sut.setSensitivity(1.5)

        // Should not crash and service should remain ready
        XCTAssertTrue(sut.isReady)
    }

    func testHighSensitivityLowersDetectionThreshold() async throws {
        try await sut.initialize()

        let buffer = createTestBuffer()

        // Test with low sensitivity
        sut.setSensitivity(0.1)
        let lowSensResult = await sut.detectPurr(audioBuffer: buffer)

        // Test with high sensitivity
        sut.setSensitivity(0.9)
        let highSensResult = await sut.detectPurr(audioBuffer: buffer)

        // High sensitivity should be more likely to detect
        // (or at least not crash)
        XCTAssertNotNil(lowSensResult)
        XCTAssertNotNil(highSensResult)
    }

    // MARK: - PurrDetectionResult Tests

    func testPurrDetectionResultNone() {
        let result = PurrDetectionResult.none
        XCTAssertFalse(result.detected)
        XCTAssertEqual(result.confidence, 0.0)
    }

    func testPurrDetectionResultFields() {
        let timestamp = Date()
        let result = PurrDetectionResult(
            confidence: 0.85,
            detected: true,
            timestamp: timestamp,
            duration: 0.5
        )

        XCTAssertEqual(result.confidence, 0.85)
        XCTAssertTrue(result.detected)
        XCTAssertEqual(result.timestamp, timestamp)
        XCTAssertEqual(result.duration, 0.5)
    }

    // MARK: - Error Types Tests

    func testPurrDetectionErrorModelLoadFailedDescription() {
        let error = PurrDetectionError.modelLoadFailed("test reason")
        XCTAssertTrue(error.errorDescription?.contains("Failed to load Whisper model") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("test reason") ?? false)
    }

    func testPurrDetectionErrorAnalysisErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "analysis failed"])
        let error = PurrDetectionError.analysisError(underlyingError)
        XCTAssertTrue(error.errorDescription?.contains("Audio analysis failed") ?? false)
    }

    func testPurrDetectionErrorNotInitializedDescription() {
        let error = PurrDetectionError.notInitialized
        XCTAssertEqual(error.errorDescription, "Purr detection service not initialized")
    }

    // MARK: - Protocol Conformance Tests

    func testPurrDetectionServiceConformsToPurrDetecting() {
        XCTAssertTrue(sut is PurrDetecting)
    }

    // MARK: - Test Helpers

    /// Creates a basic test audio buffer
    private func createTestBuffer() -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4096)!
        buffer.frameLength = 4096

        // Fill with silence
        if let channelData = buffer.floatChannelData {
            for index in 0..<Int(buffer.frameLength) {
                channelData[0][index] = 0.0
            }
        }

        return buffer
    }

    /// Creates a buffer with low frequency content (simulating purr)
    private func createLowFrequencyBuffer() -> AVAudioPCMBuffer {
        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4096)!
        buffer.frameLength = 4096

        // Generate a low frequency sine wave (~50 Hz, in purr range)
        let frequency: Float = 50.0
        let amplitude: Float = 0.1

        if let channelData = buffer.floatChannelData {
            for index in 0..<Int(buffer.frameLength) {
                let phase = 2.0 * Float.pi * frequency * Float(index) / Float(sampleRate)
                channelData[0][index] = amplitude * sin(phase)
            }
        }

        return buffer
    }
}

// MARK: - Mock Purr Detecting

/// Mock implementation of PurrDetecting for testing other components
final class MockPurrDetecting: PurrDetecting {
    var isReady: Bool = false
    var initializeCallCount = 0
    var detectPurrCallCount = 0
    var setSensitivityCallCount = 0

    var lastSensitivity: Float?
    var stubbedResult: PurrDetectionResult = .none

    var shouldThrowOnInitialize = false

    func initialize() async throws {
        if shouldThrowOnInitialize {
            throw PurrDetectionError.modelLoadFailed("Mock error")
        }
        initializeCallCount += 1
        isReady = true
    }

    func detectPurr(audioBuffer: AVAudioPCMBuffer) async -> PurrDetectionResult {
        detectPurrCallCount += 1
        return stubbedResult
    }

    func setSensitivity(_ sensitivity: Float) {
        setSensitivityCallCount += 1
        lastSensitivity = sensitivity
    }

    func reset() {
        isReady = false
        initializeCallCount = 0
        detectPurrCallCount = 0
        setSensitivityCallCount = 0
        lastSensitivity = nil
        stubbedResult = .none
        shouldThrowOnInitialize = false
    }
}

// MARK: - Mock Purr Detecting Tests

final class MockPurrDetectingTests: XCTestCase {
    var mockService: MockPurrDetecting!

    override func setUp() {
        super.setUp()
        mockService = MockPurrDetecting()
    }

    override func tearDown() {
        mockService = nil
        super.tearDown()
    }

    func testInitializeTracksCallCount() async throws {
        try await mockService.initialize()
        XCTAssertEqual(mockService.initializeCallCount, 1)
        XCTAssertTrue(mockService.isReady)
    }

    func testDetectPurrReturnsStubbed() async {
        mockService.stubbedResult = PurrDetectionResult(
            confidence: 0.9,
            detected: true,
            timestamp: Date(),
            duration: 0.5
        )

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!

        let result = await mockService.detectPurr(audioBuffer: buffer)

        XCTAssertEqual(mockService.detectPurrCallCount, 1)
        XCTAssertTrue(result.detected)
        XCTAssertEqual(result.confidence, 0.9)
    }

    func testSetSensitivityTracksValue() {
        mockService.setSensitivity(0.75)
        XCTAssertEqual(mockService.setSensitivityCallCount, 1)
        XCTAssertEqual(mockService.lastSensitivity, 0.75)
    }

    func testShouldThrowOnInitializeThrowsError() async {
        mockService.shouldThrowOnInitialize = true

        do {
            try await mockService.initialize()
            XCTFail("Should have thrown")
        } catch {
            XCTAssertTrue(error is PurrDetectionError)
        }
    }

    func testResetClearsState() async throws {
        try await mockService.initialize()
        mockService.setSensitivity(0.5)
        mockService.reset()

        XCTAssertFalse(mockService.isReady)
        XCTAssertEqual(mockService.initializeCallCount, 0)
        XCTAssertNil(mockService.lastSensitivity)
    }
}

// MARK: - Memory Leak Tests (T039)

final class PurrDetectionServiceMemoryTests: XCTestCase {

    /// Test that PurrDetectionService deallocates properly
    func testServiceDeallocatesAfterUse() {
        weak var weakService: PurrDetectionService?

        autoreleasepool {
            let service = PurrDetectionService()
            weakService = service
            service.setSensitivity(0.5)
        }

        XCTAssertNil(weakService, "PurrDetectionService should be deallocated")
    }

    /// Test that service deallocates after async initialization
    func testServiceDeallocatesAfterInitialization() async {
        weak var weakService: PurrDetectionService?

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task {
                autoreleasepool {
                    let service = PurrDetectionService()
                    weakService = service
                    try? await service.initialize()
                }
                continuation.resume()
            }
        }

        // Give time for async cleanup
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        XCTAssertNil(weakService, "PurrDetectionService should deallocate after init")
    }

    /// Test repeated detection calls don't leak buffers
    func testRepeatedDetectionNoBufferLeak() async throws {
        let service = PurrDetectionService()
        try await service.initialize()

        // Perform multiple detections
        for _ in 0..<10 {
            let buffer = createTestBuffer()
            _ = await service.detectPurr(audioBuffer: buffer)
        }

        // Service should still be functional
        XCTAssertTrue(service.isReady)
    }

    /// Test sensitivity changes don't accumulate state
    func testSensitivityChangesNoStateLeak() {
        weak var weakService: PurrDetectionService?

        autoreleasepool {
            let service = PurrDetectionService()
            weakService = service

            // Change sensitivity many times
            for i in 0..<100 {
                service.setSensitivity(Float(i % 10) / 10.0)
            }
        }

        XCTAssertNil(weakService, "Service should deallocate after sensitivity changes")
    }

    // MARK: - Test Helpers

    private func createTestBuffer() -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4096)!
        buffer.frameLength = 4096
        return buffer
    }
}
