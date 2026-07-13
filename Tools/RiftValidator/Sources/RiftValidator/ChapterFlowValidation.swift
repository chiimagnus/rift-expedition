import Foundation

public struct ChapterFlowValidationIssue: Equatable, Sendable {
    public var message: String

    public init(message: String) {
        self.message = message
    }
}

public struct ChapterFlowValidationResult: Equatable, Sendable {
    public var questCount: Int
    public var mainQuestCount: Int
    public var sideQuestCount: Int
    public var encounterReferenceCount: Int
    public var requiredItemCount: Int
    public var issues: [ChapterFlowValidationIssue]

    public var isValid: Bool { issues.isEmpty }

    public func reportMarkdown() -> String {
        var lines = [
            "# Chapter Flow Validation",
            "",
            "- Quests: \(questCount) (main: \(mainQuestCount), side: \(sideQuestCount))",
            "- Required turn-in items checked: \(requiredItemCount)",
            "- Map encounter references checked: \(encounterReferenceCount)",
            "- Validation: \(issues.isEmpty ? "passed" : "failed")"
        ]
        if issues.isEmpty {
            lines.append("- No issues.")
        } else {
            lines.append("")
            lines.append(contentsOf: issues.map { "- \($0.message)" })
        }
        return lines.joined(separator: "\n") + "\n"
    }
}

public enum ChapterFlowValidator {
    public static func validateIfPresent(
        resourcesRoot: URL,
        maps: [TiledMap],
        chapterID: String? = nil
    ) throws -> ChapterFlowValidationResult? {
        let dataRoot = resourcesRoot.appending(path: "Data")
        let questsURL = dataRoot.appending(path: "quests.json")
        guard FileManager.default.fileExists(atPath: questsURL.path) else { return nil }

        let allQuests = try decode([QuestRecord].self, from: questsURL)
        let quests = chapterID.map { selectedChapterID in
            allQuests.filter { $0.chapterID == selectedChapterID }
        } ?? allQuests
        let dialogs = try decode([DialogRecord].self, from: dataRoot.appending(path: "dialogs.json"))
        let encounters = try decode([IDRecord].self, from: dataRoot.appending(path: "encounters.json"))
        let items = try decode([IDRecord].self, from: dataRoot.appending(path: "items.json"))
        let skills = try decode([IDRecord].self, from: dataRoot.appending(path: "skills.json"))

        var issues: [ChapterFlowValidationIssue] = []
        appendDuplicateIssues(label: "quest", records: allQuests, id: \.id, issues: &issues)
        appendDuplicateIssues(label: "dialog", records: dialogs, id: \.id, issues: &issues)
        appendDuplicateIssues(label: "encounter", records: encounters, id: \.id, issues: &issues)
        appendDuplicateIssues(label: "item", records: items, id: \.id, issues: &issues)
        appendDuplicateIssues(label: "skill", records: skills, id: \.id, issues: &issues)

        let dialogsByID = firstRecordIndex(dialogs, id: \.id)
        let allQuestIDs = Set(allQuests.map(\.id))
        let encounterIDs = Set(encounters.map(\.id))
        let itemIDs = Set(items.map(\.id))
        let skillIDs = Set(skills.map(\.id))
        let mapItemIDs = Set(maps.flatMap { map in
            map.objectGroups["item", default: []].compactMap { $0.properties["itemId"] }
        })
        let mapEncounterReferences = maps.flatMap { map in
            map.objectGroups["encounter", default: []].compactMap { object -> (String, Int, String)? in
                guard let encounterID = object.properties["encounterId"] else { return nil }
                return (map.areaID, object.tiledID, encounterID)
            }
        }

        for quest in quests {
            validateDialog(
                id: quest.startDialogID,
                expectedAction: "acceptQuest",
                questID: quest.id,
                role: "start",
                dialogsByID: dialogsByID,
                issues: &issues
            )

            if let turnInDialogID = quest.turnInDialogID {
                validateDialog(
                    id: turnInDialogID,
                    expectedAction: "completeQuest",
                    questID: quest.id,
                    role: "turn-in",
                    dialogsByID: dialogsByID,
                    issues: &issues
                )
            } else {
                issues.append(.init(message: "Quest \(quest.id) has no turn-in dialog."))
            }

            for itemID in quest.rewardItemIDs where !itemIDs.contains(itemID) {
                issues.append(.init(message: "Quest \(quest.id) rewards missing item: \(itemID)"))
            }
            for skillID in quest.rewardSkillIDs where !skillIDs.contains(skillID) {
                issues.append(.init(message: "Quest \(quest.id) rewards missing skill: \(skillID)"))
            }

            for requiredItemID in quest.requiredItemIDs {
                if !itemIDs.contains(requiredItemID) {
                    issues.append(.init(message: "Quest \(quest.id) requires undefined item: \(requiredItemID)"))
                } else if !mapItemIDs.contains(requiredItemID) {
                    issues.append(.init(message: "Quest \(quest.id) turn-in item is unobtainable from chapter maps: \(requiredItemID)"))
                }
            }
        }


        for (areaID, tiledID, encounterID) in mapEncounterReferences where !encounterIDs.contains(encounterID) {
            issues.append(.init(message: "\(areaID) encounter object \(tiledID) references missing encounter: \(encounterID)"))
        }

        for dialog in dialogs {
            appendDuplicateIssues(
                label: "dialog \(dialog.id) option",
                records: dialog.options,
                id: \.id,
                issues: &issues
            )
            for option in dialog.options {
                let prefix = "Dialog \(dialog.id) option \(option.id)"
                if option.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    issues.append(.init(message: "Dialog \(dialog.id) has blank option id."))
                }
                if option.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    issues.append(.init(message: "\(prefix) has blank title."))
                }
                switch option.action {
                case "acceptQuest", "completeQuest":
                    guard let questID = option.questID?.trimmingCharacters(in: .whitespacesAndNewlines), !questID.isEmpty else {
                        issues.append(.init(message: "\(prefix) action \(option.action) requires questID."))
                        continue
                    }
                    if option.encounterID != nil {
                        issues.append(.init(message: "\(prefix) action \(option.action) forbids encounterID."))
                    }
                    if !allQuestIDs.contains(questID) {
                        issues.append(.init(message: "Dialog \(dialog.id) action \(option.action) references missing quest: \(questID)"))
                    }
                case "startBattle":
                    if option.questID != nil {
                        issues.append(.init(message: "\(prefix) action startBattle forbids questID."))
                    }
                    guard let encounterID = option.encounterID?.trimmingCharacters(in: .whitespacesAndNewlines), !encounterID.isEmpty else {
                        issues.append(.init(message: "\(prefix) action startBattle requires encounterID."))
                        continue
                    }
                    if !encounterIDs.contains(encounterID) {
                        issues.append(.init(message: "Dialog \(dialog.id) references missing encounter: \(encounterID)"))
                    }
                case "close":
                    if option.questID != nil || option.encounterID != nil {
                        issues.append(.init(message: "\(prefix) action close forbids questID and encounterID."))
                    }
                default:
                    issues.append(.init(message: "\(prefix) has unsupported action: \(option.action)"))
                }
            }
        }

        return ChapterFlowValidationResult(
            questCount: quests.count,
            mainQuestCount: quests.filter { $0.isMainQuest == true }.count,
            sideQuestCount: quests.filter { $0.isMainQuest != true }.count,
            encounterReferenceCount: mapEncounterReferences.count,
            requiredItemCount: quests.reduce(0) { $0 + $1.requiredItemIDs.count },
            issues: issues.sorted { $0.message < $1.message }
        )
    }


    private static func appendDuplicateIssues<Record>(
        label: String,
        records: [Record],
        id: KeyPath<Record, String>,
        issues: inout [ChapterFlowValidationIssue]
    ) {
        var seen: Set<String> = []
        var duplicates: Set<String> = []
        for record in records {
            let value = record[keyPath: id]
            if !seen.insert(value).inserted {
                duplicates.insert(value)
            }
        }
        for duplicate in duplicates.sorted() {
            issues.append(.init(message: "Duplicate \(label) id: \(duplicate)"))
        }
    }

    private static func firstRecordIndex<Record>(
        _ records: [Record],
        id: KeyPath<Record, String>
    ) -> [String: Record] {
        records.reduce(into: [:]) { result, record in
            let value = record[keyPath: id]
            if result[value] == nil {
                result[value] = record
            }
        }
    }

    private static func validateDialog(
        id: String,
        expectedAction: String,
        questID: String,
        role: String,
        dialogsByID: [String: DialogRecord],
        issues: inout [ChapterFlowValidationIssue]
    ) {
        guard let dialog = dialogsByID[id] else {
            issues.append(.init(message: "Quest \(questID) \(role) dialog is missing: \(id)"))
            return
        }
        let hasMatchingAction = dialog.options.contains {
            $0.action == expectedAction && $0.questID == questID
        }
        if !hasMatchingAction {
            issues.append(.init(message: "Quest \(questID) \(role) dialog \(id) lacks matching \(expectedAction) action."))
        }
    }

    private static func decode<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        try JSONDecoder().decode(type, from: Data(contentsOf: url))
    }
}

private struct IDRecord: Decodable {
    var id: String
}

private struct QuestRecord: Decodable {
    var id: String
    var chapterID: String
    var isMainQuest: Bool?
    var startDialogID: String
    var turnInDialogID: String?
    var requiredItemIDs: [String]
    var rewardItemIDs: [String]
    var rewardSkillIDs: [String]
}

private struct DialogRecord: Decodable {
    var id: String
    var options: [DialogOptionRecord]
}

private struct DialogOptionRecord: Decodable {
    var id: String
    var title: String
    var action: String
    var questID: String?
    var encounterID: String?
}
