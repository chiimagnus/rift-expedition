import Foundation
import RiftCore
import XCTest
@testable import RiftExpedition

@MainActor
final class GameOverRecoveryTests: XCTestCase {
    func testPartyWipeLoadsLatestSafeAutosave() throws {
        let store = makeStore()
        try store.write(makeSave(areaID: "village_square", spawnID: "start"), to: .auto(1), safety: .safe)
        try store.write(makeSave(areaID: "village_riverside", spawnID: "from_square"), to: .auto(2), safety: .safe)
        try setModifiedAt(Date(timeIntervalSince1970: 1), slot: .auto(1), store: store)
        try setModifiedAt(Date(timeIntervalSince1970: 2), slot: .auto(2), store: store)

        let session = GameSessionViewModel(saveGameStore: store)
        session.appState = .battle
        session.currentAreaID = "cave_depths"
        session.battleViewModel = BattleViewModel(
            state: BattleState(actors: [
                makeActor(id: "player_1", faction: .player, health: 0),
                makeActor(id: "player_2", faction: .player, health: 0),
                makeActor(id: "raider", faction: .hostile, health: 12)
            ]),
            skills: []
        )

        session.finishBattle()

        XCTAssertEqual(session.appState, .exploration)
        XCTAssertEqual(session.currentAreaID, "village_riverside")
        XCTAssertEqual(session.currentSpawnID, "from_square")
        XCTAssertNil(session.battleViewModel)
        XCTAssertEqual(session.party.count, 2)
        XCTAssertEqual(session.statusText, "全队倒下，已读取自动槽 2 的安全自动存档。")
    }

    func testPartyWipeWithoutAutosaveReturnsToMainMenu() {
        let session = GameSessionViewModel(saveGameStore: makeStore())
        session.appState = .battle
        session.battleViewModel = BattleViewModel(
            state: BattleState(actors: [
                makeActor(id: "player_1", faction: .player, health: 0),
                makeActor(id: "player_2", faction: .player, health: 0),
                makeActor(id: "raider", faction: .hostile, health: 12)
            ]),
            skills: []
        )

        session.finishBattle()

        XCTAssertEqual(session.appState, .mainMenu)
        XCTAssertNil(session.battleViewModel)
        XCTAssertEqual(session.statusText, "全队倒下，但没有可用自动存档；已返回主菜单。")
    }

    func testAutosaveFailureShowsNonBlockingChineseWarning() throws {
        let blockedDirectory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try Data("not a directory".utf8).write(to: blockedDirectory)
        defer { try? FileManager.default.removeItem(at: blockedDirectory) }

        let session = GameSessionViewModel(saveGameStore: SaveGameStore(directory: blockedDirectory))
        session.partyCreationViewModel.toggleSelection("warrior")
        session.partyCreationViewModel.toggleSelection("mage")

        session.startChapterWithSelectedParty()

        XCTAssertEqual(session.appState, .exploration)
        XCTAssertEqual(session.party.count, 2)
        XCTAssertEqual(session.statusText, "自动存档失败；已保留上一个安全存档。")
    }

    func testVictoryRevivesDownedPartyMemberAfterBattle() {
        let session = GameSessionViewModel(saveGameStore: makeStore())
        session.appState = .battle
        session.battleViewModel = BattleViewModel(
            state: BattleState(actors: [
                makeActor(id: "player_1", faction: .player, health: 0),
                makeActor(id: "player_2", faction: .player, health: 8),
                makeActor(id: "raider", faction: .hostile, health: 0)
            ]),
            skills: []
        )

        session.finishBattle()

        XCTAssertEqual(session.appState, .exploration)
        XCTAssertEqual(session.party.first { $0.id == "player_1" }?.stats.health, 10)
        XCTAssertEqual(session.statusText, "战斗胜利。倒下的队友已在战后复活。")
    }

    private func makeStore() -> SaveGameStore {
        SaveGameStore(directory: URL.temporaryDirectory.appending(path: UUID().uuidString))
    }

    private func makeSave(areaID: String, spawnID: String) -> SaveGame {
        SaveGame(
            currentAreaID: areaID,
            currentSpawnID: spawnID,
            party: [
                makeActor(id: "player_1", faction: .player, health: 20),
                makeActor(id: "player_2", faction: .player, health: 20)
            ],
            inventory: PartyInventory()
        )
    }

    private func setModifiedAt(_ date: Date, slot: SaveSlot, store: SaveGameStore) throws {
        try FileManager.default.setAttributes(
            [.modificationDate: date],
            ofItemAtPath: store.fileURL(for: slot).path
        )
    }

    private func makeActor(id: String, faction: Faction, health: Int) -> Actor {
        Actor(
            id: id,
            displayName: id,
            kind: kind(for: faction),
            faction: faction,
            level: 1,
            stats: Stats(
                maxHealth: 20,
                health: health,
                attack: 5,
                defense: 2,
                evasion: 0,
                magic: 1,
                maxActionPoints: 4,
                actionPoints: 4
            ),
            skillIDs: []
        )
    }

    private func kind(for faction: Faction) -> ActorKind {
        switch faction {
        case .player:
            .player
        case .civilian:
            .npc
        case .hostile:
            .humanEnemy
        case .animal:
            .animal
        case .monster:
            .monster
        }
    }
}
