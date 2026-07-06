import XCTest
@testable import RiftCore

final class BattleEngineTests: XCTestCase {
    func testActionFailsWhenAPIsInsufficient() throws {
        var engine = BattleEngine(state: BattleState(actors: [
            makeActor(id: "hero", faction: .player, actionPoints: 1),
            makeActor(id: "wolf", faction: .animal)
        ]))
        let skill = SkillDefinition(
            id: "heavy_slash",
            displayName: "重劈",
            actionPointCost: 2,
            range: 1.5,
            target: .enemy,
            affectsAllies: false,
            canBeDodged: true
        )

        XCTAssertThrowsError(try engine.useSkill(actorID: "hero", skill: skill)) { error in
            XCTAssertEqual(error as? BattleActionError, .insufficientActionPoints(required: 2, available: 1))
        }
    }

    func testEndTurnResetsNextActorAP() throws {
        var engine = BattleEngine(state: BattleState(actors: [
            makeActor(id: "hero", faction: .player, actionPoints: 4),
            makeActor(id: "wolf", faction: .animal, actionPoints: 0)
        ]))

        try engine.endTurn()

        XCTAssertEqual(engine.state.activeActorID, "wolf")
        XCTAssertEqual(engine.state.actor(id: "wolf")?.stats.actionPoints, 4)
    }

    func testMovementUsesStartingDistancePerAPValue() throws {
        // Micro test plan: in the vertical slice, one turn should reach an adjacent tactical point.
        // If movement is too strong, lower movementDistancePerAPStartingValue; if too weak, raise it.
        XCTAssertEqual(APRules.movementCost(forDistance: APRules.movementDistancePerAPStartingValue), 1)
        XCTAssertEqual(APRules.movementCost(forDistance: APRules.movementDistancePerAPStartingValue + 0.1), 2)
    }

    func testTargetedSkillSpendsAPAndAppliesEffects() throws {
        var engine = BattleEngine(state: BattleState(actors: [
            makeActor(id: "hero", faction: .player, actionPoints: 4),
            makeActor(id: "wolf", faction: .animal, health: 20)
        ]))
        var random = SeededRandomSource(seed: 7)
        let skill = SkillDefinition(
            id: "slash",
            displayName: "劈砍",
            actionPointCost: 2,
            range: 1.5,
            target: .enemy,
            affectsAllies: false,
            canBeDodged: false,
            effects: [.damage(8)]
        )

        _ = try engine.useSkill(
            actorID: "hero",
            targetID: "wolf",
            skill: skill,
            context: TargetingContext(distance: 1, hasLineOfSight: true, isAlly: false),
            random: &random
        )

        XCTAssertEqual(engine.state.actor(id: "hero")?.stats.actionPoints, 2)
        XCTAssertEqual(engine.state.actor(id: "wolf")?.stats.health, 14)
    }

    func testAllPlayerActorsDownMeansDefeat() {
        let state = BattleState(actors: [
            makeActor(id: "hero", faction: .player, health: 0),
            makeActor(id: "ally", faction: .player, health: 0),
            makeActor(id: "wolf", faction: .animal, health: 10)
        ])

        XCTAssertEqual(state.outcome, .defeat)
    }

    private func makeActor(
        id: String,
        faction: Faction,
        health: Int = 20,
        actionPoints: Int = 4
    ) -> Actor {
        Actor(
            id: id,
            displayName: id,
            kind: faction == .player ? .player : .animal,
            faction: faction,
            level: 1,
            stats: Stats(
                maxHealth: 20,
                health: health,
                attack: 5,
                defense: 2,
                evasion: 5,
                magic: 1,
                maxActionPoints: 4,
                actionPoints: actionPoints
            ),
            skillIDs: ["bite"]
        )
    }
}
