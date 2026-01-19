//
//  CatDetectionServiceTests.swift
//  CatPawsTests
//
//  Created on 2026-01-16.
//

import XCTest
@testable import CatPaws

final class CatDetectionServiceTests: XCTestCase {
    var sut: CatDetectionService!

    override func setUp() {
        super.setUp()
        sut = CatDetectionService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - T019: 3+ Adjacent Keys Triggers Detection

    func testThreeAdjacentKeysTriggersDetection() {
        // A(0x00), S(0x01), D(0x02) are adjacent on QWERTY
        let pressedKeys: Set<UInt16> = [0x00, 0x01, 0x02]

        let result = sut.analyzePattern(pressedKeys: pressedKeys)

        XCTAssertNotNil(result, "Should detect cat paw pattern with 3 adjacent keys")
        XCTAssertEqual(result?.type, .paw)
        XCTAssertEqual(result?.keyCount, 3)
    }

    func testFourAdjacentKeysTriggersDetection() {
        // A(0x00), S(0x01), D(0x02), F(0x03) are adjacent on QWERTY
        let pressedKeys: Set<UInt16> = [0x00, 0x01, 0x02, 0x03]

        let result = sut.analyzePattern(pressedKeys: pressedKeys)

        XCTAssertNotNil(result, "Should detect cat paw pattern with 4 adjacent keys")
        XCTAssertEqual(result?.type, .paw)
        XCTAssertEqual(result?.keyCount, 4)
    }

    func testTwoKeysDoesNotTriggerDetection() {
        // Only 2 adjacent keys should not trigger
        let pressedKeys: Set<UInt16> = [0x00, 0x01]  // A, S

        let result = sut.analyzePattern(pressedKeys: pressedKeys)

        XCTAssertNil(result, "Should not detect pattern with only 2 keys")
    }

    func testNonAdjacentKeysDoNotTriggerDetection() {
        // Q(0x0C), P(0x23), Z(0x06) - far apart on keyboard
        let pressedKeys: Set<UInt16> = [0x0C, 0x23, 0x06]

        let result = sut.analyzePattern(pressedKeys: pressedKeys)

        XCTAssertNil(result, "Should not detect pattern with non-adjacent keys")
    }

    // MARK: - T020: Modifier-Only Combinations Do NOT Trigger

    func testModifierOnlyDoesNotTriggerDetection() {
        // Command + Shift + Option
        let pressedKeys: Set<UInt16> = [0x37, 0x38, 0x3A]

        let result = sut.analyzePattern(pressedKeys: pressedKeys)

        XCTAssertNil(result, "Should not detect pattern with only modifier keys")
    }

    func testModifierWithTwoRegularKeysDoesNotTrigger() {
        // Command + A + S (modifier + only 2 regular keys)
        let pressedKeys: Set<UInt16> = [0x37, 0x00, 0x01]

        let result = sut.analyzePattern(pressedKeys: pressedKeys)

        XCTAssertNil(result, "Should not trigger with modifier + only 2 regular adjacent keys")
    }

    func testModifierWithThreeAdjacentKeysDoesTrigger() {
        // Command + A + S + D (modifier + 3 regular adjacent keys)
        let pressedKeys: Set<UInt16> = [0x37, 0x00, 0x01, 0x02]

        let result = sut.analyzePattern(pressedKeys: pressedKeys)

        XCTAssertNotNil(result, "Should detect pattern: modifier keys should be filtered, 3 adjacent remain")
        XCTAssertEqual(result?.keyCount, 3, "Key count should exclude modifier")
    }

    // MARK: - T021: Sequential Typing Does NOT Trigger

    func testSequentialTypingPattern() {
        // This tests that the detection looks at SIMULTANEOUS keys
        // In practice, sequential typing wouldn't result in 3+ keys being pressed at once
        // Testing with a state that represents normal typing (1-2 keys at a time)
        let singleKey: Set<UInt16> = [0x00]  // Just A
        let result1 = sut.analyzePattern(pressedKeys: singleKey)
        XCTAssertNil(result1, "Single key should not trigger")

        let twoKeys: Set<UInt16> = [0x00, 0x01]  // A + S during fast typing
        let result2 = sut.analyzePattern(pressedKeys: twoKeys)
        XCTAssertNil(result2, "Two keys (typical overlap during typing) should not trigger")
    }

    func testTypicalTypingOverlap() {
        // During normal typing, you might briefly have 2 adjacent keys
        // but rarely 3+ unless a cat is involved
        let typingOverlap: Set<UInt16> = [0x0D, 0x0E]  // W + E overlap
        let result = sut.analyzePattern(pressedKeys: typingOverlap)
        XCTAssertNil(result, "Normal typing overlap should not trigger")
    }

    // MARK: - T022: formsConnectedCluster Returns True for Adjacent Keys

    func testFormsConnectedClusterWithAdjacentKeys() {
        // A, S, D are connected
        let keys: Set<UInt16> = [0x00, 0x01, 0x02]
        let result = sut.formsConnectedCluster(keys)
        XCTAssertTrue(result, "Adjacent keys should form a connected cluster")
    }

    func testFormsConnectedClusterWithSingleKey() {
        let keys: Set<UInt16> = [0x00]
        let result = sut.formsConnectedCluster(keys)
        XCTAssertTrue(result, "Single key trivially forms a cluster")
    }

    func testFormsConnectedClusterWithEmptySet() {
        let keys: Set<UInt16> = []
        let result = sut.formsConnectedCluster(keys)
        XCTAssertTrue(result, "Empty set trivially forms a cluster")
    }

    func testFormsConnectedClusterWithDisconnectedKeys() {
        // Q(0x0C), Z(0x06) - far apart, not adjacent
        let keys: Set<UInt16> = [0x0C, 0x06]
        let result = sut.formsConnectedCluster(keys)
        XCTAssertFalse(result, "Non-adjacent keys should not form a connected cluster")
    }

    func testFormsConnectedClusterWithPartiallyConnected() {
        // A(0x00), S(0x01) connected, but P(0x23) is isolated
        let keys: Set<UInt16> = [0x00, 0x01, 0x23]
        let result = sut.formsConnectedCluster(keys)
        XCTAssertFalse(result, "Partially connected keys should not form a single cluster")
    }

    // MARK: - Edge Cases

    func testEmptyKeysDoesNotTrigger() {
        let result = sut.analyzePattern(pressedKeys: [])
        XCTAssertNil(result, "Empty key set should not trigger")
    }

    func testUnknownKeyCodesHandledGracefully() {
        // Unknown key codes (not in position map) should be handled
        let unknownKeys: Set<UInt16> = [0xFF, 0xFE, 0xFD]
        let result = sut.analyzePattern(pressedKeys: unknownKeys)
        XCTAssertNil(result, "Unknown key codes should not crash and should not trigger")
    }

    func testMixedKnownAndUnknownKeys() {
        // A, S, D (known) + unknown keys
        let mixedKeys: Set<UInt16> = [0x00, 0x01, 0x02, 0xFF]
        let result = sut.analyzePattern(pressedKeys: mixedKeys)
        // Should still detect the 3 adjacent known keys
        XCTAssertNotNil(result, "Should detect adjacent known keys even with unknown keys present")
    }

    // MARK: - Diagonal Adjacency Tests

    func testDiagonallyAdjacentKeys() {
        // Q(0x0C), A(0x00), W(0x0D) - Q and A are diagonal neighbors
        // W and A are also diagonal neighbors
        let diagonalKeys: Set<UInt16> = [0x0C, 0x00, 0x0D]

        let result = sut.formsConnectedCluster(diagonalKeys)
        XCTAssertTrue(result, "Diagonally adjacent keys should be considered connected")
    }

    // MARK: - T061-T063: Multi-Paw and Sitting Detection

    func testTenOrMoreKeysTriggersStttingDetection() {
        // 10+ keys should trigger sitting detection
        // Using row of keys: 1,2,3,4,5,6,7,8,9,0
        let manyKeys: Set<UInt16> = [
            0x12, 0x13, 0x14, 0x15, 0x17, 0x16, 0x1A, 0x1C, 0x19, 0x1D
        ]

        let result = sut.analyzePattern(pressedKeys: manyKeys)

        XCTAssertNotNil(result, "Should detect pattern with 10+ keys")
        XCTAssertEqual(result?.type, .sitting)
        XCTAssertEqual(result?.keyCount, 10)
    }

    func testNineKeysDoesNotTriggerSittingDetection() {
        // 9 keys should trigger paw, not sitting
        let nineKeys: Set<UInt16> = [
            0x12, 0x13, 0x14, 0x15, 0x17, 0x16, 0x1A, 0x1C, 0x19
        ]

        let result = sut.analyzePattern(pressedKeys: nineKeys)

        XCTAssertNotNil(result, "Should detect pattern with 9 adjacent keys")
        XCTAssertNotEqual(result?.type, .sitting, "9 keys should not trigger sitting")
    }

    func testMultipleDisconnectedClustersTriggersMultiPaw() {
        // Two separate clusters, each with 3+ keys
        // Cluster 1: A(0x00), S(0x01), D(0x02)
        // Cluster 2: J(0x26), K(0x28), L(0x25)
        let twoClusters: Set<UInt16> = [0x00, 0x01, 0x02, 0x26, 0x28, 0x25]

        let result = sut.analyzePattern(pressedKeys: twoClusters)

        XCTAssertNotNil(result, "Should detect multi-paw pattern")
        XCTAssertEqual(result?.type, .multiPaw)
    }

    func testSingleClusterDoesNotTriggerMultiPaw() {
        // Single cluster of 6 keys (not multiple clusters)
        let singleCluster: Set<UInt16> = [0x00, 0x01, 0x02, 0x03, 0x05, 0x04]  // A,S,D,F,G,H

        let result = sut.analyzePattern(pressedKeys: singleCluster)

        // Should be paw, not multiPaw
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .paw)
    }

    func testDetectionTypeSetCorrectlyForSitting() {
        // 12 keys
        let sittingKeys: Set<UInt16> = [
            0x12, 0x13, 0x14, 0x15, 0x17, 0x16,  // 1,2,3,4,5,6
            0x1A, 0x1C, 0x19, 0x1D, 0x1B, 0x18   // 7,8,9,0,-,=
        ]

        let result = sut.analyzePattern(pressedKeys: sittingKeys)

        XCTAssertEqual(result?.type, .sitting)
        XCTAssertEqual(result?.keyCount, 12)
    }
}
