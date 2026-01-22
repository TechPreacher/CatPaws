# Research: Cat Purr Detection

**Feature**: 009-cat-purr-detection  
**Date**: 2026-01-21

## Research Tasks

### 1. Whisper Model Integration Approach

**Question**: What is the best approach to integrate Whisper model for on-device audio classification on macOS?

**Decision**: Use **WhisperKit** framework

**Rationale**:
- Native Swift API designed for Apple platforms
- Optimized for Apple Silicon with CoreML backend
- Active maintenance by Argmax (acquired by Apple talent)
- Supports whisper-tiny through whisper-large models
- Proven macOS compatibility
- Simple integration via Swift Package Manager

**Alternatives Considered**:

| Option | Pros | Cons |
|--------|------|------|
| WhisperKit | Swift-native, Apple-optimized, easy SPM integration | Newer framework, smaller community |
| CoreML Direct | Native Apple framework, no dependencies | Requires manual model conversion, more boilerplate |
| mlx-swift | Apple Silicon native, efficient | Lower-level API, less documentation |
| whisper.cpp | Mature, widely used | C++ interop complexity, not Swift-native |

**Implementation Approach**:
```swift
import WhisperKit

class PurrDetectionService: PurrDetecting {
    private var whisperKit: WhisperKit?
    
    func initialize() async throws {
        whisperKit = try await WhisperKit(model: "whisper-tiny")
    }
    
    func detectPurr(audioBuffer: AVAudioPCMBuffer) async -> PurrDetectionResult {
        guard let whisper = whisperKit else { return .none }
        
        // Transcribe with prompt hint for purr detection
        let result = try await whisper.transcribe(
            audioBuffer: audioBuffer,
            prompt: "cat purring sound"
        )
        
        // Analyze transcription for purr indicators
        return analyzePurrIndicators(result)
    }
}
```

---

### 2. Audio Capture Strategy

**Question**: How should we capture microphone audio efficiently while minimizing battery impact?

**Decision**: Use **AVAudioEngine** with wake-on-sound threshold

**Rationale**:
- AVAudioEngine provides low-latency audio capture
- Can install tap on input node for continuous monitoring
- Supports audio level metering for threshold detection
- Native framework, no additional dependencies

**Implementation Approach**:
```swift
class AudioMonitor: AudioMonitoring {
    private let audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode { audioEngine.inputNode }
    
    private let bufferSize: AVAudioFrameCount = 4096
    private var soundThreshold: Float = 0.01  // Wake threshold
    
    func startMonitoring() throws {
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, time in
            guard let self = self else { return }
            
            // Check if audio level exceeds threshold
            let level = self.calculateRMSLevel(buffer)
            if level > self.soundThreshold {
                // Forward to Whisper for classification
                self.delegate?.audioMonitor(self, didCaptureBuffer: buffer)
            }
        }
        
        try audioEngine.start()
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

**Battery Optimization**:
- Only process audio when RMS level exceeds threshold
- Use efficient buffer sizes (4096 frames ~ 93ms at 44.1kHz)
- Pause monitoring when app is inactive

---

### 3. Purr Detection Algorithm

**Question**: How do we reliably detect cat purring from Whisper transcription output?

**Decision**: Use **multi-signal approach** combining transcription keywords and audio frequency analysis

**Rationale**:
- Whisper may transcribe purring as various sounds ("purring", "humming", "rumbling", "[purr]", etc.)
- Frequency analysis can detect characteristic purr range (25-150 Hz)
- Combining signals improves accuracy and reduces false positives

**Purr Characteristics**:
- Frequency: 25-150 Hz (fundamental frequency)
- Pattern: Continuous, rhythmic sound
- Duration: Typically sustained for several seconds

**Detection Signals**:

| Signal | Weight | Description |
|--------|--------|-------------|
| Whisper transcription keywords | 0.4 | "purr", "purring", "rumble", "hum" |
| Low frequency energy (25-150 Hz) | 0.3 | FFT analysis of audio buffer |
| Rhythmic pattern detection | 0.2 | Consistent amplitude modulation |
| Duration threshold | 0.1 | Sound sustained > 1 second |

**Implementation Approach**:
```swift
struct PurrDetectionResult {
    let confidence: Float  // 0.0 - 1.0
    let detected: Bool
    let timestamp: Date
}

func analyzePurrIndicators(_ transcription: TranscriptionResult, audioBuffer: AVAudioPCMBuffer) -> PurrDetectionResult {
    var confidence: Float = 0.0
    
    // Signal 1: Keyword matching
    let purrKeywords = ["purr", "purring", "rumble", "rumbling", "hum", "humming"]
    let text = transcription.text.lowercased()
    if purrKeywords.contains(where: { text.contains($0) }) {
        confidence += 0.4
    }
    
    // Signal 2: Low frequency energy
    let lowFreqEnergy = calculateLowFrequencyEnergy(audioBuffer, range: 25...150)
    confidence += lowFreqEnergy * 0.3
    
    // Signal 3: Rhythmic pattern
    let rhythmScore = detectRhythmicPattern(audioBuffer)
    confidence += rhythmScore * 0.2
    
    // Signal 4: Duration (handled by caller accumulating buffers)
    // confidence += durationScore * 0.1
    
    return PurrDetectionResult(
        confidence: confidence,
        detected: confidence >= sensitivityThreshold,
        timestamp: Date()
    )
}
```

---

### 4. Microphone Permission Handling

**Question**: How do we properly request and handle microphone permissions on macOS?

**Decision**: Extend existing `PermissionService` with `.microphone` type

**Implementation**:
```swift
// PermissionType extension
enum PermissionType: String, CaseIterable {
    case accessibility
    case inputMonitoring
    case microphone  // NEW
    
    var settingsURL: URL? {
        switch self {
        case .microphone:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
        // ... existing cases
        }
    }
}

// Permission checking
import AVFoundation

func checkMicrophonePermission() -> PermissionStatus {
    switch AVCaptureDevice.authorizationStatus(for: .audio) {
    case .authorized: return .granted
    case .denied, .restricted: return .denied
    case .notDetermined: return .notDetermined
    @unknown default: return .notDetermined
    }
}

func requestMicrophonePermission() async -> Bool {
    await AVCaptureDevice.requestAccess(for: .audio)
}
```

**Entitlements Required**:
```xml
<!-- CatPaws.entitlements -->
<key>com.apple.security.device.audio-input</key>
<true/>
```

**Info.plist Required**:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>CatPaws uses the microphone to detect cat purring sounds and protect your keyboard.</string>
```

---

### 5. Privacy Considerations

**Question**: How do we ensure user privacy with audio monitoring?

**Decision**: Implement strict privacy-first approach

**Privacy Guarantees**:
1. **On-device processing only**: All audio processed locally via Whisper, never transmitted
2. **No audio storage**: Audio buffers discarded immediately after classification
3. **Minimal data retention**: Only detection events (timestamp, confidence) stored, no audio
4. **User control**: Easy toggle to disable purr detection entirely
5. **Transparency**: Clear explanation in permission request and settings

**Implementation**:
```swift
// Audio buffers are never persisted
func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
    let result = await purrDetector.detectPurr(buffer)
    // Buffer goes out of scope and is deallocated
    
    if result.detected {
        // Only store detection metadata, never audio
        recordDetectionEvent(type: .purr, confidence: result.confidence)
    }
}
```

---

### 6. Model Selection

**Question**: Which Whisper model size should we use?

**Decision**: Start with **whisper-tiny**, option to upgrade

| Model | Size | Speed | Accuracy | Recommendation |
|-------|------|-------|----------|----------------|
| whisper-tiny | ~39MB | Fastest | Good for simple sounds | **Default choice** |
| whisper-base | ~74MB | Fast | Better accuracy | Optional upgrade |
| whisper-small | ~244MB | Moderate | High accuracy | Not recommended (too large) |

**Rationale**:
- Purr detection is simpler than speech transcription
- whisper-tiny sufficient for detecting "purr-like" sounds
- Smaller model = faster inference = lower battery usage
- Can offer whisper-base as "high accuracy" option in settings

---

## Summary of Decisions

| Topic | Decision | Key Files Affected |
|-------|----------|-------------------|
| Whisper Integration | WhisperKit via SPM | Package.swift, PurrDetectionService.swift |
| Audio Capture | AVAudioEngine with threshold | AudioMonitor.swift |
| Detection Algorithm | Multi-signal (keywords + frequency + rhythm) | PurrDetectionService.swift |
| Permissions | Extend PermissionService | PermissionType.swift, PermissionService.swift |
| Privacy | On-device only, no audio storage | All audio-related code |
| Model Size | whisper-tiny (39MB) default | Configuration.swift |
