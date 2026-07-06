import CoreGraphics
import RiftCore
import XCTest
@testable import RiftExpedition

@MainActor
final class BattleViewModelTests: XCTestCase {
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
        let viewModel = BattleViewModel(
            state: BattleState(actors: [
                actor(id: "player", faction: .player, actionPoints: 4, skillIDs: ["heavy_slash"]),
                actor(id: "boar", faction: .animal, health: 12, actionPoints: 4, skillIDs: [])
            ]),
            skills: [heavySlash],
            initialPositions: [
                "player": CGPoint(x: 100, y: 100),
                "boar": CGPoint(x: 120, y: 100)
            ]
        )

        viewModel.performSkill(id: "heavy_slash")

        XCTAssertEqual(viewModel.state.actor(id: "player")?.stats.actionPoints, 4)
        XCTAssertEqual(viewModel.state.actor(id: "boar")?.stats.health, 12)

        viewModel.performSelectedAction(targetID: "boar")

        XCTAssertEqual(viewModel.state.actor(id: "player")?.stats.actionPoints, 1)
        XCTAssertEqual(viewModel.state.actor(id: "boar")?.stats.health, 7)
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
            ]
        )

        viewModel.selectConsumable(id: "minor_healing_draught")
        viewModel.performSelectedAction(targetID: "player")

        XCTAssertEqual(viewModel.state.actor(id: "player")?.stats.health, 12)
        XCTAssertEqual(viewModel.state.actor(id: "player")?.stats.actionPoints, 3)
        XCTAssertEqual(viewModel.inventory.count(of: "minor_healing_draught"), 0)
        XCTAssertEqual(viewModel.selectedAction, .move)
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
        skillIDs: [String]
    ) -> Actor {
        Actor(
            id: id,
            displayName: id,
            kind: faction == .player ? .player : .animal,
            faction: faction,
            level: 1,
            stats: Stats(
                maxHealth: 12,
                health: health,
                attack: 4,
                defense: 1,
                evasion: 0,
                magic: 0,
                maxActionPoints: 4,
                actionPoints: actionPoints
            ),
            skillIDs: skillIDs
        )
    }
}
