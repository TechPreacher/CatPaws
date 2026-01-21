//
//  AudioMonitor.swift
//  CatPaws
//
//  Created on 2026-01-21.
//

import AVFoundation
import Foundation

/// Delegate protocol for receiving audio buffer callbacks from AudioMonitor
protocol AudioMonitorDelegate: AnyObject {
    /// Called when an audio buffer exceeds the configured sound threshold
    /// - Parameters:
    ///   - monitor: The AudioMonitor instance
    ///   - buffer: The captured audio buffer above threshold
    func audioMonitor(_ monitor: AudioMonitor, didCaptureBuffer buffer: AVAudioPCMBuffer)
}

/// Protocol for microphone audio monitoring
protocol AudioMonitoring: AnyObject {
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
    /// - Throws: Error if audio engine fails to restart
    func resumeMonitoring() throws

    /// Update the wake-on-sound threshold
    /// - Parameter threshold: RMS level threshold (0.001 to 0.1)
    func setSoundThreshold(_ threshold: Float)
}

/// Error types for AudioMonitor
enum AudioMonitorError: Error, LocalizedError {
    case engineStartFailed(Error)
    case noInputAvailable
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .engineStartFailed(let error):
            return "Failed to start audio engine: \(error.localizedDescription)"
        case .noInputAvailable:
            return "No audio input device available"
        case .permissionDenied:
            return "Microphone permission not granted"
        }
    }
}

/// Concrete implementation of audio monitoring using AVAudioEngine
final class AudioMonitor: AudioMonitoring {
    // MARK: - Singleton

    /// Shared instance for app-wide access
    static let shared = AudioMonitor()

    // MARK: - Properties

    /// Delegate to receive audio buffer callbacks
    weak var delegate: AudioMonitorDelegate?

    /// The audio engine for capturing microphone input
    private let audioEngine = AVAudioEngine()

    /// Buffer size in frames (~93ms at 44.1kHz)
    private let bufferSize: AVAudioFrameCount = 4096

    /// Wake-on-sound RMS threshold
    private var soundThreshold: Float = 0.01

    /// Current audio RMS level
    private(set) var currentLevel: Float = 0.0

    /// Lock for thread-safe access to state
    private let stateLock = NSLock()

    // MARK: - AudioMonitoring

    /// Whether audio monitoring is currently active
    var isMonitoring: Bool {
        audioEngine.isRunning
    }

    /// Start capturing audio from the microphone
    /// - Throws: AudioMonitorError if engine fails to start
    func startMonitoring() throws {
        stateLock.lock()
        defer { stateLock.unlock() }

        guard !audioEngine.isRunning else { return }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        // Verify we have valid audio format
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw AudioMonitorError.noInputAvailable
        }

        // Install tap on input node to capture audio buffers
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }

        do {
            try audioEngine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            throw AudioMonitorError.engineStartFailed(error)
        }
    }

    /// Stop audio capture and clean up resources
    func stopMonitoring() {
        stateLock.lock()
        defer { stateLock.unlock() }

        guard audioEngine.isRunning else { return }

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        currentLevel = 0.0
    }

    /// Pause monitoring temporarily
    func pauseMonitoring() {
        stateLock.lock()
        defer { stateLock.unlock() }

        if audioEngine.isRunning {
            audioEngine.pause()
        }
    }

    /// Resume monitoring after pause
    /// - Throws: AudioMonitorError if engine fails to restart
    func resumeMonitoring() throws {
        stateLock.lock()
        defer { stateLock.unlock() }

        guard !audioEngine.isRunning else { return }

        do {
            try audioEngine.start()
        } catch {
            throw AudioMonitorError.engineStartFailed(error)
        }
    }

    /// Update the wake-on-sound threshold
    /// - Parameter threshold: RMS level threshold (clamped to 0.001-0.1)
    func setSoundThreshold(_ threshold: Float) {
        soundThreshold = max(0.001, min(0.1, threshold))
    }

    // MARK: - Private Methods

    /// Process an audio buffer, calculate RMS level, and forward if above threshold
    /// - Parameter buffer: The audio buffer to process
    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        let level = calculateRMSLevel(buffer)
        currentLevel = level

        // Only forward buffers that exceed the sound threshold
        if level > soundThreshold {
            delegate?.audioMonitor(self, didCaptureBuffer: buffer)
        }
    }

    /// Calculate the RMS (Root Mean Square) level of an audio buffer
    /// - Parameter buffer: The audio buffer to analyze
    /// - Returns: RMS level as a Float
    private func calculateRMSLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }

        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return 0 }

        var sum: Float = 0
        for index in 0..<frames {
            let sample = channelData[0][index]
            sum += sample * sample
        }

        return sqrt(sum / Float(frames))
    }
}
