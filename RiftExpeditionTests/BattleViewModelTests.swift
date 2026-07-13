import CoreGraphics
import RiftCore
import XCTest
@testable import RiftExpedition

@MainActor
final class BattleViewModelTests: XCTestCase {
    // 敌人视觉 ID 多样化：具体动画资源由 actor-animations.json 决定。
    func testHumanEnemyVisualIDVariesByClassAndLevel() {
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "player", faction: .player, actionPoints: 4, skillIDs: [], kind: .player, classID: "warrior"),
                actor(id: "grunt_archer", faction: .hostile, actionPoints: 4, skillIDs: [], kind: .humanEnemy, classID: "archer", level: 2),
                actor(id: "grunt_warrior", faction: .hostile, actionPoints: 4, skillIDs: [], kind: .humanEnemy, classID: "warrior", level: 2),
                actor(id: "elite_guard", faction: .hostile, actionPoints: 4, skillIDs: [], kind: .humanEnemy, classID: "warrior", level: 4)
            ]),
            skills: []
        )

        let visualIDs = Dictionary(uniqueKeysWithValues: viewModel.sceneSnapshot.actors.map { ($0.id, $0.visualID) })

        XCTAssertEqual(visualIDs["player"], "actor_warrior")
        XCTAssertEqual(visualIDs["grunt_archer"], "enemy_human_ranged")
        XCTAssertEqual(visualIDs["grunt_warrior"], "enemy_human_melee")
        // 4 级的守卫不管战斗职业是什么，都应该读成「精英」视觉，这样即使它和前面的杂兵
        // 共用同一个 warrior 职业 ID，章节高潮战也能明显区分开来。
        XCTAssertEqual(visualIDs["elite_guard"], "enemy_human_elite")
        XCTAssertNotEqual(visualIDs["grunt_warrior"], visualIDs["player"])
    }

    func testSnapshotIncludesStableAnimationState() throws {
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "player", faction: .player, actionPoints: 4, skillIDs: [], kind: .player, classID: "warrior"),
                actor(id: "boar", faction: .animal, actionPoints: 4, skillIDs: [])
            ]),
            skills: []
        )

        let firstSnapshot = viewModel.sceneSnapshot
        let secondSnapshot = viewModel.sceneSnapshot
        let player = try XCTUnwrap(firstSnapshot.actors.first { $0.id == "player" })

        XCTAssertEqual(player.visualID, "actor_warrior")
        XCTAssertEqual(player.facing, .down)
        XCTAssertEqual(player.baseAction, .idle)
        XCTAssertEqual(firstSnapshot.presentationEvents, secondSnapshot.presentationEvents)
    }

    func testBeastAndMonsterVisualIDVariesByKindAndLevel() {
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "boar", faction: .animal, actionPoints: 4, skillIDs: [], kind: .animal, level: 1),
                actor(id: "cave_vermin", faction: .monster, actionPoints: 4, skillIDs: [], kind: .monster, level: 2),
                actor(id: "rift_hatchling", faction: .monster, actionPoints: 4, skillIDs: [], kind: .monster, level: 3)
            ]),
            skills: []
        )

        let visualIDs = Dictionary(uniqueKeysWithValues: viewModel.sceneSnapshot.actors.map { ($0.id, $0.visualID) })

        XCTAssertEqual(visualIDs["boar"], "enemy_beast_animal")
        XCTAssertEqual(visualIDs["cave_vermin"], "enemy_beast_tainted")
        // 等级更高的裂隙幼体应该比洞穴小怪显得更「腐化」。
        XCTAssertEqual(visualIDs["rift_hatchling"], "enemy_beast_rift")
        XCTAssertNotEqual(visualIDs["cave_vermin"], visualIDs["rift_hatchling"])
    }
    func testAPInsufficientDisablesSkillAndDoesNotSpendPoints() {
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "player", faction: .player, actionPoints: 1, skillIDs: ["heavy_slash"]),
                actor(id: "boar", faction: .animal, actionPoints: 4, skillIDs: [])
            ]),
            skills: [heavySlash]
        )

        XCTAssertFalse(viewModel.canUseSkill(id: "heavy_slash"))

        viewModel.performSkill(id: "heavy_slash")

        XCTAssertEqual(viewModel.state.actor(id: "player")?.stats.actionPoints, 1)
        XCTAssertEqual(viewModel.statusText, "AP 不足：需要 3，当前 1。")
    }

    func testSelectingSkillDoesNotSpendUntilTargetIsClicked() {
        var cues: [AudioCue] = []
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "player", faction: .player, actionPoints: 4, skillIDs: ["heavy_slash"]),
                actor(id: "boar", faction: .animal, health: 12, actionPoints: 4, skillIDs: [])
            ]),
            skills: [heavySlash],
            initialPositions: [
                "player": CGPoint(x: 100, y: 100),
                "boar": CGPoint(x: 120, y: 100)
            ],
            onAudioCue: { cues.append($0) }
        )

        viewModel.performSkill(id: "heavy_slash")

        XCTAssertEqual(viewModel.state.actor(id: "player")?.stats.actionPoints, 4)
        XCTAssertEqual(viewModel.state.actor(id: "boar")?.stats.health, 12)

        viewModel.performSelectedAction(targetID: "boar")

        XCTAssertEqual(viewModel.state.actor(id: "player")?.stats.actionPoints, 1)
        XCTAssertEqual(viewModel.state.actor(id: "boar")?.stats.health, 7)
        XCTAssertEqual(viewModel.sceneSnapshot.presentationEvents, [
            BattlePresentationEvent(
                id: 1,
                actorID: "player",
                action: .attack,
                direction: .right,
                targetActorID: "boar",
                sourcePoint: CGPoint(x: 100, y: 100),
                effectPoint: CGPoint(x: 120, y: 100),
                effectStyle: .strike,
                feedback: .damage(amount: 5, defeated: false)
            ),
            BattlePresentationEvent(
                id: 2,
                actorID: "boar",
                action: .hurt,
                direction: .left,
                targetActorID: "player",
                effectPoint: nil
            )
        ])
        XCTAssertEqual(cues, [.skillCast, .attackHit])
    }

    func testMoveToClickedPointSpendsAPAndUpdatesPosition() {
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "player", faction: .player, actionPoints: 4, skillIDs: []),
                actor(id: "boar", faction: .animal, actionPoints: 4, skillIDs: [])
            ]),
            skills: [],
            initialPositions: [
                "player": CGPoint(x: 100, y: 100),
                "boar": CGPoint(x: 220, y: 100)
            ]
        )

        viewModel.performMove(to: CGPoint(x: 156, y: 100))

        XCTAssertEqual(viewModel.state.actor(id: "player")?.stats.actionPoints, 3)
        XCTAssertEqual(viewModel.actorPositions["player"], CGPoint(x: 156, y: 100))
        XCTAssertEqual(viewModel.sceneSnapshot.actors.first { $0.id == "player" }?.facing, .right)
        XCTAssertEqual(viewModel.sceneSnapshot.presentationEvents.last, BattlePresentationEvent(
            id: 1,
            actorID: "player",
            action: .walk,
            direction: .right,
            targetActorID: nil,
            effectPoint: nil
        ))
    }


    func testPresentationEventsAreNotDroppedBeforeSceneConsumesThem() {
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "player", faction: .player, actionPoints: 20, skillIDs: []),
                actor(id: "boar", faction: .animal, actionPoints: 4, skillIDs: [])
            ]),
            skills: [],
            initialPositions: [
                "player": CGPoint(x: 100, y: 100),
                "boar": CGPoint(x: 600, y: 100)
            ]
        )

        for step in 1...10 {
            viewModel.performMove(to: CGPoint(x: 100 + CGFloat(step), y: 100))
        }

        XCTAssertEqual(viewModel.sceneSnapshot.presentationEvents.count, 10)
        XCTAssertEqual(viewModel.sceneSnapshot.presentationEvents.map(\.id), Array(1...10))
    }

    func testOutOfRangeTargetDoesNotSpendAP() {
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "player", faction: .player, actionPoints: 4, skillIDs: ["heavy_slash"]),
                actor(id: "boar", faction: .animal, actionPoints: 4, skillIDs: [])
            ]),
            skills: [heavySlash],
            initialPositions: [
                "player": CGPoint(x: 100, y: 100),
                "boar": CGPoint(x: 600, y: 100)
            ]
        )

        viewModel.performSkill(id: "heavy_slash")
        viewModel.performSelectedAction(targetID: "boar")

        XCTAssertEqual(viewModel.state.actor(id: "player")?.stats.actionPoints, 4)
        XCTAssertTrue(viewModel.statusText.hasPrefix("距离太远"))
    }

    func testConsumableUsesSkillEffectAndDecrementsInventory() {
        var cues: [AudioCue] = []
        let potion = ItemDefinition(
            id: "minor_healing_draught",
            displayName: "止血药剂",
            kind: .consumable,
            skillID: "minor_healing_draught"
        )
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "player", faction: .player, health: 4, actionPoints: 4, skillIDs: []),
                actor(id: "boar", faction: .animal, actionPoints: 4, skillIDs: [])
            ]),
            skills: [healingDraught],
            inventory: PartyInventory(itemCounts: ["minor_healing_draught": 1]),
            itemDefinitions: [potion],
            initialPositions: [
                "player": CGPoint(x: 100, y: 100),
                "boar": CGPoint(x: 220, y: 100)
            ],
            onAudioCue: { cues.append($0) }
        )

        viewModel.selectConsumable(id: "minor_healing_draught")
        viewModel.performSelectedAction(targetID: "player")

        XCTAssertEqual(viewModel.state.actor(id: "player")?.stats.health, 12)
        XCTAssertEqual(viewModel.state.actor(id: "player")?.stats.actionPoints, 3)
        XCTAssertEqual(viewModel.inventory.count(of: "minor_healing_draught"), 0)
        XCTAssertEqual(viewModel.selectedAction, .move)
        XCTAssertEqual(viewModel.sceneSnapshot.presentationEvents, [
            BattlePresentationEvent(
                id: 1,
                actorID: "player",
                action: .attack,
                direction: .down,
                targetActorID: "player",
                sourcePoint: CGPoint(x: 100, y: 100),
                effectPoint: CGPoint(x: 100, y: 100),
                effectStyle: .heal,
                feedback: .healing(amount: 8)
            )
        ])
        XCTAssertEqual(cues, [.healDrink])
    }

    func testDodgedPlayerSkillEmitsAttackWithoutHurt() {
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "player", faction: .player, actionPoints: 4, skillIDs: ["heavy_slash"]),
                actor(id: "rogue", faction: .hostile, actionPoints: 4, skillIDs: [], evasion: 100)
            ]),
            skills: [heavySlash],
            initialPositions: [
                "player": CGPoint(x: 100, y: 100),
                "rogue": CGPoint(x: 120, y: 100)
            ]
        )

        viewModel.performSkill(id: "heavy_slash")
        viewModel.performSelectedAction(targetID: "rogue")

        XCTAssertEqual(viewModel.state.actor(id: "rogue")?.stats.health, 12)
        XCTAssertEqual(viewModel.sceneSnapshot.presentationEvents, [
            BattlePresentationEvent(
                id: 1,
                actorID: "player",
                action: .attack,
                direction: .right,
                targetActorID: "rogue",
                sourcePoint: CGPoint(x: 100, y: 100),
                effectPoint: CGPoint(x: 120, y: 100),
                effectStyle: .strike,
                feedback: .dodge
            )
        ])
    }

    func testEndTurnAdvancesActiveActorAndRefreshesActionPoints() {
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "player", faction: .player, actionPoints: 0, skillIDs: []),
                actor(id: "ally", faction: .player, actionPoints: 0, skillIDs: [])
            ]),
            skills: []
        )

        viewModel.endTurn()

        XCTAssertEqual(viewModel.state.activeActorID, "ally")
        XCTAssertEqual(viewModel.state.actor(id: "ally")?.stats.actionPoints, 4)
    }

    func testPlayerActionDoesNotSpendPointsDuringEnemyTurn() {
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "boar", faction: .animal, actionPoints: 4, skillIDs: ["heavy_slash"]),
                actor(id: "player", faction: .player, actionPoints: 4, skillIDs: [])
            ]),
            skills: [heavySlash]
        )

        XCTAssertFalse(viewModel.canUseSkill(id: "heavy_slash"))

        viewModel.performSkill(id: "heavy_slash")

        XCTAssertEqual(viewModel.state.actor(id: "boar")?.stats.actionPoints, 4)
        XCTAssertEqual(viewModel.statusText, "当前不是玩家回合。")
    }

    func testEndTurnRunsEnemyAIAndReturnsToPlayerTurn() {
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "player", faction: .player, actionPoints: 4, skillIDs: []),
                actor(id: "boar", faction: .animal, actionPoints: 4, skillIDs: ["heavy_slash"])
            ]),
            skills: [heavySlash],
            initialPositions: [
                "player": CGPoint(x: 100, y: 100),
                "boar": CGPoint(x: 500, y: 100)
            ]
        )

        viewModel.endTurn()

        XCTAssertEqual(viewModel.state.activeActorID, "player")
        XCTAssertEqual(viewModel.state.actor(id: "boar")?.stats.actionPoints, 3)
        XCTAssertEqual(viewModel.statusText, "boar 逼近 player。")
        XCTAssertEqual(viewModel.sceneSnapshot.actors.first { $0.id == "boar" }?.facing, .left)
        XCTAssertEqual(viewModel.sceneSnapshot.presentationEvents.last?.actorID, "boar")
        XCTAssertEqual(viewModel.sceneSnapshot.presentationEvents.last?.action, .walk)
        XCTAssertEqual(viewModel.sceneSnapshot.presentationEvents.last?.direction, .left)
    }

    func testEnemySkillEmitsAttackAndHurtEvents() {
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "player", faction: .player, actionPoints: 4, skillIDs: []),
                actor(id: "boar", faction: .animal, actionPoints: 4, skillIDs: ["heavy_slash"])
            ]),
            skills: [heavySlash],
            initialPositions: [
                "player": CGPoint(x: 100, y: 100),
                "boar": CGPoint(x: 120, y: 100)
            ]
        )

        viewModel.endTurn()

        XCTAssertEqual(viewModel.state.activeActorID, "player")
        XCTAssertEqual(viewModel.state.actor(id: "player")?.stats.health, 7)
        XCTAssertEqual(viewModel.sceneSnapshot.presentationEvents, [
            BattlePresentationEvent(
                id: 1,
                actorID: "boar",
                action: .attack,
                direction: .left,
                targetActorID: "player",
                sourcePoint: CGPoint(x: 120, y: 100),
                effectPoint: CGPoint(x: 100, y: 100),
                effectStyle: .strike,
                feedback: .damage(amount: 5, defeated: false)
            ),
            BattlePresentationEvent(
                id: 2,
                actorID: "player",
                action: .hurt,
                direction: .right,
                targetActorID: "boar",
                effectPoint: nil
            )
        ])
    }


    func testRangedSkillCarriesSourcePointAndProjectileStyle() {
        let shot = SkillDefinition(
            id: "test_shot",
            displayName: "试射",
            actionPointCost: 1,
            range: 8,
            target: .enemy,
            affectsAllies: false,
            canBeDodged: false,
            effects: [.damage(4)]
        )
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "archer", faction: .player, actionPoints: 4, skillIDs: ["test_shot"], kind: .player, classID: "archer"),
                actor(id: "target", faction: .hostile, health: 12, actionPoints: 4, skillIDs: [])
            ]),
            skills: [shot],
            initialPositions: [
                "archer": CGPoint(x: 80, y: 120),
                "target": CGPoint(x: 240, y: 120)
            ]
        )

        viewModel.performSkill(id: "test_shot")
        viewModel.performSelectedAction(targetID: "target")

        let event = viewModel.sceneSnapshot.presentationEvents.first
        XCTAssertEqual(event?.sourcePoint, CGPoint(x: 80, y: 120))
        XCTAssertEqual(event?.effectPoint, CGPoint(x: 240, y: 120))
        XCTAssertEqual(event?.effectStyle, .projectile)
        XCTAssertEqual(event?.feedback, .damage(amount: 4, defeated: false))
    }

    func testLethalDamageMarksFeedbackAsDefeated() {
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "player", faction: .player, actionPoints: 4, skillIDs: ["heavy_slash"]),
                actor(id: "boar", faction: .animal, health: 4, actionPoints: 4, skillIDs: [])
            ]),
            skills: [heavySlash],
            initialPositions: [
                "player": CGPoint(x: 100, y: 100),
                "boar": CGPoint(x: 120, y: 100)
            ]
        )

        viewModel.performSkill(id: "heavy_slash")
        viewModel.performSelectedAction(targetID: "boar")

        XCTAssertEqual(
            viewModel.sceneSnapshot.presentationEvents.first?.feedback,
            .damage(amount: 4, defeated: true)
        )
    }

    private var heavySlash: SkillDefinition {
        SkillDefinition(
            id: "heavy_slash",
            displayName: "重劈",
            actionPointCost: 3,
            range: 2,
            target: .enemy,
            affectsAllies: false,
            canBeDodged: true,
            effects: [.damage(6)]
        )
    }

    private var healingDraught: SkillDefinition {
        SkillDefinition(
            id: "minor_healing_draught",
            displayName: "止血药剂",
            actionPointCost: 1,
            range: 2.5,
            target: .ally,
            affectsAllies: true,
            canBeDodged: false,
            effects: [.heal(8)]
        )
    }

    private func actor(
        id: String,
        faction: Faction,
        health: Int = 12,
        actionPoints: Int,
        skillIDs: [String],
        kind: ActorKind? = nil,
        classID: String? = nil,
        level: Int = 1,
        evasion: Int = 0
    ) -> Actor {
        Actor(
            id: id,
            displayName: id,
            kind: kind ?? (faction == .player ? .player : .animal),
            faction: faction,
            level: level,
            stats: Stats(
                maxHealth: 12,
                health: health,
                attack: 4,
                defense: 1,
                evasion: evasion,
                magic: 0,
                maxActionPoints: 4,
                actionPoints: actionPoints
            ),
            classID: classID,
            skillIDs: skillIDs
        )
    }
}
