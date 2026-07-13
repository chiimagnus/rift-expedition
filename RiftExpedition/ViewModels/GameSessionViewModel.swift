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

@MainActor
@Observable
final class GameSessionViewModel {
    var appState: AppState = .mainMenu
    var statusText = "裂隙正在沉睡。"
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
    private let skillDefinitions: [SkillDefinition]
    private let itemDefinitions: [ItemDefinition]
    private let questDefinitions: [QuestDefinition]
    private let areaNamesByID: [String: String]
    private let npcNamesByID: [String: String]
    private var currentMapMetadata: TiledMapMetadata?
    private let saveGameStore: SaveGameStore
    private let contentBundle: Bundle
    let partyCreationViewModel: PartyCreationViewModel
    let dialogViewModel: DialogViewModel

    init(
        contentBundle: Bundle = .main,
        saveGameStore: SaveGameStore = SaveGameStore(),
        audioService: AudioService = AudioService()
    ) {
        self.contentBundle = contentBundle
        self.saveGameStore = saveGameStore
        self.audioService = audioService
        let catalog = Self.loadCatalog(from: contentBundle)
        encounterDefinitions = EncounterTriggerService.loadDefinitions(from: contentBundle)
        skillDefinitions = catalog?.skills ?? []
        itemDefinitions = catalog?.items ?? []
        let loadedQuestDefinitions = catalog?.quests ?? []
        questDefinitions = loadedQuestDefinitions
        areaNamesByID = Self.loadAreaDisplayNames(from: contentBundle)
        npcNamesByID = Self.loadNPCDisplayNames(from: contentBundle)
        let startAreaID = "village_square"
        currentMapMetadata = try? TiledMapLoader.loadMetadata(areaID: startAreaID, bundle: contentBundle)
        partyCreationViewModel = Self.makePartyCreation(from: catalog)
        dialogViewModel = DialogViewModel(
            scripts: DialogViewModel.loadScripts(from: contentBundle),
            questDefinitions: loadedQuestDefinitions,
            session: session
        )
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
        loadArea("village_square", spawnID: "start")
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
        let createdParty = partyCreationViewModel.createParty()
        guard createdParty.count == 2 else {
            statusText = "请选择两名不同职业。"
            return
        }

        party = createdParty
        inventory = Self.makeStartingInventory(for: createdParty)
        session.questState = QuestState()
        session.collectedMapItemKeys = []
        session.firedMapTriggerKeys = []
        session.resolvedEncounterKeys = []
        activeEncounterKey = nil
        loadArea("village_square", spawnID: "start")
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
                applySave: { [weak self] save in self?.apply(save) },
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
        startBattle(encounter, trigger: nil)
    }

    func applyQuestRewards(questID: String) {
        guard let quest = questDefinitions.first(where: { $0.id == questID }) else {
            statusText = "没有找到任务奖励配置。"
            return
        }

        var updatedInventory = inventory
        for itemID in questTurnInItemIDs(for: questID) {
            try? updatedInventory.removeItem(id: itemID)
        }
        for itemID in quest.rewardItemIDs {
            updatedInventory.addItem(id: itemID)
        }

        let rewardedParty = learnSkills(quest.rewardSkillIDs, for: party)
        party = rewardedParty
        inventory = updatedInventory

        let rewardNames = (quest.rewardItemIDs.map(itemName) + quest.rewardSkillIDs.map(skillName)).joined(separator: "、")
        audioService.play(.questComplete)
        statusText = rewardNames.isEmpty ? "任务已完成。" : "任务完成，获得：\(rewardNames)。"
        if questID == "blood_debt" {
            completeChapter()
        }
    }

    func completeChapter() {
        let didAutosave = performSafeAutosave()
        audioService.stopBGM()
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
        audioService.stopBGM()
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

    private func startBattle(_ encounter: EncounterDefinition, trigger: MapEncounterTrigger?) {
        activeEncounterKey = trigger.map(encounterKey)
        audioService.play(.battleStart)
        audioService.playBattleSoundscape(for: currentAreaID)
        battleViewModel = BattleViewModel(
            state: BattleState(actors: party + encounter.enemies),
            skills: skillDefinitions,
            inventory: inventory,
            itemDefinitions: itemDefinitions,
            initialPositions: battleInitialPositions(for: encounter, trigger: trigger),
            surfaces: battleSurfaces(),
            hasLineOfSight: battleLineOfSight,
            onAudioCue: { [weak self] cue in self?.audioService.play(cue) }
        )
        appState = .battle
        statusText = "遭遇已触发。"
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

    private func apply(_ save: SaveGame) {
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
        loadArea(save.currentAreaID, spawnID: save.currentSpawnID)
        battleViewModel = nil
        appState = .exploration
        audioService.playExplorationSoundscape(for: save.currentAreaID)
        statusText = "已读取存档。"
    }

    @discardableResult
    private func performSafeAutosave() -> Bool {
        guard let save = makeCurrentSave() else { return false }
        do {
            try saveGameStore.write(save, to: .auto(1), safety: .safe)
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
        guard let recovery = saveGameStore.latestReadableAutosave() else {
            returnToMainMenu()
            statusText = "全队倒下，但没有可用自动存档；已返回主菜单。"
            return
        }

        apply(recovery.save)
        saveLoadViewModel?.refresh()
        statusText = "全队倒下，已读取自动槽 \(recovery.slot.index) 的安全自动存档。"
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

    private static func loadAreaDisplayNames(from bundle: Bundle) -> [String: String] {
        guard
            let url = bundle.url(forResource: "chapter1", withExtension: "json", subdirectory: "Data/worlds"),
            let data = try? Data(contentsOf: url),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let areas = root["areas"] as? [[String: Any]]
        else {
            return [:]
        }

        return Dictionary(uniqueKeysWithValues: areas.compactMap { area in
            guard let id = area["id"] as? String,
                  let displayName = area["displayName"] as? String
            else {
                return nil
            }
            return (id, displayName)
        })
    }

    private static func loadNPCDisplayNames(from bundle: Bundle) -> [String: String] {
        guard
            let url = bundle.url(forResource: "npcs", withExtension: "json", subdirectory: "Data"),
            let data = try? Data(contentsOf: url),
            let npcs = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else {
            return [:]
        }

        return Dictionary(uniqueKeysWithValues: npcs.compactMap { npc in
            guard let id = npc["id"] as? String,
                  let displayName = npc["displayName"] as? String
            else {
                return nil
            }
            return (id, displayName)
        })
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

    private func questTurnInItemIDs(for questID: String) -> [String] {
        // ponytail（有意为之的技术债）：章节任务目前仍使用轻量手写映射；
        // 等任务量进一步上涨，再统一迁移到更完整的数据驱动结构里。
        switch questID {
        case "blood_debt":
            return ["element_ore_ledger"]
        case "bitterroot_medicine":
            return ["bitterroot_herb"]
        case "scorched_vow":
            return ["scorched_ring"]
        case "miners_last_shift":
            return ["miner_gauntlets"]
        default:
            return []
        }
    }

    private func itemName(_ itemID: String) -> String {
        itemDefinitions.first(where: { $0.id == itemID })?.displayName ?? itemID
    }

    private func inventoryContains(_ itemID: String) -> Bool {
        inventory.count(of: itemID) > 0
    }

    private func hasTurnInItems(for questID: String) -> Bool {
        let required = questTurnInItemIDs(for: questID)
        guard !required.isEmpty else { return true }
        return required.allSatisfy { inventoryContains($0) }
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

    private func configureEncounterTriggers() {
        if let metadata = currentMapMetadata {
            encounterTriggerService = EncounterTriggerService(
                triggers: metadata.encounterTriggers,
                encounters: encounterDefinitions,
                triggeredTiledIDs: resolvedEncounterTiledIDs(in: currentAreaID)
            )
        } else {
            encounterTriggerService = nil
        }
    }

    private func loadArea(_ areaID: String, spawnID: String) {
        currentAreaID = areaID
        currentSpawnID = spawnID
        if appState == .exploration {
            audioService.playExplorationSoundscape(for: areaID)
        }
        currentMapMetadata = try? TiledMapLoader.loadMetadata(areaID: areaID, bundle: contentBundle)
        configureEncounterTriggers()
        // 之前这里完全没有把地图的障碍物同步给 explorationController，所以 navObstacle
        // 图层纯粹是摆设——寻路和移动都只看直线距离，玩家可以直接穿过任何障碍物甚至地图边界墙。
        // 现在每次切地图都会把「真正挡路」的障碍物（以及 NPC 站位，避免被一脚踩上去）同步进去。
        explorationController.setObstacles(movementObstacles(for: currentMapMetadata))

        let spawn = currentMapMetadata?.spawns.first { $0.id == spawnID }?.position ?? CGPoint(x: 160, y: 320)
        if !party.isEmpty {
            explorationController.configureParty(party, at: spawn)
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
        currentMapMetadata?.surfaces.compactMap { surface in
            guard let type = SurfaceType(rawValue: surface.surfaceType) else { return nil }
            return BattleSurfaceMarker(
                id: "surface_\(surface.tiledID)",
                frame: surface.frame,
                surfaceType: type
            )
        } ?? []
    }

    private func battleLineOfSight(from start: CGPoint, to end: CGPoint) -> Bool {
        LineOfSightService(obstacles: currentMapMetadata?.navObstacles ?? [])
            .hasLineOfSight(from: start, to: end)
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
        let prefix = "\(areaID):"
        return Set(session.resolvedEncounterKeys.compactMap { key in
            guard key.hasPrefix(prefix) else { return nil }
            return Int(key.dropFirst(prefix.count))
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

        loadArea(exit.targetAreaID, spawnID: exit.targetSpawnID)
        statusText = "进入区域：\(areaDisplayName(for: exit.targetAreaID))"
    }

    private func checkEncounterTrigger() {
        guard appState == .exploration,
              let leaderPosition = explorationController.members.first(where: { $0.actorID == explorationController.leaderID })?.position,
              let triggeredEncounter = encounterTriggerService?.triggeredEncounter(at: leaderPosition)
        else {
            return
        }

        startBattle(triggeredEncounter.definition, trigger: triggeredEncounter.trigger)
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
