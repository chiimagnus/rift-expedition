import Foundation
import Testing
@testable import RiftValidator

struct ChapterFlowValidationTests {
    @Test func validChapterFlowPasses() throws {
        let fixture = try ChapterFixture()
        defer { fixture.remove() }
        try fixture.writeValidData()

        let optionalResult = try ChapterFlowValidator.validateIfPresent(
            resourcesRoot: fixture.root,
            maps: fixture.validMaps,
            chapterID: "chapter1"
        )
        let result = try #require(optionalResult)

        #expect(result.isValid)
        #expect(result.questCount == 4)
        #expect(result.mainQuestCount == 1)
        #expect(result.sideQuestCount == 3)
        #expect(result.requiredItemCount == 4)
        #expect(result.encounterReferenceCount == 1)
    }

    @Test func detectsMissingCompletionActionAndUnobtainableItem() throws {
        let fixture = try ChapterFixture()
        defer { fixture.remove() }
        try fixture.writeValidData()
        try fixture.replaceDialogAction(dialogID: "elder_return", action: "close")

        let maps = [fixture.makeMap(itemIDs: ["bitterroot_herb", "scorched_ring", "miner_gauntlets"], encounterID: "boar_intro")]
        let optionalResult = try ChapterFlowValidator.validateIfPresent(resourcesRoot: fixture.root, maps: maps, chapterID: "chapter1")
        let result = try #require(optionalResult)

        #expect(result.issues.contains { $0.message.contains("elder_return lacks matching completeQuest") })
        #expect(result.issues.contains { $0.message.contains("element_ore_ledger") && $0.message.contains("unobtainable") })
    }

    @Test func areaReportFiltersAlreadyValidatedChapterResults() throws {
        let chapterMap = TiledMap(areaID: "chapter_area", width: 32, height: 32, objectGroups: [:])
        let siblingMap = TiledMap(areaID: "sibling_area", width: 32, height: 32, objectGroups: [:])
        let chapterResults = [
            MapValidationResult(map: chapterMap, issues: []),
            MapValidationResult(map: siblingMap, issues: [])
        ]

        let reported = try reportedMapResults(
            chapterResults,
            areaID: "chapter_area",
            chapterID: "chapter1"
        )

        #expect(reported.map(\.map.areaID) == ["chapter_area"])
    }

    @Test func chapterSelectionIgnoresQuestsFromOtherChapters() throws {
        let fixture = try ChapterFixture()
        defer { fixture.remove() }
        try fixture.writeValidData()
        try fixture.appendFutureChapterQuest()

        let optionalResult = try ChapterFlowValidator.validateIfPresent(
            resourcesRoot: fixture.root,
            maps: fixture.validMaps,
            chapterID: "chapter1"
        )
        let result = try #require(optionalResult)

        #expect(result.isValid)
        #expect(result.questCount == 4)
    }

    @Test func detectsDialogReferenceToUndefinedQuestAcrossAllChapters() throws {
        let fixture = try ChapterFixture()
        defer { fixture.remove() }
        try fixture.writeValidData()
        try fixture.appendDialogReferencingMissingQuest()

        let optionalResult = try ChapterFlowValidator.validateIfPresent(
            resourcesRoot: fixture.root,
            maps: fixture.validMaps,
            chapterID: "chapter1"
        )
        let result = try #require(optionalResult)

        #expect(result.issues.contains { $0.message.contains("missing_global_quest") })
    }


    @Test func duplicateContentIDsAreReportedWithoutCrashing() throws {
        let fixture = try ChapterFixture()
        defer { fixture.remove() }
        try fixture.writeValidData()
        try fixture.appendDuplicateIDs()

        let optionalResult = try ChapterFlowValidator.validateIfPresent(
            resourcesRoot: fixture.root,
            maps: fixture.validMaps,
            chapterID: "chapter1"
        )
        let result = try #require(optionalResult)

        #expect(result.issues.contains { $0.message == "Duplicate quest id: blood_debt" })
        #expect(result.issues.contains { $0.message == "Duplicate dialog id: elder_intro" })
        #expect(result.issues.contains { $0.message == "Duplicate encounter id: boar_intro" })
        #expect(result.issues.contains { $0.message == "Duplicate item id: element_ore_ledger" })
        #expect(result.issues.contains { $0.message == "Duplicate skill id: water_orb" })
    }

    @Test func detectsDuplicateOptionIDsAndInvalidActionPayloads() throws {
        let fixture = try ChapterFixture()
        defer { fixture.remove() }
        try fixture.writeValidData()
        try fixture.replaceDialogOptions(
            dialogID: "elder_intro",
            options: [
                [
                    "id": "duplicate",
                    "title": "接受",
                    "action": "acceptQuest",
                    "questID": "blood_debt",
                    "encounterID": "boar_intro"
                ],
                [
                    "id": "duplicate",
                    "title": "",
                    "action": "startBattle",
                    "questID": "blood_debt"
                ],
                [
                    "id": "close_payload",
                    "title": "关闭",
                    "action": "close",
                    "questID": "blood_debt"
                ]
            ]
        )

        let optionalResult = try ChapterFlowValidator.validateIfPresent(
            resourcesRoot: fixture.root,
            maps: fixture.validMaps,
            chapterID: "chapter1"
        )
        let result = try #require(optionalResult)

        #expect(result.issues.contains { $0.message == "Duplicate dialog elder_intro option id: duplicate" })
        #expect(result.issues.contains { $0.message.contains("acceptQuest forbids encounterID") })
        #expect(result.issues.contains { $0.message.contains("startBattle forbids questID") })
        #expect(result.issues.contains { $0.message.contains("startBattle requires encounterID") })
        #expect(result.issues.contains { $0.message.contains("close forbids questID and encounterID") })
        #expect(result.issues.contains { $0.message.contains("has blank title") })
    }

    @Test func detectsMissingRewardsAndEncounterReferences() throws {
        let fixture = try ChapterFixture()
        defer { fixture.remove() }
        try fixture.writeValidData()
        try fixture.replaceQuestRewards(itemID: "missing_item", skillID: "missing_skill")

        let maps = [fixture.makeMap(itemIDs: fixture.requiredItemIDs, encounterID: "missing_encounter")]
        let optionalResult = try ChapterFlowValidator.validateIfPresent(resourcesRoot: fixture.root, maps: maps, chapterID: "chapter1")
        let result = try #require(optionalResult)

        #expect(result.issues.contains { $0.message.contains("rewards missing item: missing_item") })
        #expect(result.issues.contains { $0.message.contains("rewards missing skill: missing_skill") })
        #expect(result.issues.contains { $0.message.contains("references missing encounter: missing_encounter") })
    }
}

private enum ChapterFlowValidatorRequiredItems {
    static func items(for questID: String) -> [String] {
        switch questID {
        case "blood_debt": ["element_ore_ledger"]
        case "bitterroot_medicine": ["bitterroot_herb"]
        case "scorched_vow": ["scorched_ring"]
        case "miners_last_shift": ["miner_gauntlets"]
        default: []
        }
    }
}

private final class ChapterFixture {
    let root: URL
    let dataRoot: URL
    let requiredItemIDs = ["element_ore_ledger", "bitterroot_herb", "scorched_ring", "miner_gauntlets"]

    init() throws {
        root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        dataRoot = root.appending(path: "Data")
        try FileManager.default.createDirectory(at: dataRoot, withIntermediateDirectories: true)
    }

    var validMaps: [TiledMap] {
        [makeMap(itemIDs: requiredItemIDs, encounterID: "boar_intro")]
    }

    func makeMap(itemIDs: [String], encounterID: String) -> TiledMap {
        var nextID = 1
        let items = itemIDs.map { itemID -> TiledObject in
            defer { nextID += 1 }
            return TiledObject(
                tiledID: nextID,
                name: nil,
                type: nil,
                x: 0,
                y: 0,
                width: 16,
                height: 16,
                properties: ["itemId": itemID]
            )
        }
        let encounter = TiledObject(
            tiledID: nextID,
            name: nil,
            type: nil,
            x: 0,
            y: 0,
            width: 16,
            height: 16,
            properties: ["encounterId": encounterID]
        )
        return TiledMap(
            areaID: "test_area",
            width: 1024,
            height: 640,
            objectGroups: ["item": items, "encounter": [encounter]]
        )
    }

    func writeValidData() throws {
        let quests: [[String: Any]] = [
            quest("blood_debt", start: "elder_intro", turnIn: "elder_return", main: true, rewards: ["rift_shard_amulet"], skills: ["water_orb"]),
            quest("bitterroot_medicine", start: "healer_request", turnIn: "healer_return"),
            quest("scorched_vow", start: "fiance_ring_request", turnIn: "fiance_ring_return"),
            quest("miners_last_shift", start: "guard_gauntlets_request", turnIn: "guard_gauntlets_return")
        ]
        let dialogs = quests.flatMap { quest -> [[String: Any]] in
            let questID = quest["id"] as! String
            let start = quest["startDialogID"] as! String
            let turnIn = quest["turnInDialogID"] as! String
            return [
                dialog(start, action: "acceptQuest", questID: questID),
                dialog(turnIn, action: "completeQuest", questID: questID)
            ]
        }
        try writeJSON(quests, named: "quests.json")
        try writeJSON(dialogs, named: "dialogs.json")
        try writeJSON([["id": "boar_intro"]], named: "encounters.json")
        try writeJSON((requiredItemIDs + ["rift_shard_amulet"]).map { ["id": $0] }, named: "items.json")
        try writeJSON([["id": "water_orb"]], named: "skills.json")
    }

    func replaceDialogAction(dialogID: String, action: String) throws {
        let url = dataRoot.appending(path: "dialogs.json")
        var records = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [[String: Any]]
        let index = records.firstIndex { $0["id"] as? String == dialogID }!
        var options = records[index]["options"] as! [[String: Any]]
        options[0]["action"] = action
        records[index]["options"] = options
        try writeJSON(records, named: "dialogs.json")
    }

    func replaceDialogOptions(dialogID: String, options: [[String: Any]]) throws {
        let url = dataRoot.appending(path: "dialogs.json")
        var records = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [[String: Any]]
        let index = records.firstIndex { $0["id"] as? String == dialogID }!
        records[index]["options"] = options
        try writeJSON(records, named: "dialogs.json")
    }

    func replaceQuestRewards(itemID: String, skillID: String) throws {
        let url = dataRoot.appending(path: "quests.json")
        var records = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [[String: Any]]
        records[0]["rewardItemIDs"] = [itemID]
        records[0]["rewardSkillIDs"] = [skillID]
        try writeJSON(records, named: "quests.json")
    }


    func appendDuplicateIDs() throws {
        let questsURL = dataRoot.appending(path: "quests.json")
        var quests = try JSONSerialization.jsonObject(with: Data(contentsOf: questsURL)) as! [[String: Any]]
        quests.append(quests[0])
        try writeJSON(quests, named: "quests.json")

        let dialogsURL = dataRoot.appending(path: "dialogs.json")
        var dialogs = try JSONSerialization.jsonObject(with: Data(contentsOf: dialogsURL)) as! [[String: Any]]
        dialogs.append(dialogs[0])
        try writeJSON(dialogs, named: "dialogs.json")

        let encountersURL = dataRoot.appending(path: "encounters.json")
        var encounters = try JSONSerialization.jsonObject(with: Data(contentsOf: encountersURL)) as! [[String: Any]]
        encounters.append(encounters[0])
        try writeJSON(encounters, named: "encounters.json")

        let itemsURL = dataRoot.appending(path: "items.json")
        var items = try JSONSerialization.jsonObject(with: Data(contentsOf: itemsURL)) as! [[String: Any]]
        items.append(items[0])
        try writeJSON(items, named: "items.json")

        let skillsURL = dataRoot.appending(path: "skills.json")
        var skills = try JSONSerialization.jsonObject(with: Data(contentsOf: skillsURL)) as! [[String: Any]]
        skills.append(skills[0])
        try writeJSON(skills, named: "skills.json")
    }

    func appendDialogReferencingMissingQuest() throws {
        let dialogsURL = dataRoot.appending(path: "dialogs.json")
        var dialogs = try JSONSerialization.jsonObject(with: Data(contentsOf: dialogsURL)) as! [[String: Any]]
        dialogs.append(dialog("broken_dialog", action: "acceptQuest", questID: "missing_global_quest"))
        try writeJSON(dialogs, named: "dialogs.json")
    }

    func appendFutureChapterQuest() throws {
        let questsURL = dataRoot.appending(path: "quests.json")
        var quests = try JSONSerialization.jsonObject(with: Data(contentsOf: questsURL)) as! [[String: Any]]
        quests.append([
            "id": "future_quest",
            "chapterID": "chapter2",
            "title": "Future Quest",
            "summary": "Future chapter fixture",
            "isMainQuest": true,
            "locationHint": "Future area",
            "objectives": ["Complete the future fixture"],
            "startDialogID": "future_start",
            "turnInDialogID": "future_turnin",
            "requiredItemIDs": ["future_item"],
            "rewardItemIDs": [],
            "rewardSkillIDs": []
        ])
        try writeJSON(quests, named: "quests.json")

        let dialogsURL = dataRoot.appending(path: "dialogs.json")
        var dialogs = try JSONSerialization.jsonObject(with: Data(contentsOf: dialogsURL)) as! [[String: Any]]
        dialogs.append(dialog("future_start", action: "acceptQuest", questID: "future_quest"))
        dialogs.append(dialog("future_turnin", action: "completeQuest", questID: "future_quest"))
        try writeJSON(dialogs, named: "dialogs.json")
    }

    func remove() {
        try? FileManager.default.removeItem(at: root)
    }

    private func quest(
        _ id: String,
        start: String,
        turnIn: String,
        main: Bool = false,
        rewards: [String] = [],
        skills: [String] = []
    ) -> [String: Any] {
        [
            "id": id,
            "chapterID": "chapter1",
            "title": id,
            "summary": "Fixture quest \(id)",
            "isMainQuest": main,
            "locationHint": "Fixture area",
            "objectives": ["Complete fixture quest \(id)"],
            "startDialogID": start,
            "turnInDialogID": turnIn,
            "requiredItemIDs": ChapterFlowValidatorRequiredItems.items(for: id),
            "rewardItemIDs": rewards,
            "rewardSkillIDs": skills
        ]
    }

    private func dialog(_ id: String, action: String, questID: String) -> [String: Any] {
        [
            "id": id,
            "options": [[
                "id": "\(id)_option",
                "title": "继续",
                "action": action,
                "questID": questID
            ]]
        ]
    }

    private func writeJSON(_ object: Any, named name: String) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: dataRoot.appending(path: name))
    }
}
