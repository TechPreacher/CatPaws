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

    // MARK: - State Transitions

    /// Records a new block event
    mutating func recordBlock() {
        totalBlocks += 1
        todayBlocks += 1
        weekBlocks += 1
        lastBlockDate = Date()
    }

    /// Resets daily counter (called at midnight)
    mutating func resetDaily() {
        todayBlocks = 0
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
    }
}
