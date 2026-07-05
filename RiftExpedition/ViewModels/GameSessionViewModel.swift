import CoreGraphics
import Foundation
import Observation
import RiftCore

@MainActor
@Observable
final class GameSessionViewModel {
    var appState: AppState = .mainMenu
    var statusText = "裂隙正在沉睡。"
    var lastWorldClick: CGPoint?
    var party: [Actor] = []
    var explorationController = ExplorationController()
    var battleViewModel: BattleViewModel?
    var battleState: BattleState? {
        battleViewModel?.state
    }
    var inventoryViewModel: InventoryViewModel?
    var saveLoadViewModel: SaveLoadViewModel?
    let audioService: AudioService
    var uiScale = 1.0
    var isDebugOverlayVisible = false
    private var encounterTriggerService: EncounterTriggerService?
    private let encounterDefinitions: [EncounterDefinition]
    private let skillDefinitions: [SkillDefinition]
    private let itemDefinitions: [ItemDefinition]
    private let initialMapMetadata: TiledMapMetadata?
    private let saveGameStore: SaveGameStore
    let partyCreationViewModel: PartyCreationViewModel
    let dialogViewModel: DialogViewModel

    init(
        contentBundle: Bundle = .main,
        saveGameStore: SaveGameStore = SaveGameStore(),
        audioService: AudioService = AudioService()
    ) {
        self.saveGameStore = saveGameStore
        self.audioService = audioService
        let catalog = Self.loadCatalog(from: contentBundle)
        encounterDefinitions = EncounterTriggerService.loadDefinitions(from: contentBundle)
        skillDefinitions = catalog?.skills ?? []
        itemDefinitions = catalog?.items ?? []
        initialMapMetadata = try? TiledMapLoader.loadMetadata(areaID: "vertical_slice", bundle: contentBundle)
        partyCreationViewModel = Self.makePartyCreation(from: catalog)
        dialogViewModel = DialogViewModel(
            scripts: DialogViewModel.loadScripts(from: contentBundle),
            questDefinitions: catalog?.quests ?? []
        )
    }

    func startNewGame() {
        audioService.play(.click)
        appState = .partyCreation
        statusText = "选择两名冒险者后进入第一章。"
    }

    func enterExploration() {
        audioService.playAreaBGM()
        appState = .exploration
        statusText = "点击地图移动队长。"
    }

    func startChapterWithSelectedParty() {
        let createdParty = partyCreationViewModel.createParty()
        guard createdParty.count == 2 else {
            statusText = "请选择两名不同职业。"
            return
        }

        party = createdParty
        inventoryViewModel = InventoryViewModel(
            party: createdParty,
            inventory: Self.makeStartingInventory(for: createdParty),
            itemDefinitions: itemDefinitions
        )
        explorationController.configureParty(createdParty, at: CGPoint(x: 96, y: 96))
        configureEncounterTriggers()
        enterExploration()
    }

    func openSaveLoad() {
        audioService.play(.click)
        if saveLoadViewModel == nil {
            saveLoadViewModel = SaveLoadViewModel(
                store: saveGameStore,
                makeSave: { [weak self] in self?.makeCurrentSave() },
                applySave: { [weak self] save in self?.apply(save) }
            )
        } else {
            saveLoadViewModel?.refresh()
        }
        appState = .saveLoad
        statusText = "手动存档与自动存档将在此管理。"
    }

    func openDialog(_ dialogID: String) {
        audioService.play(.click)
        if dialogViewModel.start(dialogID: dialogID) {
            appState = .dialogue
        } else {
            statusText = "没有找到对话。"
        }
    }

    func openQuestLog() {
        audioService.play(.click)
        appState = .questLog
    }

    func openInventory() {
        audioService.play(.click)
        appState = .inventory
    }

    func openSettings() {
        audioService.play(.click)
        appState = .settings
    }

    func toggleDebugOverlay() {
        isDebugOverlayVisible.toggle()
    }

    func closePanel() {
        if let inventoryViewModel {
            party = inventoryViewModel.party
        }
        appState = party.isEmpty ? .mainMenu : .exploration
    }

    func beginBattleFromDialog(encounterID: String) {
        guard let encounter = encounterDefinitions.first(where: { $0.id == encounterID }) else {
            statusText = "没有找到遭遇。"
            return
        }
        startBattle(encounter)
    }

    func returnToMainMenu() {
        audioService.stopAreaBGM()
        appState = .mainMenu
        statusText = "裂隙正在沉睡。"
        lastWorldClick = nil
        battleViewModel = nil
        inventoryViewModel = nil
        saveLoadViewModel = nil
    }

    private func startBattle(_ encounter: EncounterDefinition) {
        audioService.play(.attack)
        battleViewModel = BattleViewModel(
            state: BattleState(actors: (inventoryViewModel?.party ?? party) + encounter.enemies),
            skills: skillDefinitions
        )
        appState = .battle
        statusText = "遭遇已触发。"
    }

    private func makeCurrentSave() -> SaveGame? {
        let currentParty = inventoryViewModel?.party ?? party
        guard !currentParty.isEmpty else { return nil }

        return SaveGame(
            currentAreaID: "vertical_slice",
            currentSpawnID: "start",
            party: currentParty,
            inventory: inventoryViewModel?.inventory ?? PartyInventory()
        )
    }

    private func apply(_ save: SaveGame) {
        party = save.party
        inventoryViewModel = InventoryViewModel(
            party: save.party,
            inventory: save.inventory,
            itemDefinitions: itemDefinitions
        )
        explorationController.configureParty(save.party, at: CGPoint(x: 96, y: 96))
        configureEncounterTriggers()
        battleViewModel = nil
        appState = .exploration
        statusText = "已读取存档。"
    }

    private static func loadCatalog(from bundle: Bundle) -> ContentCatalog? {
        guard let dataDirectory = bundle.resourceURL?.appending(path: "Data") else { return nil }
        return try? ContentLoader.load(from: dataDirectory)
    }

    private static func makePartyCreation(from catalog: ContentCatalog?) -> PartyCreationViewModel {
        guard let catalog else { return PartyCreationViewModel(classes: []) }
        let skillNames: [String: String] = Dictionary(uniqueKeysWithValues: catalog.skills.map { ($0.id, $0.displayName) })
        return PartyCreationViewModel(classes: catalog.classes, skillNamesByID: skillNames)
    }

    private static func makeStartingInventory(for party: [Actor]) -> PartyInventory {
        var inventory = PartyInventory()
        for actor in party {
            let equippedItemIDs = [actor.equipment.weaponID, actor.equipment.armorID, actor.equipment.accessoryID]
            for itemID in equippedItemIDs.compactMap({ $0 }) {
                inventory.addItem(id: itemID)
            }
        }
        return inventory
    }

    var debugObstacleCount: Int {
        initialMapMetadata?.navObstacles.count ?? 0
    }

    var debugEncounterTriggerCount: Int {
        initialMapMetadata?.encounterTriggers.count ?? 0
    }

    private func configureEncounterTriggers() {
        if let metadata = initialMapMetadata {
            encounterTriggerService = EncounterTriggerService(
                triggers: metadata.encounterTriggers,
                encounters: encounterDefinitions
            )
        }
    }
}

extension GameSessionViewModel: GameSceneEventHandling {
    func gameSceneDidLoad(_ scene: GameScene) {
        statusText = "区域已载入。"
    }

    func gameScene(_ scene: GameScene, didClickWorld point: CGPoint) {
        lastWorldClick = point
        if appState == .exploration {
            explorationController.setLeaderDestination(point)
            statusText = "队长移动到：\(Int(point.x)), \(Int(point.y))"
            checkEncounterTrigger()
        } else {
            statusText = "目标位置：\(Int(point.x)), \(Int(point.y))"
        }
    }

    func gameSceneDidRequestLeaderSwitch(_ scene: GameScene) {
        guard appState == .exploration else { return }

        explorationController.switchToNextLeader()
        statusText = "已切换队长。"
    }

    func gameSceneDidRequestDebugToggle(_ scene: GameScene) {
        toggleDebugOverlay()
    }

    func gameScene(_ scene: GameScene, didAdvance deltaTime: TimeInterval) {
        guard appState == .exploration else { return }

        explorationController.advance(deltaTime: deltaTime)
        checkEncounterTrigger()
    }

    private func checkEncounterTrigger() {
        guard appState == .exploration,
              let leaderPosition = explorationController.members.first(where: { $0.actorID == explorationController.leaderID })?.position,
              let encounter = encounterTriggerService?.encounter(at: leaderPosition)
        else {
            return
        }

        startBattle(encounter)
    }
}
