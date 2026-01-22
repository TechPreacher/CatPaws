# Service Protocol: PurrDetecting

**Feature**: 009-cat-purr-detection  
**Date**: 2026-01-21

## Overview

The `PurrDetecting` protocol defines the interface for audio-based cat purr detection using machine learning models. This protocol abstracts the detection implementation to allow for dependency injection and testing with mocks.

## Protocol Definition

```swift
import AVFoundation

/// Protocol for audio-based cat purr detection
protocol PurrDetecting {
    /// Initialize the detection model
    /// - Throws: Error if model initialization fails
    func initialize() async throws
    
    /// Analyze an audio buffer for cat purring sounds
    /// - Parameter audioBuffer: The audio buffer to analyze
    /// - Returns: Detection result with confidence score
    func detectPurr(audioBuffer: AVAudioPCMBuffer) async -> PurrDetectionResult
    
    /// Update detection sensitivity
    /// - Parameter sensitivity: Value between 0.0 (low) and 1.0 (high)
    func setSensitivity(_ sensitivity: Float)
    
    /// Check if the detection model is ready
    var isReady: Bool { get }
}
```

## Result Type

```swift
/// Result of a purr detection analysis
struct PurrDetectionResult {
    /// Confidence score (0.0 to 1.0)
    let confidence: Float
    
    /// Whether purr was detected above threshold
    let detected: Bool
    
    /// Timestamp of detection
    let timestamp: Date
    
    /// Duration of the detected sound
    let duration: TimeInterval
    
    /// No detection result
    static let none = PurrDetectionResult(
        confidence: 0,
        detected: false,
        timestamp: Date(),
        duration: 0
    )
}
```

## Implementation Requirements

### PurrDetectionService (Production)

1. **Model**: Use WhisperKit with whisper-tiny model
2. **Processing**: All inference must be on-device
3. **Thread Safety**: Must be safe to call from any thread
4. **Memory**: Audio buffers must not be retained after processing

```swift
final class PurrDetectionService: PurrDetecting {
    private var whisperKit: WhisperKit?
    private var sensitivity: Float = 0.5
    
    var isReady: Bool { whisperKit != nil }
    
    func initialize() async throws {
        whisperKit = try await WhisperKit(model: "whisper-tiny")
    }
    
    func detectPurr(audioBuffer: AVAudioPCMBuffer) async -> PurrDetectionResult {
        // Implementation in PurrDetectionService.swift
    }
    
    func setSensitivity(_ sensitivity: Float) {
        self.sensitivity = max(0, min(1, sensitivity))
    }
}
```

### MockPurrDetectionService (Testing)

```swift
final class MockPurrDetectionService: PurrDetecting {
    var initializeCalled = false
    var detectPurrCalled = false
    var lastSensitivity: Float = 0.5
    var mockResult: PurrDetectionResult = .none
    var isReady: Bool = true
    
    func initialize() async throws {
        initializeCalled = true
    }
    
    func detectPurr(audioBuffer: AVAudioPCMBuffer) async -> PurrDetectionResult {
        detectPurrCalled = true
        return mockResult
    }
    
    func setSensitivity(_ sensitivity: Float) {
        lastSensitivity = sensitivity
    }
}
```

## Usage Example

```swift
class AppViewModel: AudioMonitorDelegate {
    private var purrDetector: PurrDetecting
    
    init(purrDetector: PurrDetecting = PurrDetectionService()) {
        self.purrDetector = purrDetector
    }
    
    func setupPurrDetection() async {
        do {
            try await purrDetector.initialize()
            purrDetector.setSensitivity(Float(configuration.purrSensitivity))
        } catch {
            // Handle initialization failure
        }
    }
    
    func audioMonitor(_ monitor: AudioMonitor, didCaptureBuffer buffer: AVAudioPCMBuffer) {
        Task {
            let result = await purrDetector.detectPurr(audioBuffer: buffer)
            if result.detected {
                // Handle detection
            }
        }
    }
}
```

## Contract Guarantees

| Guarantee | Description |
|-----------|-------------|
| Thread Safety | All methods safe to call from any thread |
| Memory Safety | No audio data retained after processing |
| Privacy | No data transmitted off-device |
| Idempotency | Multiple initialize() calls are safe |
| Graceful Degradation | Returns `.none` on errors, does not throw |
