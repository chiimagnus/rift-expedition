import CoreGraphics
import RiftCore
import XCTest
@testable import RiftExpedition

@MainActor
final class GameSessionViewModelTests: XCTestCase {
    func testAreaIDsMapToRegionalBGMCues() {
        XCTAssertEqual(AudioService.bgmCue(for: "village_square"), .villageTheme)
        XCTAssertEqual(AudioService.bgmCue(for: "village_riverside"), .villageTheme)
        XCTAssertEqual(AudioService.bgmCue(for: "wilds_road"), .wildsTheme)
        XCTAssertEqual(AudioService.bgmCue(for: "wilds_riverbank"), .wildsTheme)
        XCTAssertEqual(AudioService.bgmCue(for: "cave_entrance"), .caveTheme)
        XCTAssertEqual(AudioService.bgmCue(for: "cave_depths"), .caveTheme)
    }

    func testAreaIDsMapToAmbienceCues() {
        XCTAssertNil(AudioService.ambienceCue(for: "village_square"))
        XCTAssertNil(AudioService.ambienceCue(for: "wilds_road"))
        XCTAssertEqual(AudioService.ambienceCue(for: "cave_entrance"), .caveDrip)
        XCTAssertEqual(AudioService.ambienceCue(for: "cave_depths"), .caveDrip)
    }

    func testAudioServiceVolumeMuteAndBGMSwitchUseAllPlayers() {
        var playersByCue: [AudioCue: FakeAudioPlayer] = [:]
        let service = AudioService(
            makePlayer: { url in
                let cueID = url.deletingPathExtension().lastPathComponent
                let cue = try XCTUnwrap(AudioCue(rawValue: cueID))
                let player = FakeAudioPlayer()
                playersByCue[cue] = player
                return player
            },
            urlForCue: { cue in
                URL(fileURLWithPath: "/tmp/\(cue.rawValue).wav")
            }
        )

        service.masterVolume = 0.25
        XCTAssertTrue(playersByCue.values.allSatisfy { abs($0.volume - 0.25) < 0.001 })

        service.isMuted = true
        XCTAssertTrue(playersByCue.values.allSatisfy { $0.volume == 0 })

        service.isMuted = false
        service.playBGM(for: "village_square")
        XCTAssertEqual(playersByCue[.villageTheme]?.numberOfLoops, -1)
        XCTAssertEqual(playersByCue[.villageTheme]?.playCount, 1)

        service.playBGM(for: "wilds_road")
        XCTAssertEqual(playersByCue[.villageTheme]?.stopCount, 1)
        XCTAssertEqual(playersByCue[.wildsTheme]?.numberOfLoops, -1)
        XCTAssertEqual(playersByCue[.wildsTheme]?.playCount, 1)
    }

    func testAudioServiceMissingCuesDoNotCrash() {
        let service = AudioService(
            makePlayer: { _ in
                XCTFail("No player should be created when every cue URL is missing")
                return FakeAudioPlayer()
            },
            urlForCue: { _ in nil }
        )

        service.play(.uiClick)
        service.playBGM(for: "cave_entrance")
        service.playAmbience(for: "cave_entrance")
        service.stopBGM()
    }

    func testSessionAreaTransitionsRouteBGMAndAmbience() throws {
        var playersByCue: [AudioCue: FakeAudioPlayer] = [:]
        let audioService = AudioService(
            makePlayer: { url in
                let cueID = url.deletingPathExtension().lastPathComponent
                let cue = try XCTUnwrap(AudioCue(rawValue: cueID))
                let player = FakeAudioPlayer()
                playersByCue[cue] = player
                return player
            },
            urlForCue: { cue in
                URL(fileURLWithPath: "/tmp/\(cue.rawValue).wav")
            }
        )
        let session = GameSessionViewModel(audioService: audioService)
        let scene = GameScene(size: .init(width: 1, height: 1))
        session.partyCreationViewModel.toggleSelection("warrior")
        session.partyCreationViewModel.toggleSelection("mage")

        session.startChapterWithSelectedParty()
        XCTAssertEqual(playersByCue[.villageTheme]?.playCount, 1)

        session.explorationController.configureParty(
            session.party,
            at: try exitCenter(in: "village_square", to: "village_riverside")
        )
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(playersByCue[.villageTheme]?.playCount, 1)

        session.explorationController.configureParty(
            session.party,
            at: try exitCenter(in: "village_riverside", to: "wilds_riverbank")
        )
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(playersByCue[.villageTheme]?.stopCount, 1)
        XCTAssertEqual(playersByCue[.wildsTheme]?.playCount, 1)

        session.explorationController.configureParty(
            session.party,
            at: try exitCenter(in: "wilds_riverbank", to: "cave_entrance")
        )
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(playersByCue[.wildsTheme]?.stopCount, 1)
        XCTAssertEqual(playersByCue[.caveTheme]?.playCount, 1)
        XCTAssertEqual(playersByCue[.caveDrip]?.playCount, 1)
    }

    func testLeaderEnteringExitChangesArea() throws {
        let session = GameSessionViewModel()
        session.partyCreationViewModel.toggleSelection("warrior")
        session.partyCreationViewModel.toggleSelection("mage")
        session.startChapterWithSelectedParty()
        session.explorationController.configureParty(
            session.party,
            at: try exitCenter(in: "village_square", to: "village_riverside")
        )

        session.gameScene(GameScene(size: .init(width: 1, height: 1)), didAdvance: 1.0 / 60.0)

        XCTAssertEqual(session.currentAreaID, "village_riverside")
        XCTAssertEqual(session.currentSpawnID, "from_square")
        XCTAssertEqual(session.appState, .exploration)
        XCTAssertEqual(session.statusText, "进入区域：裂隙村河岸")
    }

    func testStartingChapterWritesSafeAutosave() throws {
        let directory = URL.temporaryDirectory
            .appending(path: "RiftExpeditionTests")
            .appending(path: UUID().uuidString)
        let store = SaveGameStore(directory: directory)
        let session = GameSessionViewModel(saveGameStore: store)
        session.partyCreationViewModel.toggleSelection("warrior")
        session.partyCreationViewModel.toggleSelection("mage")

        session.startChapterWithSelectedParty()

        let save = try store.read(.auto(1))
        XCTAssertEqual(save.currentAreaID, "village_square")
        XCTAssertEqual(save.party.count, 2)
    }

    func testBitterrootCanBePickedUpAndTurnedInForRewards() throws {
        let session = GameSessionViewModel()
        let scene = GameScene(size: .init(width: 1, height: 1))
        session.partyCreationViewModel.toggleSelection("warrior")
        session.partyCreationViewModel.toggleSelection("mage")
        session.startChapterWithSelectedParty()

        XCTAssertTrue(session.dialogViewModel.start(dialogID: "healer_request"))
        let accept = try XCTUnwrap(session.dialogViewModel.activeDialog?.options.first { $0.questID == "bitterroot_medicine" })
        XCTAssertEqual(session.dialogViewModel.choose(accept), .none)

        session.explorationController.configureParty(
            session.party,
            at: try exitCenter(in: "village_square", to: "village_riverside")
        )
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(session.currentAreaID, "village_riverside")

        session.explorationController.configureParty(
            session.party,
            at: try exitCenter(in: "village_riverside", to: "wilds_riverbank")
        )
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(session.currentAreaID, "wilds_riverbank")

        let bitterrootPosition = try itemPosition(in: "wilds_riverbank", itemID: "bitterroot_herb")
        session.explorationController.configureParty(session.party, at: bitterrootPosition)
        session.gameScene(scene, didClickWorld: bitterrootPosition)
        XCTAssertEqual(session.inventoryViewModel?.inventory.count(of: "bitterroot_herb"), 1)

        session.explorationController.configureParty(
            session.party,
            at: try exitCenter(in: "wilds_riverbank", to: "village_riverside")
        )
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(session.currentAreaID, "village_riverside")
        if session.appState == .dialogue {
            session.closePanel()
        }

        let healerPosition = try npcPosition(in: "village_riverside", actorID: "healer")
        session.explorationController.configureParty(session.party, at: healerPosition)
        session.gameScene(scene, didClickWorld: healerPosition)
        XCTAssertEqual(session.appState, .dialogue)
        XCTAssertEqual(session.dialogViewModel.activeDialog?.id, "healer_return")

        let complete = try XCTUnwrap(session.dialogViewModel.activeDialog?.options.first { $0.questID == "bitterroot_medicine" })
        XCTAssertEqual(session.dialogViewModel.choose(complete), .completedQuest("bitterroot_medicine"))
        session.applyQuestRewards(questID: "bitterroot_medicine")

        XCTAssertEqual(session.inventoryViewModel?.inventory.count(of: "bitterroot_herb"), 0)
        XCTAssertEqual(session.inventoryViewModel?.inventory.count(of: "river_charm"), 1)
        XCTAssertEqual(session.inventoryViewModel?.inventory.count(of: "minor_healing_draught"), 3)
    }

    private func exitCenter(in areaID: String, to targetAreaID: String) throws -> CGPoint {
        let metadata = try TiledMapLoader.loadMetadata(areaID: areaID)
        let exit = try XCTUnwrap(metadata.exits.first { $0.targetAreaID == targetAreaID })
        return exit.frame.center
    }

    private func itemPosition(in areaID: String, itemID: String) throws -> CGPoint {
        let metadata = try TiledMapLoader.loadMetadata(areaID: areaID)
        return try XCTUnwrap(metadata.items.first { $0.itemID == itemID }).position
    }

    private func npcPosition(in areaID: String, actorID: String) throws -> CGPoint {
        let metadata = try TiledMapLoader.loadMetadata(areaID: areaID)
        return try XCTUnwrap(metadata.npcs.first { $0.actorID == actorID }).position
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

private final class FakeAudioPlayer: AudioPlaying {
    var currentTime: TimeInterval = 0
    var volume: Float = 1
    var numberOfLoops = 0
    private(set) var isPlaying = false
    private(set) var playCount = 0
    private(set) var stopCount = 0

    func play() -> Bool {
        playCount += 1
        isPlaying = true
        return true
    }

    func stop() {
        stopCount += 1
        isPlaying = false
    }

    func prepareToPlay() -> Bool {
        true
    }
}
