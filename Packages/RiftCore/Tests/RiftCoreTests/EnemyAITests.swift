import XCTest
@testable import RiftCore

final class EnemyAITests: XCTestCase {
    func testMeleeMovesTowardClosestTargetWhenOutOfRange() {
        let actor = makeActor(id: "wolf", faction: .animal, skillIDs: ["bite"])
        let state = BattleState(actors: [
            actor,
            makeActor(id: "far_hero", faction: .player),
            makeActor(id: "near_hero", faction: .player)
        ])
        let context = EnemyAIContext(
            skills: [skill(id: "bite", range: 1.2)],
            distancesByTargetID: ["far_hero": 8.0, "near_hero": 4.0]
        )

        let action = EnemyAI.chooseAction(for: actor, tendency: .melee, in: state, context: context)

        XCTAssertEqual(action, .moveToward(targetID: "near_hero", distance: APRules.movementDistancePerAPStartingValue))
    }

    func testArcherKeepsDistanceWhenTargetIsTooClose() {
        let actor = makeActor(id: "bandit_archer", faction: .hostile, skillIDs: ["shot"])
        let state = BattleState(actors: [
            actor,
            makeActor(id: "hero", faction: .player)
        ])
        let context = EnemyAIContext(
            skills: [skill(id: "shot", range: 6.0)],
            distancesByTargetID: ["hero": 1.5]
        )

        let action = EnemyAI.chooseAction(for: actor, tendency: .archer, in: state, context: context)

        XCTAssertEqual(action, .moveAway(targetID: "hero", distance: APRules.movementDistancePerAPStartingValue))
    }

    func testMagePrefersElementalSkill() {
        let actor = makeActor(id: "cult_mage", faction: .hostile, skillIDs: ["slash", "spark"])
        let state = BattleState(actors: [
            actor,
            makeActor(id: "hero", faction: .player)
        ])
        let context = EnemyAIContext(
            skills: [
                skill(id: "slash", range: 2.0, canBeDodged: true),
                skill(id: "spark", range: 5.0, canBeDodged: false)
            ],
            distancesByTargetID: ["hero": 4.0]
        )

        let action = EnemyAI.chooseAction(for: actor, tendency: .mage, in: state, context: context)

        XCTAssertEqual(action, .useSkill(skillID: "spark", targetID: "hero"))
    }

    func testRogueTargetsLowestHealthActor() {
        let actor = makeActor(id: "assassin", faction: .hostile, skillIDs: ["backstab"])
        let state = BattleState(actors: [
            actor,
            makeActor(id: "healthy_hero", faction: .player, health: 20),
            makeActor(id: "weak_hero", faction: .player, health: 3)
        ])
        let context = EnemyAIContext(
            skills: [skill(id: "backstab", actionPointCost: 3, range: 1.5)],
            distancesByTargetID: ["healthy_hero": 1.0, "weak_hero": 1.2]
        )

        let action = EnemyAI.chooseAction(for: actor, tendency: .rogue, in: state, context: context)

        XCTAssertEqual(action, .useSkill(skillID: "backstab", targetID: "weak_hero"))
    }

    func testNoActionPointsEndsTurn() {
        let actor = makeActor(id: "wolf", faction: .animal, actionPoints: 0, skillIDs: ["bite"])
        let state = BattleState(actors: [
            actor,
            makeActor(id: "hero", faction: .player)
        ])
        let context = EnemyAIContext(
            skills: [skill(id: "bite", range: 1.2)],
            distancesByTargetID: ["hero": 4.0]
        )

        let action = EnemyAI.chooseAction(for: actor, tendency: .melee, in: state, context: context)

        XCTAssertEqual(action, .endTurn)
    }

    private func makeActor(
        id: String,
        faction: Faction,
        health: Int = 20,
        actionPoints: Int = 4,
        skillIDs: [String] = []
    ) -> Actor {
        let kind: ActorKind
        switch faction {
        case .player:
            kind = .player
        case .animal:
            kind = .animal
        case .monster:
            kind = .monster
        default:
            kind = .humanEnemy
        }

        return Actor(
            id: id,
            displayName: id,
            kind: kind,
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
            skillIDs: skillIDs
        )
    }

    private func skill(
        id: String,
        actionPointCost: Int = 2,
        range: Double,
        canBeDodged: Bool = true
    ) -> SkillDefinition {
        SkillDefinition(
            id: id,
            displayName: id,
            actionPointCost: actionPointCost,
            range: range,
            target: .enemy,
            affectsAllies: false,
            canBeDodged: canBeDodged
        )
    }
}
