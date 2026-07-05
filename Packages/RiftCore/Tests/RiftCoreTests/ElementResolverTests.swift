import XCTest
@testable import RiftCore

final class ElementResolverTests: XCTestCase {
    func testOilIgnitesIntoFireSurface() {
        let surface = ElementResolver.surfaceAfterApplying(.fire, to: .oil)

        XCTAssertEqual(surface, .fire)
    }

    func testWaterRemovesBurningAndAppliesWet() {
        var actor = makeActor(statuses: [StatusEffect(type: .burning, remainingTurns: 2)])

        ElementResolver.applySurface(.water, to: &actor)

        XCTAssertFalse(actor.statuses.contains { $0.type == .burning })
        XCTAssertTrue(actor.statuses.contains { $0.type == .wet })
    }

    func testPoisonTickDamagesWithoutDodgeRoll() {
        var actor = makeActor(evasion: 100, statuses: [StatusEffect(type: .poisoned, remainingTurns: 2)])

        ElementResolver.tickStatuses(on: &actor)

        XCTAssertEqual(actor.stats.health, 18)
        XCTAssertEqual(actor.statuses.first?.remainingTurns, 1)
    }

    private func makeActor(evasion: Int = 0, statuses: [StatusEffect] = []) -> Actor {
        Actor(
            id: "target",
            displayName: "目标",
            kind: .humanEnemy,
            faction: .hostile,
            level: 1,
            stats: Stats(
                maxHealth: 20,
                health: 20,
                attack: 5,
                defense: 1,
                evasion: evasion,
                magic: 0,
                maxActionPoints: 4,
                actionPoints: 4
            ),
            skillIDs: [],
            statuses: statuses
        )
    }
}
