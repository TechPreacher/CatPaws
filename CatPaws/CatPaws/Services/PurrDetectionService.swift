//
//  PurrDetectionService.swift
//  CatPaws
//
//  Created on 2026-01-21.
//

import Accelerate
import AVFoundation
import Foundation

/// Protocol for audio-based cat purr detection
protocol PurrDetecting: AnyObject {
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

/// Error types for PurrDetectionService
enum PurrDetectionError: Error, LocalizedError {
    case modelLoadFailed(String)
    case analysisError(Error)
    case notInitialized

    var errorDescription: String? {
        switch self {
        case .modelLoadFailed(let reason):
            return "Failed to load Whisper model: \(reason)"
        case .analysisError(let error):
            return "Audio analysis failed: \(error.localizedDescription)"
        case .notInitialized:
            return "Purr detection service not initialized"
        }
    }
}

/// Concrete implementation of purr detection using audio analysis
/// Note: Full Whisper integration requires WhisperKit SPM dependency
final class PurrDetectionService: PurrDetecting {
    // MARK: - Properties

    /// Detection sensitivity threshold (0.0 to 1.0)
    private var sensitivity: Float = 0.5

    /// Whether the service is initialized and ready
    private(set) var isReady: Bool = false

    /// Keywords that indicate cat purring in transcription
    private let purrKeywords = ["purr", "purring", "rumble", "rumbling", "hum", "humming", "cat"]

    /// Frequency range for cat purring (Hz)
    private let purrFrequencyRange: ClosedRange<Float> = 25...150

    // MARK: - Initialization

    init() {}

    // MARK: - PurrDetecting

    /// Initialize the detection service
    /// - Note: For enhanced detection with speech recognition, add WhisperKit SPM dependency
    ///   and initialize with: `whisperKit = try await WhisperKit(model: "whisper-tiny")`
    ///   See `specs/009-cat-purr-detection/whisperkit-integration.md` for details.
    func initialize() async throws {
        // Currently using frequency-based detection
        // WhisperKit integration available as optional enhancement
        isReady = true
        AppLogger.logPurrDetectionInitialized()
    }

    /// Analyze an audio buffer for cat purring sounds
    /// Uses frequency analysis to detect purr-like sounds
    func detectPurr(audioBuffer: AVAudioPCMBuffer) async -> PurrDetectionResult {
        guard isReady else { return .none }

        // Analyze audio for purr characteristics
        let frequencyConfidence = analyzeFrequencyContent(audioBuffer)
        let patternConfidence = analyzeTemporalPattern(audioBuffer)

        // Combine signals with weights
        let totalConfidence = (frequencyConfidence * 0.6) + (patternConfidence * 0.4)

        // Apply sensitivity threshold
        // Higher sensitivity = lower threshold needed for detection
        let threshold = 1.0 - sensitivity
        let detected = totalConfidence >= threshold

        let result = PurrDetectionResult(
            confidence: totalConfidence,
            detected: detected,
            timestamp: Date(),
            duration: Double(audioBuffer.frameLength) / audioBuffer.format.sampleRate
        )
        AppLogger.logPurrDetectionResult(detected: detected, confidence: totalConfidence)
        return result
    }

    /// Update detection sensitivity
    func setSensitivity(_ sensitivity: Float) {
        self.sensitivity = max(0, min(1, sensitivity))
        AppLogger.logPurrSensitivityChanged(sensitivity: self.sensitivity)
    }

    // MARK: - Private Analysis Methods

    /// Analyze frequency content for purr-like characteristics (25-150 Hz)
    /// Uses vDSP for SIMD-accelerated computation
    /// - Parameter buffer: Audio buffer to analyze
    /// - Returns: Confidence score (0.0 to 1.0) based on low frequency energy
    private func analyzeFrequencyContent(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }

        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return 0 }

        // Calculate RMS using vDSP for vectorized computation
        var meanSquare: Float = 0
        vDSP_measqv(channelData[0], 1, &meanSquare, vDSP_Length(frames))
        let rms = sqrt(meanSquare)

        // Calculate zero-crossing rate for frequency estimation
        // Use vDSP to compute sign changes efficiently
        let zeroCrossings = countZeroCrossings(channelData[0], count: frames)
        let zeroCrossingRate = Float(zeroCrossings) / Float(frames)

        // Low zero-crossing rate with decent amplitude suggests low frequency content
        // Cat purrs have characteristic low frequency (25-150 Hz)
        // At 44.1kHz, 150 Hz would have ~294 samples per cycle, so ZCR < 0.01 is good
        let lowFreqScore: Float
        if zeroCrossingRate < 0.01 && rms > 0.01 {
            lowFreqScore = 0.8
        } else if zeroCrossingRate < 0.02 && rms > 0.005 {
            lowFreqScore = 0.5
        } else if zeroCrossingRate < 0.03 {
            lowFreqScore = 0.2
        } else {
            lowFreqScore = 0.0
        }

        return lowFreqScore
    }

    /// Count zero crossings using optimized iteration
    /// - Parameters:
    ///   - data: Pointer to audio samples
    ///   - count: Number of samples
    /// - Returns: Number of zero crossings
    private func countZeroCrossings(_ data: UnsafePointer<Float>, count: Int) -> Int {
        guard count > 1 else { return 0 }

        var crossings = 0
        var previous = data[0]

        for index in 1..<count {
            let current = data[index]
            if (current >= 0 && previous < 0) || (current < 0 && previous >= 0) {
                crossings += 1
            }
            previous = current
        }

        return crossings
    }

    /// Analyze temporal pattern for rhythmic purr-like characteristics
    /// Uses vDSP for SIMD-accelerated envelope computation
    /// - Parameter buffer: Audio buffer to analyze
    /// - Returns: Confidence score (0.0 to 1.0) based on rhythmic patterns
    private func analyzeTemporalPattern(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }

        let frames = Int(buffer.frameLength)
        guard frames > 256 else { return 0 }

        // Calculate amplitude envelope using vDSP
        let windowSize = 256
        let hopSize = windowSize / 2
        let envelopeCount = (frames - windowSize) / hopSize + 1

        guard envelopeCount > 2 else { return 0 }

        // Compute absolute values for envelope calculation
        var absValues = [Float](repeating: 0, count: frames)
        vDSP_vabs(channelData[0], 1, &absValues, 1, vDSP_Length(frames))

        // Calculate envelope using windowed means
        var envelopeValues = [Float](repeating: 0, count: envelopeCount)
        absValues.withUnsafeBufferPointer { bufferPointer in
            for windowIndex in 0..<envelopeCount {
                let startIndex = windowIndex * hopSize
                var windowMean: Float = 0
                vDSP_meanv(bufferPointer.baseAddress! + startIndex, 1, &windowMean, vDSP_Length(windowSize))
                envelopeValues[windowIndex] = windowMean
            }
        }

        // Calculate mean of envelope
        var mean: Float = 0
        vDSP_meanv(envelopeValues, 1, &mean, vDSP_Length(envelopeCount))
        guard mean > 0.001 else { return 0 } // Minimum amplitude threshold

        // Calculate variance using vDSP
        // variance = mean(x^2) - mean(x)^2
        var meanSquare: Float = 0
        vDSP_measqv(envelopeValues, 1, &meanSquare, vDSP_Length(envelopeCount))
        let variance = meanSquare - (mean * mean)

        // Low variance relative to mean indicates sustained sound (like purring)
        let coefficientOfVariation = sqrt(max(0, variance)) / mean
        let sustainedScore: Float
        if coefficientOfVariation < 0.3 {
            sustainedScore = 0.8  // Very consistent amplitude
        } else if coefficientOfVariation < 0.5 {
            sustainedScore = 0.5  // Moderately consistent
        } else if coefficientOfVariation < 0.7 {
            sustainedScore = 0.2  // Somewhat consistent
        } else {
            sustainedScore = 0.0  // Too variable
        }

        return sustainedScore
    }
}
