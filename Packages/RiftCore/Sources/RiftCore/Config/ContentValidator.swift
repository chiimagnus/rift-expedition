import Foundation

public enum ContentValidationError: Error, Equatable, CustomStringConvertible, Sendable {
    case duplicateID(kind: String, id: String)
    case missingReference(owner: String, field: String, id: String)
    case invalidItem(owner: String, id: String, reason: String)
    case invalidQuest(owner: String, id: String, reason: String)
    case invalidSkill(owner: String, id: String, reason: String)
    case invalidDialogue(owner: String, id: String, reason: String)

    public var description: String {
        switch self {
        case let .duplicateID(kind, id):
            "Duplicate \(kind) id: \(id)"
        case let .missingReference(owner, field, id):
            "Missing reference in \(owner).\(field): \(id)"
        case let .invalidItem(owner, id, reason):
            "Invalid item in \(owner): \(id) (\(reason))"
        case let .invalidQuest(owner, id, reason):
            "Invalid quest in \(owner): \(id) (\(reason))"
        case let .invalidSkill(owner, id, reason):
            "Invalid skill in \(owner): \(id) (\(reason))"
        case let .invalidDialogue(owner, id, reason):
            "Invalid dialogue in \(owner): \(id) (\(reason))"
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

        for skill in catalog.skills {
            let owner = "skill:\(skill.id)"
            if skill.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(.invalidSkill(owner: owner, id: skill.id, reason: "id must not be blank"))
            }
            if skill.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(.invalidSkill(owner: owner, id: skill.id, reason: "displayName must not be blank"))
            }
            if skill.actionPointCost <= 0 {
                errors.append(.invalidSkill(owner: owner, id: skill.id, reason: "actionPointCost must be positive"))
            }
            if !skill.range.isFinite || skill.range < 0 {
                errors.append(.invalidSkill(owner: owner, id: skill.id, reason: "range must be finite and non-negative"))
            }
            if skill.effects.isEmpty {
                errors.append(.invalidSkill(owner: owner, id: skill.id, reason: "effects must not be empty"))
            }
            for effect in skill.effects {
                switch effect {
                case let .damage(amount):
                    if amount <= 0 {
                        errors.append(.invalidSkill(owner: owner, id: skill.id, reason: "damage amount must be positive"))
                    }
                case let .heal(amount):
                    if amount <= 0 {
                        errors.append(.invalidSkill(owner: owner, id: skill.id, reason: "heal amount must be positive"))
                    }
                case let .applyStatus(statusID, durationTurns):
                    if StatusType(rawValue: statusID) == nil {
                        errors.append(.invalidSkill(owner: owner, id: skill.id, reason: "unknown statusID: \(statusID)"))
                    }
                    if durationTurns <= 0 {
                        errors.append(.invalidSkill(owner: owner, id: skill.id, reason: "status duration must be positive"))
                    }
                case let .createSurface(surfaceID, durationTurns):
                    if SurfaceType(rawValue: surfaceID) == nil {
                        errors.append(.invalidSkill(owner: owner, id: skill.id, reason: "unknown surfaceID: \(surfaceID)"))
                    }
                    if durationTurns <= 0 {
                        errors.append(.invalidSkill(owner: owner, id: skill.id, reason: "surface duration must be positive"))
                    }
                }
            }
        }

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
        for item in catalog.items where item.kind == .consumable {
            guard let skillID = item.skillID else {
                errors.append(.invalidItem(owner: "item:\(item.id)", id: item.id, reason: "consumable item requires skillID"))
                continue
            }
            if !skillIDs.contains(skillID) {
                errors.append(.missingReference(owner: "item:\(item.id)", field: "skillID", id: skillID))
            }
        }

        let questIDs = Set(catalog.quests.map(\.id))
        for dialogue in catalog.dialogues {
            let owner = "dialogue:\(dialogue.id)"
            errors.append(contentsOf: duplicateErrors(
                dialogue.options.map(\.id),
                kind: "dialogue option in \(dialogue.id)"
            ))
            for option in dialogue.options {
                let optionID = option.id
                if optionID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    errors.append(.invalidDialogue(owner: owner, id: optionID, reason: "option id must not be blank"))
                }
                if option.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    errors.append(.invalidDialogue(owner: owner, id: optionID, reason: "option title must not be blank"))
                }
                switch option.action {
                case .acceptQuest, .completeQuest:
                    guard let questID = option.questID?.trimmingCharacters(in: .whitespacesAndNewlines), !questID.isEmpty else {
                        errors.append(.invalidDialogue(owner: owner, id: optionID, reason: "\(option.action.rawValue) requires questID"))
                        continue
                    }
                    if option.encounterID != nil {
                        errors.append(.invalidDialogue(owner: owner, id: optionID, reason: "\(option.action.rawValue) forbids encounterID"))
                    }
                    if !questIDs.contains(questID) {
                        errors.append(.missingReference(owner: owner, field: "option.questID", id: questID))
                    }
                case .startBattle:
                    if option.questID != nil {
                        errors.append(.invalidDialogue(owner: owner, id: optionID, reason: "startBattle forbids questID"))
                    }
                    guard let encounterID = option.encounterID?.trimmingCharacters(in: .whitespacesAndNewlines), !encounterID.isEmpty else {
                        errors.append(.invalidDialogue(owner: owner, id: optionID, reason: "startBattle requires encounterID"))
                        continue
                    }
                case .close:
                    if option.questID != nil || option.encounterID != nil {
                        errors.append(.invalidDialogue(owner: owner, id: optionID, reason: "close forbids questID and encounterID"))
                    }
                }
            }
        }

        for quest in catalog.quests {
            if Set(quest.requiredItemIDs).count != quest.requiredItemIDs.count {
                errors.append(.invalidQuest(
                    owner: "quest:\(quest.id)",
                    id: quest.id,
                    reason: "requiredItemIDs must not contain duplicates"
                ))
            }
            for itemID in quest.requiredItemIDs where !itemIDs.contains(itemID) {
                errors.append(.missingReference(owner: "quest:\(quest.id)", field: "requiredItemIDs", id: itemID))
            }
            if !dialogueIDs.contains(quest.startDialogID) {
                errors.append(.missingReference(owner: "quest:\(quest.id)", field: "startDialogID", id: quest.startDialogID))
            }
            if !dialogueIDs.contains(quest.turnInDialogID) {
                errors.append(.missingReference(owner: "quest:\(quest.id)", field: "turnInDialogID", id: quest.turnInDialogID))
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
