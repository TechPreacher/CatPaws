//
//  PurrDetectionService.swift
//  CatPaws
//
//  Created on 2026-01-21.
//

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
    /// Note: In production, this would load the WhisperKit model
    func initialize() async throws {
        // TODO: Add WhisperKit initialization when dependency is added
        // whisperKit = try await WhisperKit(model: "whisper-tiny")

        // For now, mark as ready using frequency-based detection
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
    /// - Parameter buffer: Audio buffer to analyze
    /// - Returns: Confidence score (0.0 to 1.0) based on low frequency energy
    private func analyzeFrequencyContent(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }

        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return 0 }

        // Calculate energy in different frequency bands using simple approach
        // Full implementation would use FFT/vDSP

        // Calculate overall RMS
        var totalSum: Float = 0
        for index in 0..<frames {
            let sample = channelData[0][index]
            totalSum += sample * sample
        }
        let rms = sqrt(totalSum / Float(frames))

        // Simple low-frequency detection using zero-crossing rate
        // Low zero-crossing rate indicates low frequency content
        var zeroCrossings = 0
        for index in 1..<frames {
            let current = channelData[0][index]
            let previous = channelData[0][index - 1]
            if (current >= 0 && previous < 0) || (current < 0 && previous >= 0) {
                zeroCrossings += 1
            }
        }

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

    /// Analyze temporal pattern for rhythmic purr-like characteristics
    /// - Parameter buffer: Audio buffer to analyze
    /// - Returns: Confidence score (0.0 to 1.0) based on rhythmic patterns
    private func analyzeTemporalPattern(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }

        let frames = Int(buffer.frameLength)
        guard frames > 256 else { return 0 }

        // Analyze amplitude envelope for rhythmic modulation
        // Cat purrs have characteristic rhythmic pattern
        let windowSize = 256
        var envelopeValues: [Float] = []

        for startIndex in stride(from: 0, to: frames - windowSize, by: windowSize / 2) {
            var sum: Float = 0
            for offset in 0..<windowSize {
                let sample = channelData[0][startIndex + offset]
                sum += abs(sample)
            }
            envelopeValues.append(sum / Float(windowSize))
        }

        // Check for consistent amplitude (purrs are sustained)
        guard envelopeValues.count > 2 else { return 0 }

        let mean = envelopeValues.reduce(0, +) / Float(envelopeValues.count)
        guard mean > 0.001 else { return 0 } // Minimum amplitude threshold

        var variance: Float = 0
        for value in envelopeValues {
            let diff = value - mean
            variance += diff * diff
        }
        variance /= Float(envelopeValues.count)

        // Low variance relative to mean indicates sustained sound (like purring)
        let coefficientOfVariation = sqrt(variance) / mean
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
