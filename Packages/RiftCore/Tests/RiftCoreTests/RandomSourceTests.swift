import XCTest
@testable import RiftCore

final class RandomSourceTests: XCTestCase {
    func testSameSeedProducesSameDodgeSequence() {
        var left = SeededRandomSource(seed: 42)
        var right = SeededRandomSource(seed: 42)

        let leftRolls = (0..<12).map { _ in left.roll(chancePercent: 35) }
        let rightRolls = (0..<12).map { _ in right.roll(chancePercent: 35) }

        XCTAssertEqual(leftRolls, rightRolls)
    }

    func testRollClampsChancePercent() {
        var random = SeededRandomSource(seed: 1)

        XCTAssertFalse(random.roll(chancePercent: -20))
        XCTAssertTrue(random.roll(chancePercent: 120))
    }
}
