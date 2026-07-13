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

    func testAreaIDsMapToSoundscapeAmbienceCues() {
        XCTAssertEqual(AudioService.soundscapeAmbienceCue(for: "village_square"), .villageAmbience)
        XCTAssertEqual(AudioService.soundscapeAmbienceCue(for: "wilds_road"), .wildsAmbience)
        XCTAssertEqual(AudioService.soundscapeAmbienceCue(for: "cave_entrance"), .caveDripLoop)
        XCTAssertEqual(AudioService.soundscapeAmbienceCue(for: "cave_depths"), .caveRumble)
    }

    func testAudioServiceVolumeMuteAndBGMSwitchUseAllPlayers() {
        var playersByCue: [AudioCue: FakeAudioPlayer] = [:]
        let service = AudioService(
            crossfadeDuration: 0,
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
        service.playExplorationSoundscape(for: "village_square")
        XCTAssertEqual(playersByCue[.villageTheme]?.numberOfLoops, -1)
        XCTAssertEqual(playersByCue[.villageTheme]?.playCount, 1)

        service.playExplorationSoundscape(for: "wilds_road")
        XCTAssertEqual(playersByCue[.villageTheme]?.stopCount, 1)
        XCTAssertEqual(playersByCue[.wildsTheme]?.numberOfLoops, -1)
        XCTAssertEqual(playersByCue[.wildsTheme]?.playCount, 1)
    }

    func testAudioServiceMixerVolumesAffectOnlyTheirBus() throws {
        var playersByCue: [AudioCue: FakeAudioPlayer] = [:]
        let service = AudioService(
            makePlayer: { url in
                let cue = try XCTUnwrap(AudioCue(rawValue: url.deletingPathExtension().lastPathComponent))
                let player = FakeAudioPlayer()
                playersByCue[cue] = player
                return player
            },
            urlForCue: { cue in URL(fileURLWithPath: "/tmp/\(cue.rawValue).wav") }
        )

        service.masterVolume = 0.5
        service.musicVolume = 0.4
        service.ambienceVolume = 0.6
        service.sfxVolume = 0.8

        XCTAssertEqual(try XCTUnwrap(playersByCue[.villageTheme]).volume, 0.2, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(playersByCue[.riverAmbience]).volume, 0.3, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(playersByCue[.attackHit]).volume, 0.4, accuracy: 0.001)
    }


    func testAudioSoundscapeStateIsIdempotentAndRoutesThreeLoopBuses() throws {
        var playersByCue: [AudioCue: FakeAudioPlayer] = [:]
        let service = AudioService(
            crossfadeDuration: 0,
            makePlayer: { url in
                let cue = try XCTUnwrap(AudioCue(rawValue: url.deletingPathExtension().lastPathComponent))
                let player = FakeAudioPlayer()
                playersByCue[cue] = player
                return player
            },
            urlForCue: { cue in URL(fileURLWithPath: "/tmp/\(cue.rawValue).wav") }
        )

        service.playExplorationSoundscape(for: "village_riverside")
        service.playExplorationSoundscape(for: "village_riverside")

        XCTAssertEqual(
            service.soundscapeSnapshot,
            AudioSoundscapeSnapshot(
                state: .exploration(areaID: "village_riverside"),
                bgmCue: .villageTheme,
                musicLayerCue: .villageLayer,
                ambienceCue: .riverAmbience
            )
        )
        XCTAssertEqual(playersByCue[.villageTheme]?.playCount, 1)
        XCTAssertEqual(playersByCue[.villageLayer]?.playCount, 1)
        XCTAssertEqual(playersByCue[.riverAmbience]?.playCount, 1)

        service.playBattleSoundscape(for: "village_riverside")
        service.playBattleSoundscape(for: "village_riverside")

        XCTAssertEqual(
            service.soundscapeSnapshot,
            AudioSoundscapeSnapshot(
                state: .battle(areaID: "village_riverside"),
                bgmCue: .battleTheme,
                musicLayerCue: .battleLayer,
                ambienceCue: nil
            )
        )
        XCTAssertEqual(playersByCue[.villageTheme]?.stopCount, 1)
        XCTAssertEqual(playersByCue[.villageLayer]?.stopCount, 1)
        XCTAssertEqual(playersByCue[.riverAmbience]?.stopCount, 1)
        XCTAssertEqual(playersByCue[.battleTheme]?.playCount, 1)
        XCTAssertEqual(playersByCue[.battleLayer]?.playCount, 1)

        service.playExplorationSoundscape(for: "village_riverside")
        XCTAssertEqual(playersByCue[.battleTheme]?.stopCount, 1)
        XCTAssertEqual(playersByCue[.battleLayer]?.stopCount, 1)
        XCTAssertEqual(playersByCue[.villageTheme]?.playCount, 2)
        XCTAssertEqual(playersByCue[.villageLayer]?.playCount, 2)
        XCTAssertEqual(playersByCue[.riverAmbience]?.playCount, 2)
    }


    func testAudioCrossfadeUsesFadeRequestsBeforeStoppingOldLoops() throws {
        var playersByCue: [AudioCue: FakeAudioPlayer] = [:]
        let service = AudioService(
            crossfadeDuration: 0.2,
            makePlayer: { url in
                let cue = try XCTUnwrap(AudioCue(rawValue: url.deletingPathExtension().lastPathComponent))
                let player = FakeAudioPlayer()
                playersByCue[cue] = player
                return player
            },
            urlForCue: { cue in URL(fileURLWithPath: "/tmp/\(cue.rawValue).wav") }
        )

        service.playExplorationSoundscape(for: "village_square")
        service.playBattleSoundscape(for: "village_square")

        let villageTheme = try XCTUnwrap(playersByCue[.villageTheme])
        let battleTheme = try XCTUnwrap(playersByCue[.battleTheme])
        XCTAssertEqual(villageTheme.stopCount, 0)
        let villageFade = try XCTUnwrap(villageTheme.fadeRequests.last)
        let battleFade = try XCTUnwrap(battleTheme.fadeRequests.last)
        XCTAssertEqual(villageFade.volume, 0, accuracy: 0.001)
        XCTAssertEqual(villageFade.duration, 0.2, accuracy: 0.001)
        XCTAssertEqual(battleFade.volume, 0.75, accuracy: 0.001)
        XCTAssertEqual(battleFade.duration, 0.2, accuracy: 0.001)
    }

    func testMixerUpdateDoesNotRaiseLoopThatIsFadingOut() throws {
        var playersByCue: [AudioCue: FakeAudioPlayer] = [:]
        let service = AudioService(
            crossfadeDuration: 0.2,
            makePlayer: { url in
                let cue = try XCTUnwrap(AudioCue(rawValue: url.deletingPathExtension().lastPathComponent))
                let player = FakeAudioPlayer()
                playersByCue[cue] = player
                return player
            },
            urlForCue: { cue in URL(fileURLWithPath: "/tmp/\(cue.rawValue).wav") }
        )

        service.playExplorationSoundscape(for: "village_square")
        service.playBattleSoundscape(for: "village_square")
        let fadingVillageTheme = try XCTUnwrap(playersByCue[.villageTheme])
        XCTAssertEqual(fadingVillageTheme.volume, 0, accuracy: 0.001)

        service.masterVolume = 0.5

        XCTAssertEqual(fadingVillageTheme.volume, 0, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(playersByCue[.battleTheme]).volume, 0.5, accuracy: 0.001)
    }

    func testAudioCrossfadeGenerationDoesNotStopRestartedLoop() async throws {
        var playersByCue: [AudioCue: FakeAudioPlayer] = [:]
        let service = AudioService(
            crossfadeDuration: 0.02,
            makePlayer: { url in
                let cue = try XCTUnwrap(AudioCue(rawValue: url.deletingPathExtension().lastPathComponent))
                let player = FakeAudioPlayer()
                playersByCue[cue] = player
                return player
            },
            urlForCue: { cue in URL(fileURLWithPath: "/tmp/\(cue.rawValue).wav") }
        )

        service.playExplorationSoundscape(for: "village_square")
        service.playBattleSoundscape(for: "village_square")
        service.playExplorationSoundscape(for: "village_square")
        try await Task.sleep(for: .milliseconds(60))

        let villageTheme = try XCTUnwrap(playersByCue[.villageTheme])
        let battleTheme = try XCTUnwrap(playersByCue[.battleTheme])
        XCTAssertTrue(villageTheme.isPlaying)
        XCTAssertEqual(villageTheme.stopCount, 0)
        XCTAssertFalse(battleTheme.isPlaying)
        XCTAssertEqual(battleTheme.stopCount, 1)
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
        service.playExplorationSoundscape(for: "cave_entrance")
        service.playBattleSoundscape(for: "cave_entrance")
        service.stopSoundscape()
    }

    func testSessionAreaTransitionsRouteBGMAndAmbience() throws {
        var playersByCue: [AudioCue: FakeAudioPlayer] = [:]
        let audioService = AudioService(
            crossfadeDuration: 0,
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

    func testEncounterVictoryPersistsAcrossAreaReloadAndManualLoad() throws {
        let directory = URL.temporaryDirectory
            .appending(path: "RiftExpeditionTests")
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = SaveGameStore(directory: directory)
        let session = GameSessionViewModel(saveGameStore: store)
        let scene = GameScene(size: .init(width: 1, height: 1))
        startTestParty(in: session)
        try move(session, through: scene, from: "village_square", to: "village_outskirts")

        let trigger = try encounterTrigger(in: "village_outskirts")
        session.explorationController.configureParty(session.party, at: trigger.center)
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(session.appState, .battle)

        session.battleViewModel = victoryBattleViewModel(for: session)
        session.finishBattle()

        let resolvedKey = "village_outskirts:\(trigger.tiledID)"
        XCTAssertEqual(session.appState, .exploration)
        XCTAssertTrue(session.session.resolvedEncounterKeys.contains(resolvedKey))
        XCTAssertTrue(try store.read(.auto(1)).resolvedEncounterKeys.contains(resolvedKey))

        try move(session, through: scene, from: "village_outskirts", to: "village_square")
        try move(session, through: scene, from: "village_square", to: "village_outskirts")
        session.explorationController.configureParty(session.party, at: trigger.center)
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(session.appState, .exploration)
        XCTAssertNil(session.battleViewModel)

        session.openSaveLoad()
        session.saveLoadViewModel?.saveManual(slot: .manual(1))

        let loaded = GameSessionViewModel(saveGameStore: store)
        loaded.openSaveLoad()
        loaded.saveLoadViewModel?.load(slot: .manual(1))
        XCTAssertTrue(loaded.session.resolvedEncounterKeys.contains(resolvedKey))

        loaded.explorationController.configureParty(loaded.party, at: trigger.center)
        loaded.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(loaded.appState, .exploration)
        XCTAssertNil(loaded.battleViewModel)
    }

    func testPartyWipeDoesNotResolveEncounterAndAllowsRetry() throws {
        let directory = URL.temporaryDirectory
            .appending(path: "RiftExpeditionTests")
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = SaveGameStore(directory: directory)
        let session = GameSessionViewModel(saveGameStore: store)
        let scene = GameScene(size: .init(width: 1, height: 1))
        startTestParty(in: session)
        try move(session, through: scene, from: "village_square", to: "village_outskirts")

        let trigger = try encounterTrigger(in: "village_outskirts")
        session.explorationController.configureParty(session.party, at: trigger.center)
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(session.appState, .battle)

        session.battleViewModel = defeatBattleViewModel(for: session)
        session.finishBattle()

        let unresolvedKey = "village_outskirts:\(trigger.tiledID)"
        XCTAssertEqual(session.currentAreaID, "village_square")
        XCTAssertFalse(session.session.resolvedEncounterKeys.contains(unresolvedKey))

        try move(session, through: scene, from: "village_square", to: "village_outskirts")
        session.explorationController.configureParty(session.party, at: trigger.center)
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(session.appState, .battle)
        XCTAssertNotNil(session.battleViewModel)
    }

    func testManualSavePersistsAcceptedQuestAndWorldProgress() throws {
        let directory = URL.temporaryDirectory
            .appending(path: "RiftExpeditionTests")
            .appending(path: UUID().uuidString)
        let store = SaveGameStore(directory: directory)
        let session = GameSessionViewModel(saveGameStore: store)
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
        session.explorationController.configureParty(
            session.party,
            at: try exitCenter(in: "village_riverside", to: "wilds_riverbank")
        )
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        let bitterrootPosition = try itemPosition(in: "wilds_riverbank", itemID: "bitterroot_herb")
        session.explorationController.configureParty(session.party, at: bitterrootPosition)
        session.gameScene(scene, didClickWorld: bitterrootPosition)

        session.openSaveLoad()
        session.saveLoadViewModel?.saveManual(slot: .manual(1))
        let save = try store.read(.manual(1))

        XCTAssertEqual(save.questState.statuses["bitterroot_medicine"], .active)
        XCTAssertEqual(save.inventory.count(of: "bitterroot_herb"), 1)
        XCTAssertFalse(save.collectedMapItemKeys.isEmpty)
    }

#if DEBUG
    func testDebugSkillsScreenSeedsAPlayableParty() {
        let session = GameSessionViewModel()

        session.configureDebugScreen(named: "skills")

        XCTAssertEqual(session.appState, .inventory)
        XCTAssertEqual(session.inventoryTab, .skills)
        XCTAssertEqual(session.party.count, 2)
        XCTAssertNotNil(session.inventoryViewModel)
        XCTAssertFalse(session.inventory.itemCounts.isEmpty)
        XCTAssertFalse(session.dialogViewModel.questLogEntries.isEmpty)
    }
#endif

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

    private func startTestParty(in session: GameSessionViewModel) {
        session.partyCreationViewModel.toggleSelection("warrior")
        session.partyCreationViewModel.toggleSelection("mage")
        session.startChapterWithSelectedParty()
    }

    private func move(
        _ session: GameSessionViewModel,
        through scene: GameScene,
        from areaID: String,
        to targetAreaID: String
    ) throws {
        let destination = try exitCenter(in: areaID, to: targetAreaID)
        session.explorationController.configureParty(session.party, at: destination)
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
    }

    private func encounterTrigger(in areaID: String) throws -> MapEncounterTrigger {
        let metadata = try TiledMapLoader.loadMetadata(areaID: areaID)
        return try XCTUnwrap(metadata.encounterTriggers.first)
    }

    private func victoryBattleViewModel(for session: GameSessionViewModel) -> BattleViewModel {
        BattleViewModel(
            state: BattleState(actors: session.party + [testEnemy(health: 0)]),
            skills: [],
            inventory: session.inventory
        )
    }

    private func defeatBattleViewModel(for session: GameSessionViewModel) -> BattleViewModel {
        let defeatedParty = session.party.map { actor in
            var defeated = actor
            defeated.stats.health = 0
            return defeated
        }
        return BattleViewModel(
            state: BattleState(actors: defeatedParty + [testEnemy(health: 12)]),
            skills: [],
            inventory: session.inventory
        )
    }

    private func testEnemy(health: Int) -> Actor {
        Actor(
            id: "encounter_test_enemy",
            displayName: "测试敌人",
            kind: .humanEnemy,
            faction: .hostile,
            level: 1,
            stats: Stats(
                maxHealth: 12,
                health: health,
                attack: 4,
                defense: 1,
                evasion: 0,
                magic: 0,
                maxActionPoints: 4,
                actionPoints: 4
            ),
            skillIDs: []
        )
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
    private(set) var fadeRequests: [(volume: Float, duration: TimeInterval)] = []

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

    func setVolume(_ volume: Float, fadeDuration: TimeInterval) {
        fadeRequests.append((volume: volume, duration: fadeDuration))
        self.volume = volume
    }
}
