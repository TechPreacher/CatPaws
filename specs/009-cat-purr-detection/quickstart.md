# Quickstart: Cat Purr Detection

**Feature**: 009-cat-purr-detection  
**Date**: 2026-01-21

## Overview

This guide provides quick reference for implementing cat purr detection using the Whisper model. The feature adds audio-based cat detection alongside existing keyboard pattern detection.

## Prerequisites

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- WhisperKit framework (SPM)
- Microphone hardware access

## Quick Implementation Checklist

### 1. Add Microphone Permission (~30 min)

**Files**: 
- `CatPaws/Configuration/CatPaws.entitlements`
- `CatPaws/Configuration/Info.plist`
- `CatPaws/Models/PermissionType.swift`

```xml
<!-- CatPaws.entitlements - Add key -->
<key>com.apple.security.device.audio-input</key>
<true/>

<!-- Info.plist - Add key -->
<key>NSMicrophoneUsageDescription</key>
<string>CatPaws uses the microphone to detect cat purring sounds and protect your keyboard.</string>
```

```swift
// PermissionType.swift - Add case
enum PermissionType: String, CaseIterable {
    case accessibility
    case inputMonitoring
    case microphone  // ADD THIS
    
    var settingsURL: URL? {
        switch self {
        case .microphone:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
        // ... existing
        }
    }
}
```

### 2. Add Configuration Settings (~20 min)

**File**: `CatPaws/Models/Configuration.swift`

```swift
// Add keys
static let purrDetectionEnabledKey = "catpaws.purrDetectionEnabled"
static let purrSensitivityKey = "catpaws.purrSensitivity"
static let purrSoundThresholdKey = "catpaws.purrSoundThreshold"

// Add properties
@Published var purrDetectionEnabled: Bool = false {
    didSet { UserDefaults.standard.set(purrDetectionEnabled, forKey: Self.purrDetectionEnabledKey) }
}
@Published var purrSensitivity: Double = 0.5 {
    didSet { UserDefaults.standard.set(purrSensitivity, forKey: Self.purrSensitivityKey) }
}
@Published var purrSoundThreshold: Double = 0.01 {
    didSet { UserDefaults.standard.set(purrSoundThreshold, forKey: Self.purrSoundThresholdKey) }
}
```

### 3. Create AudioMonitor Service (~1.5 hours)

**File**: `CatPaws/Services/AudioMonitor.swift`

```swift
import AVFoundation

protocol AudioMonitorDelegate: AnyObject {
    func audioMonitor(_ monitor: AudioMonitor, didCaptureBuffer buffer: AVAudioPCMBuffer)
}

protocol AudioMonitoring {
    var delegate: AudioMonitorDelegate? { get set }
    var isMonitoring: Bool { get }
    func startMonitoring() throws
    func stopMonitoring()
}

final class AudioMonitor: AudioMonitoring {
    static let shared = AudioMonitor()
    
    weak var delegate: AudioMonitorDelegate?
    private let audioEngine = AVAudioEngine()
    private let bufferSize: AVAudioFrameCount = 4096
    private var soundThreshold: Float = 0.01
    
    var isMonitoring: Bool { audioEngine.isRunning }
    
    func startMonitoring() throws {
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            let level = self.calculateRMSLevel(buffer)
            if level > self.soundThreshold {
                self.delegate?.audioMonitor(self, didCaptureBuffer: buffer)
            }
        }
        
        try audioEngine.start()
    }
    
    func stopMonitoring() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
    }
    
    private func calculateRMSLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let frames = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<frames { sum += channelData[0][i] * channelData[0][i] }
        return sqrt(sum / Float(frames))
    }
}
```

### 4. Add WhisperKit Dependency (~15 min)

**Xcode**: File → Add Package Dependencies

```
URL: https://github.com/argmaxinc/WhisperKit.git
Version: 0.9.0 or later
```

### 5. Create PurrDetectionService (~2 hours)

**File**: `CatPaws/Services/PurrDetectionService.swift`

```swift
import WhisperKit
import AVFoundation

protocol PurrDetecting {
    func initialize() async throws
    func detectPurr(audioBuffer: AVAudioPCMBuffer) async -> PurrDetectionResult
}

final class PurrDetectionService: PurrDetecting {
    private var whisperKit: WhisperKit?
    private var sensitivity: Float = 0.5
    
    func initialize() async throws {
        whisperKit = try await WhisperKit(model: "whisper-tiny")
    }
    
    func detectPurr(audioBuffer: AVAudioPCMBuffer) async -> PurrDetectionResult {
        guard let whisper = whisperKit else { return .none }
        
        do {
            let result = try await whisper.transcribe(audioBuffer: audioBuffer)
            return analyzePurrIndicators(result)
        } catch {
            return .none
        }
    }
    
    private func analyzePurrIndicators(_ result: TranscriptionResult) -> PurrDetectionResult {
        let purrKeywords = ["purr", "purring", "rumble", "hum"]
        let text = result.text.lowercased()
        let hasKeyword = purrKeywords.contains { text.contains($0) }
        let confidence: Float = hasKeyword ? 0.8 : 0.0
        
        return PurrDetectionResult(
            confidence: confidence,
            detected: confidence >= sensitivity,
            timestamp: Date(),
            duration: 0
        )
    }
}
```

### 6. Add DetectionType.purr (~10 min)

**File**: `CatPaws/Models/DetectionEvent.swift`

```swift
enum DetectionType: String, Codable, CaseIterable {
    case paw
    case multiPaw
    case sitting
    case purr  // ADD THIS
}
```

### 7. Integrate in AppViewModel (~1 hour)

**File**: `CatPaws/ViewModels/AppViewModel.swift`

```swift
// Add properties
private var audioMonitor: AudioMonitoring = AudioMonitor.shared
private var purrDetector: PurrDetecting = PurrDetectionService()

// Implement AudioMonitorDelegate
extension AppViewModel: AudioMonitorDelegate {
    func audioMonitor(_ monitor: AudioMonitor, didCaptureBuffer buffer: AVAudioPCMBuffer) {
        Task {
            let result = await purrDetector.detectPurr(audioBuffer: buffer)
            if result.detected {
                await MainActor.run {
                    let event = DetectionEvent(type: .purr, confidence: Double(result.confidence))
                    lockStateManager.handleDetection(event)
                }
            }
        }
    }
}
```

## Testing Checklist

- [ ] Unit test: `PurrDetectionServiceTests` - mock WhisperKit, verify keyword detection
- [ ] Unit test: `AudioMonitorTests` - mock audio engine, verify threshold filtering
- [ ] Unit test: `PermissionServiceTests` - verify microphone permission checking
- [ ] Integration test: Audio buffer → Detection → Lock trigger flow
- [ ] UI test: Enable purr detection toggle, verify settings persistence
- [ ] Manual test: Play purr audio, verify detection and lock

## Build & Test Commands

```bash
# Build project
cd CatPaws
xcodebuild -project CatPaws.xcodeproj -scheme CatPaws -configuration Debug build

# Run tests
xcodebuild -project CatPaws.xcodeproj -scheme CatPaws -configuration Debug test

# Run specific test class
xcodebuild -project CatPaws.xcodeproj -scheme CatPaws test -only-testing:CatPawsTests/PurrDetectionServiceTests
```

## Common Issues

| Issue | Solution |
|-------|----------|
| WhisperKit model download fails | Check network, ensure sufficient disk space (~50MB) |
| Microphone permission denied | Check System Preferences → Privacy → Microphone |
| Audio capture silent | Verify microphone is not muted, check input device selection |
| High CPU usage | Increase sound threshold, reduce buffer processing frequency |

## File Placement Reference

| File Type | Location | Example |
|-----------|----------|---------|
| Models | `CatPaws/Models/` | `PurrDetectionResult.swift` |
| Services | `CatPaws/Services/` | `AudioMonitor.swift` |
| ViewModels | `CatPaws/ViewModels/` | (modify `AppViewModel.swift`) |
| Views | `CatPaws/Views/Settings/` | `PurrDetectionSettingsView.swift` |
| Tests | `CatPawsTests/ServiceTests/` | `PurrDetectionServiceTests.swift` |
| Mocks | `CatPawsTests/Mocks/` | `MockAudioMonitor.swift` |
