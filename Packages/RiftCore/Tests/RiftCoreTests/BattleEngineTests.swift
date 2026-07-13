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
            canBeDodged: true,
            effects: [.damage(8)]
        )
        var random = SeededRandomSource(seed: 1)

        XCTAssertThrowsError(try engine.useSkill(
            actorID: "hero",
            targetID: "wolf",
            skill: skill,
            context: TargetingContext(distance: 1, hasLineOfSight: true, isAlly: false),
            random: &random
        )) { error in
            XCTAssertEqual(error as? BattleActionError, .insufficientActionPoints(required: 2, available: 1))
        }
    }

    func testNegativeActionPointCostIsRejectedWithoutIncreasingAP() throws {
        var engine = BattleEngine(state: BattleState(actors: [
            makeActor(id: "hero", faction: .player, actionPoints: 2),
            makeActor(id: "wolf", faction: .animal)
        ]))
        let skill = SkillDefinition(
            id: "broken_skill",
            displayName: "错误技能",
            actionPointCost: -2,
            range: 1,
            target: .enemy,
            affectsAllies: false,
            canBeDodged: false,
            effects: [.damage(1)]
        )
        var random = SeededRandomSource(seed: 1)

        XCTAssertThrowsError(try engine.useSkill(
            actorID: "hero",
            targetID: "wolf",
            skill: skill,
            context: TargetingContext(distance: 1, hasLineOfSight: true, isAlly: false),
            random: &random
        )) { error in
            XCTAssertEqual(error as? BattleActionError, .invalidActionPointCost(-2))
        }
        XCTAssertEqual(engine.state.actor(id: "hero")?.stats.actionPoints, 2)
        XCTAssertEqual(engine.state.actor(id: "wolf")?.stats.health, 20)
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

    func testEndTurnSkipsDefeatedActors() throws {
        var engine = BattleEngine(state: BattleState(actors: [
            makeActor(id: "hero", faction: .player),
            makeActor(id: "fallen", faction: .player, health: 0, actionPoints: 0),
            makeActor(id: "wolf", faction: .animal, actionPoints: 0)
        ]))

        try engine.endTurn()

        XCTAssertEqual(engine.state.activeActorID, "wolf")
        XCTAssertEqual(engine.state.actor(id: "wolf")?.stats.actionPoints, 4)
    }

    func testEndTurnTicksStatusesAndCanEndBattle() throws {
        var poisonedWolf = makeActor(id: "wolf", faction: .animal, health: 2)
        poisonedWolf.statuses = [StatusEffect(type: .poisoned, remainingTurns: 1)]
        var state = BattleState(actors: [
            poisonedWolf,
            makeActor(id: "hero", faction: .player)
        ])
        state.turnOrder = TurnOrder(actorIDs: ["wolf", "hero"])
        var engine = BattleEngine(state: state)

        try engine.endTurn()

        XCTAssertEqual(engine.state.actor(id: "wolf")?.stats.health, 0)
        XCTAssertEqual(engine.state.actor(id: "wolf")?.statuses, [])
        XCTAssertEqual(engine.state.outcome, .victory)
        XCTAssertEqual(engine.state.activeActorID, "wolf")
    }

    func testMovementUsesStartingDistancePerAPValue() throws {
        // 小范围测试计划：在这个最小可玩版本里，一个回合应该刚好能走到相邻的一个战术点位。
        // 如果移动距离太大，就调低 movementDistancePerAPStartingValue；太小就调高。
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

    func testBattleStartsWithFirstLivingActorWhenEarlierActorIsDefeated() {
        let state = BattleState(actors: [
            makeActor(id: "fallen", faction: .player, health: 0),
            makeActor(id: "hero", faction: .player, health: 20),
            makeActor(id: "wolf", faction: .animal, health: 20)
        ])

        XCTAssertEqual(state.activeActorID, "hero")
        XCTAssertEqual(state.outcome, .ongoing)
    }

    func testBattleWithNoLivingActorsIsTerminalAndRejectsTurnAdvance() {
        var engine = BattleEngine(state: BattleState(actors: [
            makeActor(id: "fallen_hero", faction: .player, health: 0),
            makeActor(id: "fallen_wolf", faction: .animal, health: 0)
        ]))

        XCTAssertEqual(engine.state.outcome, .defeat)
        XCTAssertThrowsError(try engine.endTurn()) { error in
            XCTAssertEqual(error as? BattleActionError, .battleAlreadyEnded(.defeat))
        }
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
