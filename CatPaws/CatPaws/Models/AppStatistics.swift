//
//  AppStatistics.swift
//  CatPaws
//
//  Created on 2026-01-18.
//

import Foundation

/// Tracks detection/lock events for statistics display
struct AppStatistics: Codable, Equatable {
    /// All-time count of keyboard locks
    var totalBlocks: Int = 0

    /// Locks triggered today
    var todayBlocks: Int = 0

    /// Locks triggered this week
    var weekBlocks: Int = 0

    /// Timestamp of most recent lock
    var lastBlockDate: Date?

    /// Date counters were last reset
    var lastResetDate = Date()

    // MARK: - Purr Detection Statistics

    /// All-time count of purr detections
    var totalPurrDetections: Int = 0

    /// Purr detections today
    var todayPurrDetections: Int = 0

    /// Timestamp of most recent purr detection
    var lastPurrDetectionDate: Date?

    // MARK: - State Transitions

    /// Records a new block event
    mutating func recordBlock() {
        totalBlocks += 1
        todayBlocks += 1
        weekBlocks += 1
        lastBlockDate = Date()
    }

    /// Records a new purr detection event
    mutating func recordPurrDetection() {
        totalPurrDetections += 1
        todayPurrDetections += 1
        lastPurrDetectionDate = Date()
    }

    /// Resets daily counter (called at midnight)
    mutating func resetDaily() {
        todayBlocks = 0
        todayPurrDetections = 0
    }

    /// Resets weekly counter (called at start of new week)
    mutating func resetWeekly() {
        weekBlocks = 0
    }

    /// Resets all statistics to zero
    mutating func resetAll() {
        totalBlocks = 0
        todayBlocks = 0
        weekBlocks = 0
        lastBlockDate = nil
        lastResetDate = Date()
        totalPurrDetections = 0
        todayPurrDetections = 0
        lastPurrDetectionDate = nil
    }
}
