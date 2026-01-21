//
//  StatisticsService.swift
//  CatPaws
//
//  Created on 2026-01-18.
//

import Foundation

/// Service for persisting and managing AppStatistics via UserDefaults
final class StatisticsService: ObservableObject {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Keys

    private enum Keys {
        static let statistics = "catpaws.statistics"
    }

    // MARK: - Published State

    @Published private(set) var statistics: AppStatistics

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.statistics = Self.load(from: defaults)
    }

    // MARK: - Persistence

    private static func load(from defaults: UserDefaults) -> AppStatistics {
        guard let data = defaults.data(forKey: Keys.statistics) else {
            return AppStatistics()
        }
        do {
            return try JSONDecoder().decode(AppStatistics.self, from: data)
        } catch {
            return AppStatistics()
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(statistics)
            defaults.set(data, forKey: Keys.statistics)
        } catch {
            // Silently fail - statistics are not critical
        }
    }

    // MARK: - Public API

    /// Records a block event and persists to storage
    func recordBlock() {
        checkAndResetCounters()
        statistics.recordBlock()
        save()
    }

    /// Records a purr detection event and persists to storage
    func recordPurrDetection() {
        checkAndResetCounters()
        statistics.recordPurrDetection()
        save()
    }

    /// Resets all statistics to zero
    func resetAll() {
        statistics.resetAll()
        save()
    }

    // MARK: - Counter Reset Logic

    /// Checks if daily/weekly counters need to be reset based on date boundaries
    func checkAndResetCounters() {
        let calendar = Calendar.current
        let now = Date()

        // Check if we need to reset daily counter
        if let lastBlock = statistics.lastBlockDate {
            if !calendar.isDate(lastBlock, inSameDayAs: now) {
                statistics.resetDaily()

                // Check if we need to reset weekly counter (Monday is start of week)
                let lastWeek = calendar.component(.weekOfYear, from: lastBlock)
                let currentWeek = calendar.component(.weekOfYear, from: now)
                let lastYear = calendar.component(.yearForWeekOfYear, from: lastBlock)
                let currentYear = calendar.component(.yearForWeekOfYear, from: now)

                if lastWeek != currentWeek || lastYear != currentYear {
                    statistics.resetWeekly()
                }
            }
        }
    }

    // MARK: - Testing Support

    /// Resets storage for testing purposes
    static func resetForTesting(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: Keys.statistics)
    }
}
