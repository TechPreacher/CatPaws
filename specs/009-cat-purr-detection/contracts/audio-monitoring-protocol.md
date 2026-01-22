# Service Protocol: AudioMonitoring

**Feature**: 009-cat-purr-detection  
**Date**: 2026-01-21

## Overview

The `AudioMonitoring` protocol defines the interface for microphone audio capture. This protocol abstracts audio input handling to allow for dependency injection and testing with mocks.

## Protocol Definition

```swift
import AVFoundation

/// Delegate protocol for receiving audio buffers
protocol AudioMonitorDelegate: AnyObject {
    /// Called when an audio buffer exceeds the sound threshold
    /// - Parameters:
    ///   - monitor: The audio monitor instance
    ///   - buffer: The captured audio buffer
    func audioMonitor(_ monitor: AudioMonitor, didCaptureBuffer buffer: AVAudioPCMBuffer)
}

/// Protocol for microphone audio monitoring
protocol AudioMonitoring {
    /// Delegate to receive audio buffer callbacks
    var delegate: AudioMonitorDelegate? { get set }
    
    /// Whether audio monitoring is currently active
    var isMonitoring: Bool { get }
    
    /// Current audio input level (RMS)
    var currentLevel: Float { get }
    
    /// Start capturing audio from the microphone
    /// - Throws: Error if audio engine fails to start or permission denied
    func startMonitoring() throws
    
    /// Stop audio capture
    func stopMonitoring()
    
    /// Pause monitoring temporarily (e.g., during system sleep)
    func pauseMonitoring()
    
    /// Resume monitoring after pause
    func resumeMonitoring() throws
    
    /// Update the wake-on-sound threshold
    /// - Parameter threshold: RMS level threshold (0.001 to 0.1)
    func setSoundThreshold(_ threshold: Float)
}
```

## State Model

```swift
/// State of the audio monitor
struct AudioMonitorState {
    /// Whether monitoring is active
    var isMonitoring: Bool = false
    
    /// Current audio RMS level
    var currentLevel: Float = 0.0
    
    /// Microphone permission status
    var permissionStatus: PermissionStatus = .notDetermined
}
```

## Implementation Requirements

### AudioMonitor (Production)

1. **Engine**: Use AVAudioEngine for low-latency capture
2. **Buffer Size**: 4096 frames (~93ms at 44.1kHz)
3. **Threshold**: Only forward buffers exceeding threshold
4. **Lifecycle**: Properly handle start/stop/pause states

```swift
final class AudioMonitor: AudioMonitoring {
    static let shared = AudioMonitor()
    
    weak var delegate: AudioMonitorDelegate?
    private let audioEngine = AVAudioEngine()
    private var soundThreshold: Float = 0.01
    private let bufferSize: AVAudioFrameCount = 4096
    
    var isMonitoring: Bool { audioEngine.isRunning }
    var currentLevel: Float = 0.0
    
    func startMonitoring() throws {
        guard !audioEngine.isRunning else { return }
        
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }
        
        try audioEngine.start()
    }
    
    func stopMonitoring() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
    }
    
    func pauseMonitoring() {
        audioEngine.pause()
    }
    
    func resumeMonitoring() throws {
        try audioEngine.start()
    }
    
    func setSoundThreshold(_ threshold: Float) {
        soundThreshold = max(0.001, min(0.1, threshold))
    }
    
    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        let level = calculateRMSLevel(buffer)
        currentLevel = level
        
        if level > soundThreshold {
            delegate?.audioMonitor(self, didCaptureBuffer: buffer)
        }
    }
    
    private func calculateRMSLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let frames = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<frames {
            sum += channelData[0][i] * channelData[0][i]
        }
        return sqrt(sum / Float(frames))
    }
}
```

### MockAudioMonitor (Testing)

```swift
final class MockAudioMonitor: AudioMonitoring {
    weak var delegate: AudioMonitorDelegate?
    
    var isMonitoring: Bool = false
    var currentLevel: Float = 0.0
    var lastThreshold: Float = 0.01
    
    var startMonitoringCalled = false
    var stopMonitoringCalled = false
    var pauseMonitoringCalled = false
    var resumeMonitoringCalled = false
    
    func startMonitoring() throws {
        startMonitoringCalled = true
        isMonitoring = true
    }
    
    func stopMonitoring() {
        stopMonitoringCalled = true
        isMonitoring = false
    }
    
    func pauseMonitoring() {
        pauseMonitoringCalled = true
        isMonitoring = false
    }
    
    func resumeMonitoring() throws {
        resumeMonitoringCalled = true
        isMonitoring = true
    }
    
    func setSoundThreshold(_ threshold: Float) {
        lastThreshold = threshold
    }
    
    /// Helper for tests: simulate receiving an audio buffer
    func simulateBuffer(_ buffer: AVAudioPCMBuffer) {
        delegate?.audioMonitor(self as! AudioMonitor, didCaptureBuffer: buffer)
    }
}
```

## Usage Example

```swift
class AppViewModel {
    private var audioMonitor: AudioMonitoring
    
    init(audioMonitor: AudioMonitoring = AudioMonitor.shared) {
        self.audioMonitor = audioMonitor
        self.audioMonitor.delegate = self
    }
    
    func enablePurrDetection() {
        do {
            audioMonitor.setSoundThreshold(Float(configuration.purrSoundThreshold))
            try audioMonitor.startMonitoring()
        } catch {
            // Handle error
        }
    }
    
    func disablePurrDetection() {
        audioMonitor.stopMonitoring()
    }
}

extension AppViewModel: AudioMonitorDelegate {
    func audioMonitor(_ monitor: AudioMonitor, didCaptureBuffer buffer: AVAudioPCMBuffer) {
        // Forward to purr detection service
    }
}
```

## Lifecycle Events

| Event | Action |
|-------|--------|
| App becomes active | `resumeMonitoring()` if enabled |
| App becomes inactive | `pauseMonitoring()` |
| System sleep | `pauseMonitoring()` |
| System wake | `resumeMonitoring()` if enabled |
| Feature disabled | `stopMonitoring()` |
| Feature enabled | `startMonitoring()` |

## Contract Guarantees

| Guarantee | Description |
|-----------|-------------|
| Thread Safety | Delegate callbacks on audio thread; UI updates must dispatch to main |
| Resource Management | Properly releases audio resources on stop |
| Threshold Filtering | Only buffers exceeding threshold are forwarded |
| State Consistency | `isMonitoring` accurately reflects engine state |
| Graceful Degradation | Handles permission denial without crashing |
