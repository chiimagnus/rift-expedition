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
            skills: [heavySlash]
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

    private func actor(id: String, faction: Faction, actionPoints: Int, skillIDs: [String]) -> Actor {
        Actor(
            id: id,
            displayName: id,
            kind: faction == .player ? .player : .animal,
            faction: faction,
            level: 1,
            stats: Stats(
                maxHealth: 12,
                health: 12,
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
