public enum ContentValidationError: Error, Equatable, CustomStringConvertible, Sendable {
    case duplicateID(kind: String, id: String)
    case missingReference(owner: String, field: String, id: String)
    case invalidItem(owner: String, id: String, reason: String)

    public var description: String {
        switch self {
        case let .duplicateID(kind, id):
            "Duplicate \(kind) id: \(id)"
        case let .missingReference(owner, field, id):
            "Missing reference in \(owner).\(field): \(id)"
        case let .invalidItem(owner, id, reason):
            "Invalid item in \(owner): \(id) (\(reason))"
        }
    }
}

public struct ContentValidationFailure: Error, CustomStringConvertible, Sendable {
    public var errors: [ContentValidationError]

    public init(errors: [ContentValidationError]) {
        self.errors = errors
    }

    public var description: String {
        errors.map(\.description).joined(separator: "\n")
    }
}

public enum ContentValidator {
    public static func validate(_ catalog: ContentCatalog) throws {
        let errors = collectErrors(in: catalog)
        if !errors.isEmpty {
            throw ContentValidationFailure(errors: errors)
        }
    }

    public static func collectErrors(in catalog: ContentCatalog) -> [ContentValidationError] {
        var errors: [ContentValidationError] = []

        errors.append(contentsOf: duplicateErrors(catalog.classes.map(\.id), kind: "class"))
        errors.append(contentsOf: duplicateErrors(catalog.skills.map(\.id), kind: "skill"))
        errors.append(contentsOf: duplicateErrors(catalog.items.map(\.id), kind: "item"))
        errors.append(contentsOf: duplicateErrors(catalog.quests.map(\.id), kind: "quest"))
        errors.append(contentsOf: duplicateErrors(catalog.dialogues.map(\.id), kind: "dialogue"))

        let skillIDs = Set(catalog.skills.map(\.id))
        let itemIDs = Set(catalog.items.map(\.id))
        let dialogueIDs = Set(catalog.dialogues.map(\.id))

        for classDefinition in catalog.classes {
            for skillID in classDefinition.initialSkillIDs where !skillIDs.contains(skillID) {
                errors.append(.missingReference(owner: "class:\(classDefinition.id)", field: "initialSkillIDs", id: skillID))
            }
            for itemID in [
                classDefinition.defaultEquipment.weaponID,
                classDefinition.defaultEquipment.armorID,
                classDefinition.defaultEquipment.accessoryID
            ].compactMap({ $0 }) where !itemIDs.contains(itemID) {
                errors.append(.missingReference(owner: "class:\(classDefinition.id)", field: "defaultEquipment", id: itemID))
            }
        }

        for item in catalog.items where item.kind == .equipment && item.equipment == nil {
            errors.append(.invalidItem(owner: "item:\(item.id)", id: item.id, reason: "equipment item requires equipment definition"))
        }

        for quest in catalog.quests {
            if !dialogueIDs.contains(quest.startDialogID) {
                errors.append(.missingReference(owner: "quest:\(quest.id)", field: "startDialogID", id: quest.startDialogID))
            }
            if let turnInDialogID = quest.turnInDialogID, !dialogueIDs.contains(turnInDialogID) {
                errors.append(.missingReference(owner: "quest:\(quest.id)", field: "turnInDialogID", id: turnInDialogID))
            }
            for itemID in quest.rewardItemIDs where !itemIDs.contains(itemID) {
                errors.append(.missingReference(owner: "quest:\(quest.id)", field: "rewardItemIDs", id: itemID))
            }
            for skillID in quest.rewardSkillIDs where !skillIDs.contains(skillID) {
                errors.append(.missingReference(owner: "quest:\(quest.id)", field: "rewardSkillIDs", id: skillID))
            }
        }

        return errors
    }

    private static func duplicateErrors(_ ids: [String], kind: String) -> [ContentValidationError] {
        var seen: Set<String> = []
        var duplicates: [ContentValidationError] = []

        for id in ids where !seen.insert(id).inserted {
            duplicates.append(.duplicateID(kind: kind, id: id))
        }

        return duplicates
    }
}
