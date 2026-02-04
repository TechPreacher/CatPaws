//
//  StatisticsServiceTests.swift
//  CatPawsTests
//
//  Created on 2026-01-20.
//

import XCTest
@testable import CatPaws

final class StatisticsServiceTests: XCTestCase {
    private var sut: StatisticsService!
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "StatisticsServiceTests")!
        testDefaults.removePersistentDomain(forName: "StatisticsServiceTests")
        sut = StatisticsService(defaults: testDefaults)
    }

    override func tearDown() {
        StatisticsService.resetForTesting(defaults: testDefaults)
        testDefaults.removePersistentDomain(forName: "StatisticsServiceTests")
        testDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitializationCreatesZeroStatistics() {
        XCTAssertEqual(sut.statistics.totalBlocks, 0)
        XCTAssertEqual(sut.statistics.todayBlocks, 0)
        XCTAssertEqual(sut.statistics.weekBlocks, 0)
    }

    // MARK: - Record Block Tests (T046)

    func testRecordBlockIncrementsCounter() {
        XCTAssertEqual(sut.statistics.totalBlocks, 0)

        sut.recordBlock()

        XCTAssertEqual(sut.statistics.totalBlocks, 1)
        XCTAssertEqual(sut.statistics.todayBlocks, 1)
        XCTAssertEqual(sut.statistics.weekBlocks, 1)
    }

    func testRecordBlockMultipleTimesIncrementsCorrectly() {
        sut.recordBlock()
        sut.recordBlock()
        sut.recordBlock()

        XCTAssertEqual(sut.statistics.totalBlocks, 3)
        XCTAssertEqual(sut.statistics.todayBlocks, 3)
        XCTAssertEqual(sut.statistics.weekBlocks, 3)
    }

    func testRecordBlockPersistsToUserDefaults() {
        sut.recordBlock()

        // Create new instance to verify persistence
        let newService = StatisticsService(defaults: testDefaults)
        XCTAssertEqual(newService.statistics.totalBlocks, 1)
    }

    // MARK: - Reset All Tests (T047)

    func testResetAllClearsStatistics() {
        // Record some blocks first
        sut.recordBlock()
        sut.recordBlock()
        XCTAssertEqual(sut.statistics.totalBlocks, 2)

        sut.resetAll()

        XCTAssertEqual(sut.statistics.totalBlocks, 0)
        XCTAssertEqual(sut.statistics.todayBlocks, 0)
        XCTAssertEqual(sut.statistics.weekBlocks, 0)
    }

    func testResetAllPersistsToUserDefaults() {
        sut.recordBlock()
        sut.resetAll()

        // Create new instance to verify persistence
        let newService = StatisticsService(defaults: testDefaults)
        XCTAssertEqual(newService.statistics.totalBlocks, 0)
    }

    // MARK: - Daily Reset Logic Tests (T048)

    func testInitializationResetsDailyCounterOnNewDay() {
        // Simulate yesterday's date with stale counters
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        var stats = AppStatistics()
        stats.totalBlocks = 5
        stats.todayBlocks = 3
        stats.weekBlocks = 5
        stats.lastBlockDate = yesterday

        // Encode and save to defaults
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(stats) {
            testDefaults.set(data, forKey: "catpaws.statistics")
        }

        // Create new service - should reset daily counter on init
        let service = StatisticsService(defaults: testDefaults)

        // Daily counter should be reset to 0 without needing recordBlock()
        XCTAssertEqual(service.statistics.todayBlocks, 0)
        // Weekly counter should NOT be reset (same week)
        XCTAssertEqual(service.statistics.weekBlocks, 5)
        // Total should remain unchanged
        XCTAssertEqual(service.statistics.totalBlocks, 5)
    }

    func testInitializationResetsWeeklyCounterOnNewWeek() {
        // Get a date from last week
        let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!

        var stats = AppStatistics()
        stats.totalBlocks = 10
        stats.todayBlocks = 3
        stats.weekBlocks = 7
        stats.lastBlockDate = lastWeek

        // Encode and save to defaults
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(stats) {
            testDefaults.set(data, forKey: "catpaws.statistics")
        }

        // Create new service - should reset both counters on init
        let service = StatisticsService(defaults: testDefaults)

        // Both counters should be reset without needing recordBlock()
        XCTAssertEqual(service.statistics.todayBlocks, 0)
        XCTAssertEqual(service.statistics.weekBlocks, 0)
        // Total should remain unchanged
        XCTAssertEqual(service.statistics.totalBlocks, 10)
    }

    func testCheckAndResetCountersResetsDailyOnNewDay() {
        // Simulate yesterday's date
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        var stats = AppStatistics()
        stats.totalBlocks = 5
        stats.todayBlocks = 3
        stats.weekBlocks = 5
        stats.lastBlockDate = yesterday

        // Encode and save to defaults
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(stats) {
            testDefaults.set(data, forKey: "catpaws.statistics")
        }

        // Create new service to load the data
        let service = StatisticsService(defaults: testDefaults)

        // Record a block today - this triggers checkAndResetCounters
        service.recordBlock()

        // Daily counter should have been reset and then incremented by 1
        XCTAssertEqual(service.statistics.todayBlocks, 1)
        // Total should be incremented
        XCTAssertEqual(service.statistics.totalBlocks, 6)
    }

    func testCheckAndResetCountersResetsWeeklyOnNewWeek() {
        // Get a date from last week
        let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!

        var stats = AppStatistics()
        stats.totalBlocks = 10
        stats.todayBlocks = 3
        stats.weekBlocks = 7
        stats.lastBlockDate = lastWeek

        // Encode and save to defaults
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(stats) {
            testDefaults.set(data, forKey: "catpaws.statistics")
        }

        // Create new service to load the data
        let service = StatisticsService(defaults: testDefaults)

        // Record a block - triggers checkAndResetCounters
        service.recordBlock()

        // Weekly counter should have been reset and then incremented by 1
        XCTAssertEqual(service.statistics.weekBlocks, 1)
        // Daily counter should also be reset and incremented by 1
        XCTAssertEqual(service.statistics.todayBlocks, 1)
        // Total should be incremented
        XCTAssertEqual(service.statistics.totalBlocks, 11)
    }

    func testCheckAndResetCountersDoesNotResetOnSameDay() {
        sut.recordBlock()
        sut.recordBlock()

        // Both blocks on same day, counters should just increment
        XCTAssertEqual(sut.statistics.todayBlocks, 2)
        XCTAssertEqual(sut.statistics.weekBlocks, 2)
        XCTAssertEqual(sut.statistics.totalBlocks, 2)
    }

    // MARK: - Testing Support Tests

    func testResetForTestingClearsUserDefaults() {
        sut.recordBlock()

        StatisticsService.resetForTesting(defaults: testDefaults)

        let newService = StatisticsService(defaults: testDefaults)
        XCTAssertEqual(newService.statistics.totalBlocks, 0)
    }
}
