# WhisperKit Integration Guide

**Task**: T014 - Add WhisperKit SPM dependency to Xcode project

## Overview

WhisperKit provides on-device speech recognition using OpenAI's Whisper models. For CatPaws, we use it to detect cat-related sounds in audio streams.

## Adding WhisperKit via Swift Package Manager

### In Xcode:

1. **Open Package Dependencies**:
   - Select the CatPaws project in the navigator
   - Select the "CatPaws" target
   - Go to "Package Dependencies" tab

2. **Add Package**:
   - Click the "+" button
   - Enter the repository URL: `https://github.com/argmaxinc/WhisperKit.git`
   - Set version rule: "Up to Next Major Version" from `0.9.0`
   - Click "Add Package"

3. **Select Products**:
   - Check "WhisperKit" library
   - Click "Add Package"

### In Package.swift (for SPM projects):

```swift
dependencies: [
    .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0")
],
targets: [
    .target(
        name: "CatPaws",
        dependencies: ["WhisperKit"]
    )
]
```

## Updating PurrDetectionService

After adding WhisperKit, update `PurrDetectionService.swift`:

```swift
import WhisperKit

final class PurrDetectionService: PurrDetecting {
    // Add WhisperKit instance
    private var whisperKit: WhisperKit?
    
    func initialize() async throws {
        // Load the tiny model for fast inference
        whisperKit = try await WhisperKit(model: "whisper-tiny")
        isReady = true
        AppLogger.logPurrDetectionInitialized()
    }
    
    func detectPurr(audioBuffer: AVAudioPCMBuffer) async -> PurrDetectionResult {
        guard isReady, let whisper = whisperKit else { return .none }
        
        // Convert buffer to audio samples
        let samples = convertBufferToSamples(audioBuffer)
        
        // Transcribe audio
        let result = try? await whisper.transcribe(audioArray: samples)
        
        // Check for purr-related keywords
        let transcription = result?.text?.lowercased() ?? ""
        let keywordMatch = purrKeywords.contains { transcription.contains($0) }
        
        // Combine with frequency analysis
        let frequencyConfidence = analyzeFrequencyContent(audioBuffer)
        let keywordConfidence: Float = keywordMatch ? 0.7 : 0.0
        
        let totalConfidence = max(frequencyConfidence, keywordConfidence)
        let detected = totalConfidence >= (1.0 - sensitivity)
        
        let result = PurrDetectionResult(
            confidence: totalConfidence,
            detected: detected,
            timestamp: Date(),
            duration: Double(audioBuffer.frameLength) / audioBuffer.format.sampleRate
        )
        
        AppLogger.logPurrDetectionResult(detected: detected, confidence: totalConfidence)
        return result
    }
    
    private func convertBufferToSamples(_ buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else { return [] }
        return Array(UnsafeBufferPointer(start: channelData[0], count: Int(buffer.frameLength)))
    }
}
```

## Model Options

| Model | Size | Speed | Accuracy |
|-------|------|-------|----------|
| whisper-tiny | ~39 MB | Fastest | Good |
| whisper-base | ~74 MB | Fast | Better |
| whisper-small | ~244 MB | Medium | Best |

**Recommendation**: Use `whisper-tiny` for real-time detection with minimal latency.

## Notes

- WhisperKit requires macOS 14.0+
- Models are downloaded on first use (~40-250 MB)
- Consider adding model caching for offline use
- The current frequency-based detection works without WhisperKit as a fallback

## Testing Without WhisperKit

The current implementation uses frequency analysis as the primary detection method. WhisperKit integration is optional and provides enhanced detection through transcription keywords. The service gracefully degrades to frequency-only detection if WhisperKit is not available.
