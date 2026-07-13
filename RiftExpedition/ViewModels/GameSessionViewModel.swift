import CoreGraphics
import Foundation
import Observation
import RiftCore

/// Player-owned data shared by every screen. Views may keep selection state, never another copy of this data.
@MainActor
@Observable
final class GameSessionState {
    var party: [Actor]
    var inventory: PartyInventory
    var questState: QuestState
    var collectedMapItemKeys: Set<String>
    var firedMapTriggerKeys: Set<String>
    var resolvedEncounterKeys: Set<String>

    init(
        party: [Actor] = [],
        inventory: PartyInventory = PartyInventory(),
        questState: QuestState = QuestState(),
        collectedMapItemKeys: Set<String> = [],
        firedMapTriggerKeys: Set<String> = [],
        resolvedEncounterKeys: Set<String> = []
    ) {
        self.party = party
        self.inventory = inventory
        self.questState = questState
        self.collectedMapItemKeys = collectedMapItemKeys
        self.firedMapTriggerKeys = firedMapTriggerKeys
        self.resolvedEncounterKeys = resolvedEncounterKeys
    }
}


typealias SessionMapMetadataLoading = @MainActor (String, Bundle) throws -> TiledMapMetadata

struct SessionDisplayMetadata: Equatable {
    var areaNamesByID: [String: String]
    var npcNamesByID: [String: String]
}

enum SessionMetadataError: Error, Equatable, CustomStringConvertible {
    case missingResource(String)
    case duplicateID(kind: String, id: String)
    case missingSpawn(areaID: String, spawnID: String)

    var description: String {
        switch self {
        case let .missingResource(path):
            "缺少资源：\(path)"
        case let .duplicateID(kind, id):
            "重复的\(kind) ID：\(id)"
        case let .missingSpawn(areaID, spawnID):
            "地图 \(areaID) 缺少出生点 \(spawnID)"
        }
    }
}


enum SaveWorldStateValidationError: Error, Equatable, CustomStringConvertible {
    case malformedKey(field: String, key: String)
    case unknownArea(field: String, areaID: String)
    case missingObject(field: String, key: String)

    var description: String {
        switch self {
        case let .malformedKey(field, key):
            return "存档字段 \(field) 包含无效世界状态键：\(key)"
        case let .unknownArea(field, areaID):
            return "存档字段 \(field) 引用了章节外区域：\(areaID)"
        case let .missingObject(field, key):
            return "存档字段 \(field) 引用了不存在或类型不匹配的地图对象：\(key)"
        }
    }
}

private struct SessionAreaDisplayDocument: Decodable {
    var areas: [SessionDisplayRecord]
}

private struct SessionDisplayRecord: Decodable {
    var id: String
    var displayName: String
}


private struct PreparedSessionMap {
    var areaID: String
    var spawnID: String
    var metadata: TiledMapMetadata
    var spawnPosition: CGPoint
    var encounterTriggerService: EncounterTriggerService
}

struct ExplorationWorldPresentation: Equatable {
    var areaID: String
    var hiddenItemTiledIDs: Set<Int>
    var hiddenTriggerTiledIDs: Set<Int>
    var hiddenEncounterTiledIDs: Set<Int>

    func shows(item: MapItem) -> Bool {
        !hiddenItemTiledIDs.contains(item.tiledID)
    }

    func shows(trigger: MapTrigger) -> Bool {
        !hiddenTriggerTiledIDs.contains(trigger.tiledID)
    }

    func shows(encounter: MapEncounterTrigger) -> Bool {
        !hiddenEncounterTiledIDs.contains(encounter.tiledID)
    }
}

@MainActor
@Observable
final class GameSessionViewModel {
    var appState: AppState = .mainMenu
    var statusText = "裂隙正在沉睡。"
    var contentLoadErrorMessage: String?
    var lastWorldClick: CGPoint?
    var currentAreaID = "village_square"
    var currentSpawnID = "start"
    let session = GameSessionState()
    var party: [Actor] {
        get { session.party }
        set { session.party = newValue }
    }
    var inventory: PartyInventory {
        get { session.inventory }
        set { session.inventory = newValue }
    }
    var explorationController = ExplorationController()
    var battleViewModel: BattleViewModel?
    var battleState: BattleState? {
        battleViewModel?.state
    }
    var inventoryViewModel: InventoryViewModel?
    var inventoryTab: InventoryTab = .equipment
    var saveLoadViewModel: SaveLoadViewModel?
    let audioService: AudioService
    var uiScale = 1.0
    var isDebugOverlayVisible = false
    private var encounterTriggerService: EncounterTriggerService?
    private var activeEncounterKey: String?
    private let encounterDefinitions: [EncounterDefinition]
    private let contentCatalog: ContentCatalog
    private let skillDefinitions: [SkillDefinition]
    private let itemDefinitions: [ItemDefinition]
    private let questDefinitions: [QuestDefinition]
    private let areaNamesByID: [String: String]
    private let npcNamesByID: [String: String]
    private var currentMapMetadata: TiledMapMetadata?
    private let saveGameStore: SaveGameStore
    private let contentBundle: Bundle
    private let mapMetadataLoader: SessionMapMetadataLoading
    let partyCreationViewModel: PartyCreationViewModel
    let dialogViewModel: DialogViewModel

    init(
        contentBundle: Bundle = .main,
        saveGameStore: SaveGameStore = SaveGameStore(),
        audioService: AudioService = AudioService(),
        mapMetadataLoader: @escaping SessionMapMetadataLoading = { areaID, bundle in
            try TiledMapLoader.loadMetadata(areaID: areaID, bundle: bundle)
        },
        displayMetadataLoader: (Bundle) throws -> SessionDisplayMetadata = { bundle in
            try GameSessionViewModel.loadDisplayMetadata(from: bundle)
        }
    ) {
        self.contentBundle = contentBundle
        self.saveGameStore = saveGameStore
        self.audioService = audioService
        self.mapMetadataLoader = mapMetadataLoader

        let catalog: ContentCatalog
        let loadedEncounters: [EncounterDefinition]
        let displayMetadata: SessionDisplayMetadata
        var startupErrorMessage: String?
        do {
            catalog = try Self.loadCatalog(from: contentBundle)
            loadedEncounters = try EncounterTriggerService.loadDefinitions(from: contentBundle)
            displayMetadata = try displayMetadataLoader(contentBundle)
        } catch {
            catalog = .empty
            loadedEncounters = []
            displayMetadata = SessionDisplayMetadata(areaNamesByID: [:], npcNamesByID: [:])
            startupErrorMessage = "内容加载失败：\(error)"
        }

        let startAreaID = "village_square"
        let startMetadata: TiledMapMetadata?
        if startupErrorMessage == nil {
            do {
                let metadata = try mapMetadataLoader(startAreaID, contentBundle)
                guard metadata.spawns.contains(where: { $0.id == "start" }) else {
                    throw SessionMetadataError.missingSpawn(areaID: startAreaID, spawnID: "start")
                }
                startMetadata = metadata
            } catch {
                startMetadata = nil
                startupErrorMessage = "地图加载失败：\(error)"
            }
        } else {
            startMetadata = nil
        }

        encounterDefinitions = loadedEncounters
        contentCatalog = catalog
        skillDefinitions = catalog.skills
        itemDefinitions = catalog.items
        let loadedQuestDefinitions = catalog.quests
        questDefinitions = loadedQuestDefinitions
        areaNamesByID = displayMetadata.areaNamesByID
        npcNamesByID = displayMetadata.npcNamesByID
        currentMapMetadata = startMetadata
        partyCreationViewModel = Self.makePartyCreation(from: catalog)
        dialogViewModel = DialogViewModel(
            scripts: catalog.dialogues,
            questDefinitions: loadedQuestDefinitions,
            session: session
        )
        contentLoadErrorMessage = startupErrorMessage
    }

#if DEBUG
    func configureDebugScreen(named name: String?) {
        let screen = name?.lowercased() ?? "mainmenu"
        guard screen != "mainmenu" else { return }

        if screen == "party" {
            appState = .partyCreation
            return
        }

        let demoParty = partyCreationViewModel.availableClasses.prefix(2).map(\.id)
        for classID in demoParty {
            partyCreationViewModel.toggleSelection(classID)
        }
        party = partyCreationViewModel.createParty()
        inventory = Self.makeStartingInventory(for: party)
        for item in itemDefinitions.prefix(12) {
            inventory.addItem(id: item.id)
        }
        session.questState = QuestState(statuses: Dictionary(
            uniqueKeysWithValues: questDefinitions.prefix(2).map { ($0.id, QuestStatus.active) }
        ))
        guard loadArea("village_square", spawnID: "start") else { return }
        inventoryViewModel = InventoryViewModel(
            session: session,
            itemDefinitions: itemDefinitions,
            skillDefinitions: skillDefinitions
        )

        switch screen {
        case "exploration":
            appState = .exploration
            statusText = "调试预览：探索界面。"
        case "inventory":
            inventoryTab = .equipment
            appState = .inventory
        case "skills":
            inventoryTab = .skills
            appState = .inventory
        case "quests":
            appState = .questLog
        case "save":
            openSaveLoad()
        default:
            appState = .mainMenu
        }
    }
#endif

    func startNewGame() {
        guard contentLoadErrorMessage == nil else {
            statusText = contentLoadErrorMessage ?? "内容加载失败。"
            return
        }
        audioService.play(.uiClick)
        appState = .partyCreation
        statusText = "选择两名冒险者后进入第一章。"
    }

    func enterExploration() {
        audioService.playExplorationSoundscape(for: currentAreaID)
        appState = .exploration
        statusText = "点击地图移动队长。"
    }

    func startChapterWithSelectedParty() {
        guard contentLoadErrorMessage == nil else {
            statusText = contentLoadErrorMessage ?? "内容加载失败。"
            return
        }
        let createdParty = partyCreationViewModel.createParty()
        guard createdParty.count == 2 else {
            statusText = "请选择两名不同职业。"
            return
        }

        let preparedMap: PreparedSessionMap
        do {
            preparedMap = try prepareMap(areaID: "village_square", spawnID: "start")
        } catch {
            statusText = "地图加载失败：\(error)"
            return
        }

        party = createdParty
        inventory = Self.makeStartingInventory(for: createdParty)
        session.questState = QuestState()
        session.collectedMapItemKeys = []
        session.firedMapTriggerKeys = []
        session.resolvedEncounterKeys = []
        activeEncounterKey = nil
        commitMap(preparedMap)
        inventoryViewModel = InventoryViewModel(
            session: session,
            itemDefinitions: itemDefinitions,
            skillDefinitions: skillDefinitions
        )
        enterExploration()
        performSafeAutosave()
    }

    func openSaveLoad() {
        audioService.play(.uiClick)
        if saveLoadViewModel == nil {
            saveLoadViewModel = SaveLoadViewModel(
                store: saveGameStore,
                makeSave: { [weak self] in self?.makeCurrentSave() },
                applySave: { [weak self] save in
                    guard let self else { return .rejected("游戏会话不可用。") }
                    return self.apply(save)
                },
                areaDisplayName: { [weak self] areaID in self?.areaDisplayName(for: areaID) ?? areaID }
            )
        } else {
            saveLoadViewModel?.refresh()
        }
        appState = .saveLoad
        statusText = "手动存档与自动存档将在此管理。"
    }

    func openDialog(_ dialogID: String) {
        audioService.play(.uiClick)
        if dialogViewModel.start(dialogID: dialogID) {
            appState = .dialogue
        } else {
            statusText = "没有找到对话。"
        }
    }

    func openQuestLog() {
        audioService.play(.uiClick)
        appState = .questLog
    }

    func openInventory() {
        audioService.play(.uiClick)
        appState = .inventory
    }

    func openSettings() {
        audioService.play(.uiClick)
        appState = .settings
    }

    func toggleDebugOverlay() {
        isDebugOverlayVisible.toggle()
    }

    func closePanel() {
        appState = party.isEmpty ? .mainMenu : .exploration
    }

    func beginBattleFromDialog(encounterID: String) {
        guard let encounter = encounterDefinitions.first(where: { $0.id == encounterID }) else {
            statusText = "没有找到遭遇。"
            return
        }
        _ = startBattle(encounter, trigger: nil)
    }

    @discardableResult
    func completeQuest(questID: String) -> Bool {
        guard let quest = questDefinitions.first(where: { $0.id == questID }) else {
            statusText = "没有找到任务配置。"
            dialogViewModel.message = statusText
            return false
        }

        let completedQuestState: QuestState
        do {
            completedQuestState = try QuestEngine.complete(
                questID: questID,
                in: session.questState,
                definitions: questDefinitions
            )
        } catch {
            statusText = "任务状态不满足。"
            dialogViewModel.message = statusText
            return false
        }

        let requiredCounts = Dictionary(grouping: quest.requiredItemIDs, by: { $0 }).mapValues(\.count)
        for (itemID, requiredCount) in requiredCounts where inventory.count(of: itemID) < requiredCount {
            statusText = "缺少任务物品：\(itemName(itemID)) ×\(requiredCount)。"
            dialogViewModel.message = statusText
            return false
        }

        var updatedInventory = inventory
        do {
            for (itemID, requiredCount) in requiredCounts {
                try updatedInventory.removeItem(id: itemID, quantity: requiredCount)
            }
        } catch {
            statusText = "任务物品扣除失败；任务状态未改变。"
            dialogViewModel.message = statusText
            return false
        }
        for itemID in quest.rewardItemIDs {
            updatedInventory.addItem(id: itemID)
        }
        let rewardedParty = learnSkills(quest.rewardSkillIDs, for: party)

        session.questState = completedQuestState
        inventory = updatedInventory
        party = rewardedParty

        let rewardNames = (quest.rewardItemIDs.map(itemName) + quest.rewardSkillIDs.map(skillName)).joined(separator: "、")
        audioService.play(.questComplete)
        statusText = rewardNames.isEmpty ? "任务已完成。" : "任务完成，获得：\(rewardNames)。"
        dialogViewModel.message = statusText
        if questID == "blood_debt" {
            completeChapter()
        }
        return true
    }

    func completeChapter() {
        let didAutosave = performSafeAutosave()
        audioService.stopSoundscape()
        audioService.play(.chapterComplete)
        battleViewModel = nil
        appState = .chapterComplete
        statusText = didAutosave
            ? "第一章完成：村长的谎言已经被揭穿。"
            : "第一章完成，但自动存档失败；已保留上一个安全存档。"
    }

    func finishBattle() {
        guard let battleViewModel else { return }
        switch battleViewModel.state.outcome {
        case .victory:
            if let activeEncounterKey {
                session.resolvedEncounterKeys.insert(activeEncounterKey)
            }
            activeEncounterKey = nil
            let survivingParty = battleViewModel.state.actors
                .filter { $0.faction == .player }
                .map { actor in
                    var revived = actor
                    if revived.stats.health <= 0 {
                        revived.stats.health = max(1, revived.stats.maxHealth / 2)
                    }
                    return revived
            }
            party = survivingParty
            inventory = battleViewModel.inventory
            let didAutosave = performSafeAutosave()
            audioService.play(.battleVictory)
            self.battleViewModel = nil
            appState = .exploration
            audioService.playExplorationSoundscape(for: currentAreaID)
            statusText = didAutosave
                ? "战斗胜利。倒下的队友已在战后复活。"
                : "战斗胜利，倒下的队友已复活；自动存档失败，已保留上一个安全存档。"
        case .defeat:
            activeEncounterKey = nil
            recoverFromLatestAutosave()
        case .ongoing:
            statusText = "战斗尚未结束。"
        }
    }

    func returnToMainMenu() {
        audioService.stopSoundscape()
        appState = .mainMenu
        statusText = "裂隙正在沉睡。"
        lastWorldClick = nil
        battleViewModel = nil
        inventoryViewModel = nil
        saveLoadViewModel = nil
        session.questState = QuestState()
        session.collectedMapItemKeys = []
        session.firedMapTriggerKeys = []
        session.resolvedEncounterKeys = []
        activeEncounterKey = nil
    }

    @discardableResult
    private func startBattle(_ encounter: EncounterDefinition, trigger: MapEncounterTrigger?) -> Bool {
        let battleActors = party + encounter.enemies
        if let duplicateActorID = Self.firstDuplicateID(in: battleActors.map(\.id)) {
            activeEncounterKey = nil
            statusText = "遭遇数据错误：角色 ID 重复（\(duplicateActorID)）。"
            return false
        }

        activeEncounterKey = trigger.map(encounterKey)
        audioService.play(.battleStart)
        audioService.playBattleSoundscape(for: currentAreaID)
        battleViewModel = BattleViewModel(
            state: BattleState(actors: battleActors),
            skills: skillDefinitions,
            inventory: inventory,
            itemDefinitions: itemDefinitions,
            initialPositions: battleInitialPositions(for: encounter, trigger: trigger),
            surfaces: battleSurfaces(),
            hasLineOfSight: battleLineOfSight,
            isMovementAllowed: battleMovementAllowed,
            onAudioCue: { [weak self] cue in self?.audioService.play(cue) }
        )
        appState = .battle
        statusText = "遭遇已触发。"
        return true
    }

    private func makeCurrentSave() -> SaveGame? {
        guard !party.isEmpty else { return nil }

        return SaveGame(
            currentAreaID: currentAreaID,
            currentSpawnID: currentSpawnID,
            party: party,
            inventory: inventory,
            questState: session.questState,
            collectedMapItemKeys: session.collectedMapItemKeys.sorted(),
            firedMapTriggerKeys: session.firedMapTriggerKeys.sorted(),
            resolvedEncounterKeys: session.resolvedEncounterKeys.sorted()
        )
    }

    @discardableResult
    private func apply(_ save: SaveGame) -> SaveApplicationResult {
        do {
            try SaveContentValidator.validate(save, against: contentCatalog)
            try validateWorldState(in: save)
        } catch {
            let reason = "存档内容与当前版本不兼容：\(error)"
            statusText = reason
            return .rejected(reason)
        }

        let preparedMap: PreparedSessionMap
        do {
            preparedMap = try prepareMap(areaID: save.currentAreaID, spawnID: save.currentSpawnID)
        } catch {
            let reason = "存档地图加载失败：\(error)"
            statusText = reason
            return .rejected(reason)
        }

        party = save.party
        inventory = save.inventory
        session.questState = save.questState
        session.collectedMapItemKeys = Set(save.collectedMapItemKeys)
        session.firedMapTriggerKeys = Set(save.firedMapTriggerKeys)
        session.resolvedEncounterKeys = Set(save.resolvedEncounterKeys)
        activeEncounterKey = nil
        if inventoryViewModel == nil {
            inventoryViewModel = InventoryViewModel(
                session: session,
                itemDefinitions: itemDefinitions,
                skillDefinitions: skillDefinitions
            )
        }
        commitMap(preparedMap)
        battleViewModel = nil
        appState = .exploration
        audioService.playExplorationSoundscape(for: currentAreaID)
        statusText = "已读取存档。"
        return .applied
    }

    @discardableResult
    private func performSafeAutosave() -> Bool {
        guard let save = makeCurrentSave() else { return false }
        do {
            try saveGameStore.write(save, to: saveGameStore.nextAutosaveSlot(), safety: .safe)
            saveLoadViewModel?.refresh()
            return true
        } catch {
            GameLog.save.error("安全自动存档失败")
            statusText = "自动存档失败；已保留上一个安全存档。"
            return false
        }
    }

    private func recoverFromLatestAutosave() {
        battleViewModel = nil
        let recoveries = saveGameStore.readableAutosavesNewestFirst()
        guard !recoveries.isEmpty else {
            returnToMainMenu()
            statusText = "全队倒下，但没有可用自动存档；已返回主菜单。"
            return
        }

        var lastRejectionReason: String?
        for recovery in recoveries {
            switch apply(recovery.save) {
            case .applied:
                saveLoadViewModel?.refresh()
                statusText = "全队倒下，已读取自动槽 \(recovery.slot.index) 的安全自动存档。"
                return
            case let .rejected(reason):
                lastRejectionReason = reason
            }
        }

        returnToMainMenu()
        let detail = lastRejectionReason.map { "：\($0)" } ?? ""
        statusText = "所有自动存档均无法恢复\(detail)；已返回主菜单。"
    }

    private static func firstDuplicateID(in ids: [String]) -> String? {
        var seen: Set<String> = []
        return ids.first { !seen.insert($0).inserted }
    }

    private static func loadCatalog(from bundle: Bundle) throws -> ContentCatalog {
        guard let dataDirectory = bundle.resourceURL?.appending(path: "Data") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try ContentLoader.load(from: dataDirectory)
    }

    private static func makePartyCreation(from catalog: ContentCatalog) -> PartyCreationViewModel {
        let skillNames: [String: String] = Dictionary(uniqueKeysWithValues: catalog.skills.map { ($0.id, $0.displayName) })
        return PartyCreationViewModel(classes: catalog.classes, skillNamesByID: skillNames)
    }

    static func loadDisplayMetadata(from bundle: Bundle) throws -> SessionDisplayMetadata {
        guard let areasURL = bundle.url(
            forResource: "chapter1",
            withExtension: "json",
            subdirectory: "Data/worlds"
        ) else {
            throw SessionMetadataError.missingResource("Data/worlds/chapter1.json")
        }
        guard let npcsURL = bundle.url(
            forResource: "npcs",
            withExtension: "json",
            subdirectory: "Data"
        ) else {
            throw SessionMetadataError.missingResource("Data/npcs.json")
        }

        let decoder = JSONDecoder()
        let areaDocument = try decoder.decode(
            SessionAreaDisplayDocument.self,
            from: Data(contentsOf: areasURL)
        )
        let npcs = try decoder.decode(
            [SessionDisplayRecord].self,
            from: Data(contentsOf: npcsURL)
        )
        return SessionDisplayMetadata(
            areaNamesByID: try uniqueDisplayNames(areaDocument.areas, kind: "区域"),
            npcNamesByID: try uniqueDisplayNames(npcs, kind: "NPC")
        )
    }

    private static func uniqueDisplayNames(
        _ records: [SessionDisplayRecord],
        kind: String
    ) throws -> [String: String] {
        var result: [String: String] = [:]
        for record in records {
            guard result[record.id] == nil else {
                throw SessionMetadataError.duplicateID(kind: kind, id: record.id)
            }
            result[record.id] = record.displayName
        }
        return result
    }

    private static func makeStartingInventory(for party: [Actor]) -> PartyInventory {
        var inventory = PartyInventory()
        for actor in party {
            let equippedItemIDs = [actor.equipment.weaponID, actor.equipment.armorID, actor.equipment.accessoryID]
            for itemID in equippedItemIDs.compactMap({ $0 }) {
                inventory.addItem(id: itemID)
            }
        }
        inventory.addItem(id: "minor_healing_draught", quantity: 2)
        return inventory
    }

    private func learnSkills(_ skillIDs: [String], for party: [Actor]) -> [Actor] {
        party.map { actor in
            var next = actor
            for skillID in skillIDs where !next.skillIDs.contains(skillID) {
                next.skillIDs.append(skillID)
            }
            return next
        }
    }

    private func itemName(_ itemID: String) -> String {
        itemDefinitions.first(where: { $0.id == itemID })?.displayName ?? itemID
    }

    private func hasTurnInItems(for questID: String) -> Bool {
        guard let quest = questDefinitions.first(where: { $0.id == questID }) else { return false }
        let requiredCounts = Dictionary(grouping: quest.requiredItemIDs, by: { $0 }).mapValues(\.count)
        return requiredCounts.allSatisfy { itemID, requiredCount in
            inventory.count(of: itemID) >= requiredCount
        }
    }

    private func skillName(_ skillID: String) -> String {
        skillDefinitions.first(where: { $0.id == skillID })?.displayName ?? skillID
    }

    private func areaDisplayName(for areaID: String) -> String {
        areaNamesByID[areaID] ?? areaID
    }

    private func npcDisplayName(for npc: MapNPC) -> String {
        npcNamesByID[npc.actorID] ?? "角色"
    }

    private func triggerDisplayName(for trigger: MapTrigger) -> String {
        if trigger.action == "chapterComplete" {
            return "裂隙出口"
        }
        if dialogID(fromTriggerAction: trigger.action) != nil {
            return "线索"
        }
        return "触发点"
    }

    var debugObstacleCount: Int {
        currentMapMetadata?.navObstacles.count ?? 0
    }

    var debugEncounterTriggerCount: Int {
        currentMapMetadata?.encounterTriggers.count ?? 0
    }

    var currentAreaDisplayName: String {
        areaDisplayName(for: currentAreaID)
    }

    var explorationWorldPresentation: ExplorationWorldPresentation {
        ExplorationWorldPresentation(
            areaID: currentAreaID,
            hiddenItemTiledIDs: tiledIDs(in: session.collectedMapItemKeys, areaID: currentAreaID),
            hiddenTriggerTiledIDs: tiledIDs(in: session.firedMapTriggerKeys, areaID: currentAreaID),
            hiddenEncounterTiledIDs: tiledIDs(in: session.resolvedEncounterKeys, areaID: currentAreaID)
        )
    }

    private func validateWorldState(in save: SaveGame) throws {
        enum ExpectedObjectKind {
            case item
            case trigger
            case encounter
        }

        let fields: [(name: String, keys: [String], kind: ExpectedObjectKind)] = [
            ("collectedMapItemKeys", save.collectedMapItemKeys, .item),
            ("firedMapTriggerKeys", save.firedMapTriggerKeys, .trigger),
            ("resolvedEncounterKeys", save.resolvedEncounterKeys, .encounter)
        ]
        let chapterAreaIDs = Set(areaNamesByID.keys)
        var metadataByAreaID: [String: TiledMapMetadata] = [:]

        for field in fields {
            for key in field.keys {
                let parts = key.split(separator: ":", omittingEmptySubsequences: false)
                guard parts.count == 2, let tiledID = Int(parts[1]), tiledID > 0 else {
                    throw SaveWorldStateValidationError.malformedKey(field: field.name, key: key)
                }
                let areaID = String(parts[0])
                guard chapterAreaIDs.contains(areaID) else {
                    throw SaveWorldStateValidationError.unknownArea(field: field.name, areaID: areaID)
                }

                let metadata: TiledMapMetadata
                if let cached = metadataByAreaID[areaID] {
                    metadata = cached
                } else {
                    metadata = try mapMetadataLoader(areaID, contentBundle)
                    metadataByAreaID[areaID] = metadata
                }

                let exists: Bool
                switch field.kind {
                case .item:
                    exists = metadata.items.contains { $0.tiledID == tiledID }
                case .trigger:
                    exists = metadata.triggers.contains { $0.tiledID == tiledID }
                case .encounter:
                    exists = metadata.encounterTriggers.contains { $0.tiledID == tiledID }
                }
                guard exists else {
                    throw SaveWorldStateValidationError.missingObject(field: field.name, key: key)
                }
            }
        }
    }

    private func prepareMap(areaID: String, spawnID: String) throws -> PreparedSessionMap {
        let metadata = try mapMetadataLoader(areaID, contentBundle)
        guard let spawn = metadata.spawns.first(where: { $0.id == spawnID }) else {
            throw SessionMetadataError.missingSpawn(areaID: areaID, spawnID: spawnID)
        }
        let triggerService = try EncounterTriggerService(
            triggers: metadata.encounterTriggers,
            encounters: encounterDefinitions,
            triggeredTiledIDs: resolvedEncounterTiledIDs(in: areaID)
        )
        return PreparedSessionMap(
            areaID: areaID,
            spawnID: spawnID,
            metadata: metadata,
            spawnPosition: spawn.position,
            encounterTriggerService: triggerService
        )
    }

    private func commitMap(_ prepared: PreparedSessionMap) {
        currentAreaID = prepared.areaID
        currentSpawnID = prepared.spawnID
        currentMapMetadata = prepared.metadata
        encounterTriggerService = prepared.encounterTriggerService
        if appState == .exploration {
            audioService.playExplorationSoundscape(for: prepared.areaID)
        }
        explorationController.setObstacles(movementObstacles(for: prepared.metadata))
        if !party.isEmpty {
            explorationController.configureParty(party, at: prepared.spawnPosition)
        }
    }

    @discardableResult
    private func loadArea(_ areaID: String, spawnID: String) -> Bool {
        do {
            commitMap(try prepareMap(areaID: areaID, spawnID: spawnID))
            return true
        } catch {
            statusText = "地图加载失败：\(error)"
            return false
        }
    }

    /// NPC 在地图上是站定不动的实体，但之前完全没有任何碰撞体积，队伍可以直接站到 NPC 身上、
    /// 和 NPC 完全重叠。这里给每个 NPC 站位补一个小的方形碰撞区（和 navObstacle 一样处理），
    /// 让角色/NPC 之间也有基本的“不能互相穿过”的效果。
    private func movementObstacles(for metadata: TiledMapMetadata?) -> [NavigationObstacle] {
        guard let metadata else { return [] }

        let npcBlockers = metadata.npcs.map { npc in
            // 碰撞箱大小直接用地图作者在 Tiled 里给这个 npc 对象画的宽高（数据驱动，改地图不用改代码）。
            // RiftValidator 在启动/发布校验时会强制要求每个 npc 对象都有非零宽高，
            // 所以这里不再需要兜底默认值。
            NavigationObstacle(
                tiledID: -(1000 + npc.tiledID),
                name: "npc_\(npc.actorID)",
                frame: npc.frame,
                blocksMovement: true,
                blocksSight: false
            )
        }
        return metadata.navObstacles + npcBlockers
    }

    private func battleInitialPositions(for encounter: EncounterDefinition, trigger: MapEncounterTrigger?) -> [String: CGPoint] {
        var positions: [String: CGPoint] = [:]
        for member in explorationController.members {
            positions[member.actorID] = member.position
        }

        let center = trigger?.center ?? CGPoint(x: 560, y: 320)
        let enemyOffsets = [
            CGPoint(x: 34, y: -22),
            CGPoint(x: 92, y: 42),
            CGPoint(x: 120, y: -64),
            CGPoint(x: 170, y: 18)
        ]
        for (index, enemy) in encounter.enemies.enumerated() {
            let offset = enemyOffsets[index % enemyOffsets.count]
            positions[enemy.id] = CGPoint(x: center.x + offset.x, y: center.y + offset.y)
        }
        return positions
    }

    private func battleSurfaces() -> [BattleSurfaceMarker] {
        currentMapMetadata?.surfaces.map { surface in
            BattleSurfaceMarker(
                id: "surface_\(surface.tiledID)",
                frame: surface.frame,
                surfaceType: surface.surfaceType
            )
        } ?? []
    }

    private func battleLineOfSight(from start: CGPoint, to end: CGPoint) -> Bool {
        LineOfSightService(obstacles: currentMapMetadata?.navObstacles ?? [])
            .hasLineOfSight(from: start, to: end)
    }

    private func battleMovementAllowed(from start: CGPoint, to end: CGPoint) -> Bool {
        guard let metadata = currentMapMetadata else { return false }
        let playableFrame = metadata.mapFrame.insetBy(dx: 12, dy: 12)
        guard playableFrame.contains(end) else { return false }

        return !movementObstacles(for: metadata)
            .filter(\.blocksMovement)
            .contains { obstacle in
                obstacle.frame.insetBy(dx: -10, dy: -10).intersectsSegment(from: start, to: end)
            }
    }

    private func interactWithNPC(at point: CGPoint) -> Bool {
        guard let npc = nearestNPC(to: point) else { return false }

        if isLeaderNear(npc.position, radius: 96) {
            openDialog(dialogID(for: npc))
        } else {
            explorationController.setLeaderDestination(npc.position)
            statusText = "队长正靠近 \(npcDisplayName(for: npc))。"
        }
        return true
    }

    private func collectItem(at point: CGPoint) -> Bool {
        guard let item = nearestItem(to: point) else { return false }

        let key = mapItemKey(item)
        guard !session.collectedMapItemKeys.contains(key) else {
            statusText = "这里已经搜刮过了。"
            return true
        }

        if isLeaderNear(item.position, radius: 96) {
            inventory.addItem(id: item.itemID)
            session.collectedMapItemKeys.insert(key)
            audioService.play(.chestOpen)
            statusText = "拾取了 \(itemName(item.itemID))。"
        } else {
            explorationController.setLeaderDestination(item.position)
            statusText = "队长正靠近 \(itemName(item.itemID))。"
        }
        return true
    }

    private func interactWithTrigger(at point: CGPoint) -> Bool {
        guard let trigger = nearestTrigger(to: point) else { return false }

        if isLeaderNear(trigger.frame.center, radius: 96) {
            perform(trigger)
        } else {
            explorationController.setLeaderDestination(trigger.frame.center)
            statusText = "队长正靠近 \(triggerDisplayName(for: trigger))。"
        }
        return true
    }

    private func nearestNPC(to point: CGPoint) -> MapNPC? {
        currentMapMetadata?.npcs
            .filter { distance(from: $0.position, to: point) <= 38 }
            .min { distance(from: $0.position, to: point) < distance(from: $1.position, to: point) }
    }

    private func nearestItem(to point: CGPoint) -> MapItem? {
        currentMapMetadata?.items
            .filter { distance(from: $0.position, to: point) <= 38 }
            .min { distance(from: $0.position, to: point) < distance(from: $1.position, to: point) }
    }

    private func nearestTrigger(to point: CGPoint) -> MapTrigger? {
        currentMapMetadata?.triggers.first { trigger in
            trigger.contains(point) || distance(from: trigger.frame.center, to: point) <= 38
        }
    }

    private func dialogID(for npc: MapNPC) -> String {
        switch npc.actorID {
        case "healer" where dialogViewModel.questState.statuses["bitterroot_medicine"] == .active && hasTurnInItems(for: "bitterroot_medicine"):
            return "healer_return"
        case "fiance" where dialogViewModel.questState.statuses["scorched_vow"] == .active && hasTurnInItems(for: "scorched_vow"):
            return "fiance_ring_return"
        case "fiance" where dialogViewModel.questState.statuses["blood_debt"] == .active && dialogViewModel.questState.statuses["scorched_vow"] == nil:
            return "fiance_ring_request"
        case "gate_guard" where dialogViewModel.questState.statuses["miners_last_shift"] == .active && hasTurnInItems(for: "miners_last_shift"):
            return "guard_gauntlets_return"
        case "gate_guard" where dialogViewModel.questState.statuses["blood_debt"] == .active && dialogViewModel.questState.statuses["miners_last_shift"] == nil:
            return "guard_gauntlets_request"
        case "mayor" where dialogViewModel.questState.statuses["blood_debt"] == .active && hasTurnInItems(for: "blood_debt"):
            return "elder_return"
        default:
            return npc.dialogID
        }
    }

    private func isLeaderNear(_ position: CGPoint, radius: CGFloat) -> Bool {
        guard let leaderPosition else { return false }
        return distance(from: leaderPosition, to: position) <= radius
    }

    private var leaderPosition: CGPoint? {
        explorationController.members.first(where: { $0.actorID == explorationController.leaderID })?.position
    }

    private func mapItemKey(_ item: MapItem) -> String {
        "\(currentAreaID):\(item.tiledID)"
    }

    private func mapTriggerKey(_ trigger: MapTrigger) -> String {
        "\(currentAreaID):\(trigger.tiledID)"
    }

    private func encounterKey(_ trigger: MapEncounterTrigger) -> String {
        "\(currentAreaID):\(trigger.tiledID)"
    }

    private func resolvedEncounterTiledIDs(in areaID: String) -> Set<Int> {
        tiledIDs(in: session.resolvedEncounterKeys, areaID: areaID)
    }

    private func tiledIDs(in keys: Set<String>, areaID: String) -> Set<Int> {
        let prefix = "\(areaID):"
        return Set(keys.compactMap { key in
            guard key.hasPrefix(prefix), let tiledID = Int(key.dropFirst(prefix.count)) else {
                return nil
            }
            return tiledID
        })
    }

    private func perform(_ trigger: MapTrigger) {
        let key = mapTriggerKey(trigger)
        guard !session.firedMapTriggerKeys.contains(key) else { return }

        session.firedMapTriggerKeys.insert(key)
        if let dialogID = dialogID(fromTriggerAction: trigger.action) {
            openDialog(dialogID)
        } else if trigger.action == "chapterComplete" {
            completeChapter()
        } else {
            statusText = "未知地图触发。"
        }
    }

    private func dialogID(fromTriggerAction action: String) -> String? {
        let prefix = "dialogue:"
        guard action.hasPrefix(prefix) else { return nil }
        return String(action.dropFirst(prefix.count))
    }

    private func distance(from start: CGPoint, to end: CGPoint) -> CGFloat {
        hypot(start.x - end.x, start.y - end.y)
    }
}

extension GameSessionViewModel: GameSceneEventHandling {
    func gameSceneDidLoad(_ scene: GameScene) {
        statusText = "区域已载入。"
    }

    func gameScene(_ scene: GameScene, didClickWorld point: CGPoint) {
        lastWorldClick = point
        if appState == .exploration {
            if interactWithNPC(at: point) || collectItem(at: point) || interactWithTrigger(at: point) {
                return
            }
            explorationController.setLeaderDestination(point)
            statusText = "队长移动到：\(Int(point.x)), \(Int(point.y))"
            checkEncounterTrigger()
        } else if appState == .battle {
            battleViewModel?.handleWorldClick(point)
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
            checkExitTransition()
            checkEncounterTrigger()
            checkMapTrigger()
        }

    private func checkExitTransition() {
        guard appState == .exploration,
              let leaderPosition = explorationController.members.first(where: { $0.actorID == explorationController.leaderID })?.position,
              let exit = currentMapMetadata?.exits.first(where: { $0.contains(leaderPosition) })
        else {
            return
        }

        if loadArea(exit.targetAreaID, spawnID: exit.targetSpawnID) {
            statusText = "进入区域：\(areaDisplayName(for: exit.targetAreaID))"
        }
    }

    private func checkEncounterTrigger() {
        guard appState == .exploration,
              let leaderPosition = explorationController.members.first(where: { $0.actorID == explorationController.leaderID })?.position,
              let pendingEncounter = encounterTriggerService?.pendingEncounter(at: leaderPosition)
        else {
            return
        }

        guard startBattle(pendingEncounter.definition, trigger: pendingEncounter.trigger) else {
            return
        }
        encounterTriggerService?.markTriggered(tiledID: pendingEncounter.trigger.tiledID)
    }

    private func checkMapTrigger() {
        guard appState == .exploration,
              let leaderPosition,
              let trigger = currentMapMetadata?.triggers.first(where: { $0.contains(leaderPosition) })
        else {
            return
        }

        perform(trigger)
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
