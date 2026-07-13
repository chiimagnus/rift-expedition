import Foundation

public enum ContentValidationError: Error, Equatable, CustomStringConvertible, Sendable {
    case duplicateID(kind: String, id: String)
    case missingReference(owner: String, field: String, id: String)
    case invalidClass(owner: String, id: String, reason: String)
    case invalidItem(owner: String, id: String, reason: String)
    case invalidQuest(owner: String, id: String, reason: String)
    case invalidSkill(owner: String, id: String, reason: String)
    case invalidDialogue(owner: String, id: String, reason: String)
    case invalidEncounter(owner: String, id: String, reason: String)

    public var description: String {
        switch self {
        case let .duplicateID(kind, id):
            "Duplicate \(kind) id: \(id)"
        case let .missingReference(owner, field, id):
            "Missing reference in \(owner).\(field): \(id)"
        case let .invalidClass(owner, id, reason):
            "Invalid class in \(owner): \(id) (\(reason))"
        case let .invalidItem(owner, id, reason):
            "Invalid item in \(owner): \(id) (\(reason))"
        case let .invalidQuest(owner, id, reason):
            "Invalid quest in \(owner): \(id) (\(reason))"
        case let .invalidSkill(owner, id, reason):
            "Invalid skill in \(owner): \(id) (\(reason))"
        case let .invalidDialogue(owner, id, reason):
            "Invalid dialogue in \(owner): \(id) (\(reason))"
        case let .invalidEncounter(owner, id, reason):
            "Invalid encounter in \(owner): \(id) (\(reason))"
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
        errors.append(contentsOf: duplicateErrors(catalog.encounters.map(\.id), kind: "encounter"))
        errors.append(contentsOf: duplicateErrors(catalog.quests.map(\.id), kind: "quest"))
        errors.append(contentsOf: duplicateErrors(catalog.dialogues.map(\.id), kind: "dialogue"))

        let classIDs = Set(catalog.classes.map(\.id))
        let skillIDs = Set(catalog.skills.map(\.id))
        let itemIDs = Set(catalog.items.map(\.id))
        let encounterIDs = Set(catalog.encounters.map(\.id))
        let dialogueIDs = Set(catalog.dialogues.map(\.id))

        for skill in catalog.skills {
            let owner = "skill:\(skill.id)"
            if skill.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(.invalidSkill(owner: owner, id: skill.id, reason: "id must not be blank"))
            }
            if skill.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(.invalidSkill(owner: owner, id: skill.id, reason: "displayName must not be blank"))
            }
            if isBlank(skill.description) {
                errors.append(.invalidSkill(owner: owner, id: skill.id, reason: "description must not be blank"))
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
            switch skill.target {
            case .selfOnly where !skill.affectsAllies, .ally where !skill.affectsAllies:
                errors.append(.invalidSkill(
                    owner: owner,
                    id: skill.id,
                    reason: "selfOnly and ally targets require affectsAllies"
                ))
            case .enemy where skill.affectsAllies:
                errors.append(.invalidSkill(
                    owner: owner,
                    id: skill.id,
                    reason: "enemy targets forbid affectsAllies"
                ))
            default:
                break
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

        let itemsByID = catalog.items.reduce(into: [String: ItemDefinition]()) { result, item in
            if result[item.id] == nil { result[item.id] = item }
        }

        for classDefinition in catalog.classes {
            let owner = "class:\(classDefinition.id)"
            if isBlank(classDefinition.id) {
                errors.append(.invalidClass(owner: owner, id: classDefinition.id, reason: "id must not be blank"))
            }
            if isBlank(classDefinition.displayName) {
                errors.append(.invalidClass(owner: owner, id: classDefinition.id, reason: "displayName must not be blank"))
            }
            if isBlank(classDefinition.title) {
                errors.append(.invalidClass(owner: owner, id: classDefinition.id, reason: "title must not be blank"))
            }
            if isBlank(classDefinition.combatRole) {
                errors.append(.invalidClass(owner: owner, id: classDefinition.id, reason: "combatRole must not be blank"))
            }
            if isBlank(classDefinition.description) {
                errors.append(.invalidClass(owner: owner, id: classDefinition.id, reason: "description must not be blank"))
            }
            let stats = classDefinition.initialStats
            if stats.maxHealth <= 0 {
                errors.append(.invalidClass(owner: owner, id: classDefinition.id, reason: "initialStats.maxHealth must be positive"))
            }
            if stats.health <= 0 || stats.health > stats.maxHealth {
                errors.append(.invalidClass(owner: owner, id: classDefinition.id, reason: "initialStats.health must be within 1...maxHealth"))
            }
            if [stats.attack, stats.defense, stats.evasion, stats.magic].contains(where: { $0 < 0 }) {
                errors.append(.invalidClass(owner: owner, id: classDefinition.id, reason: "initialStats combat values must be non-negative"))
            }
            if stats.maxActionPoints <= 0 {
                errors.append(.invalidClass(owner: owner, id: classDefinition.id, reason: "initialStats.maxActionPoints must be positive"))
            }
            if stats.actionPoints < 0 || stats.actionPoints > stats.maxActionPoints {
                errors.append(.invalidClass(owner: owner, id: classDefinition.id, reason: "initialStats.actionPoints must be within 0...maxActionPoints"))
            }
            if classDefinition.initialSkillIDs.isEmpty {
                errors.append(.invalidClass(owner: owner, id: classDefinition.id, reason: "initialSkillIDs must not be empty"))
            }
            if hasDuplicates(classDefinition.initialSkillIDs) {
                errors.append(.invalidClass(owner: owner, id: classDefinition.id, reason: "initialSkillIDs must not contain duplicates"))
            }
            for skillID in classDefinition.initialSkillIDs {
                if isBlank(skillID) {
                    errors.append(.invalidClass(owner: owner, id: classDefinition.id, reason: "initialSkillIDs must not contain blank ids"))
                } else if !skillIDs.contains(skillID) {
                    errors.append(.missingReference(owner: owner, field: "initialSkillIDs", id: skillID))
                }
            }
            let equipmentReferences: [(field: String, id: String?, slot: EquipmentSlot)] = [
                ("weaponID", classDefinition.defaultEquipment.weaponID, .weapon),
                ("armorID", classDefinition.defaultEquipment.armorID, .armor),
                ("accessoryID", classDefinition.defaultEquipment.accessoryID, .accessory)
            ]
            for reference in equipmentReferences {
                guard let itemID = reference.id else { continue }
                guard !isBlank(itemID) else {
                    errors.append(.invalidClass(owner: owner, id: classDefinition.id, reason: "defaultEquipment.\(reference.field) must not be blank"))
                    continue
                }
                guard let item = itemsByID[itemID] else {
                    errors.append(.missingReference(owner: owner, field: "defaultEquipment.\(reference.field)", id: itemID))
                    continue
                }
                guard item.kind == .equipment, let equipment = item.equipment else {
                    errors.append(.invalidClass(owner: owner, id: classDefinition.id, reason: "defaultEquipment.\(reference.field) must reference equipment"))
                    continue
                }
                if equipment.slot != reference.slot {
                    errors.append(.invalidClass(
                        owner: owner,
                        id: classDefinition.id,
                        reason: "defaultEquipment.\(reference.field) expected \(reference.slot.rawValue), got \(equipment.slot.rawValue)"
                    ))
                }
            }
        }

        for item in catalog.items {
            let owner = "item:\(item.id)"
            if isBlank(item.id) {
                errors.append(.invalidItem(owner: owner, id: item.id, reason: "id must not be blank"))
            }
            if isBlank(item.displayName) {
                errors.append(.invalidItem(owner: owner, id: item.id, reason: "displayName must not be blank"))
            }
            if isBlank(item.description) {
                errors.append(.invalidItem(owner: owner, id: item.id, reason: "description must not be blank"))
            }
            switch item.kind {
            case .equipment:
                if item.skillID != nil {
                    errors.append(.invalidItem(owner: owner, id: item.id, reason: "equipment item forbids skillID"))
                }
                guard let equipment = item.equipment else {
                    errors.append(.invalidItem(owner: owner, id: item.id, reason: "equipment item requires equipment definition"))
                    continue
                }
                if equipment.id != item.id {
                    errors.append(.invalidItem(owner: owner, id: item.id, reason: "equipment id must match item id"))
                }
                if isBlank(equipment.displayName) {
                    errors.append(.invalidItem(owner: owner, id: item.id, reason: "equipment displayName must not be blank"))
                }
                let modifiers = equipment.modifiers
                if [modifiers.maxHealth, modifiers.attack, modifiers.defense, modifiers.evasion, modifiers.magic]
                    .contains(where: { $0 < 0 })
                {
                    errors.append(.invalidItem(owner: owner, id: item.id, reason: "equipment modifiers must be non-negative"))
                }
            case .consumable:
                if item.equipment != nil {
                    errors.append(.invalidItem(owner: owner, id: item.id, reason: "consumable item forbids equipment definition"))
                }
                guard let rawSkillID = item.skillID else {
                    errors.append(.invalidItem(owner: owner, id: item.id, reason: "consumable item requires skillID"))
                    continue
                }
                let skillID = rawSkillID.trimmingCharacters(in: .whitespacesAndNewlines)
                if skillID.isEmpty {
                    errors.append(.invalidItem(owner: owner, id: item.id, reason: "consumable skillID must not be blank"))
                } else if !skillIDs.contains(skillID) {
                    errors.append(.missingReference(owner: owner, field: "skillID", id: skillID))
                }
            case .quest:
                if item.equipment != nil || item.skillID != nil {
                    errors.append(.invalidItem(owner: owner, id: item.id, reason: "quest item forbids equipment and skillID"))
                }
            }
        }

        for encounter in catalog.encounters {
            let owner = "encounter:\(encounter.id)"
            if isBlank(encounter.id) {
                errors.append(.invalidEncounter(owner: owner, id: encounter.id, reason: "id must not be blank"))
            }
            if isBlank(encounter.displayName) {
                errors.append(.invalidEncounter(owner: owner, id: encounter.id, reason: "displayName must not be blank"))
            }
            if encounter.enemies.isEmpty {
                errors.append(.invalidEncounter(owner: owner, id: encounter.id, reason: "enemies must not be empty"))
            }
            if hasDuplicates(encounter.enemies.map(\.id)) {
                errors.append(.invalidEncounter(owner: owner, id: encounter.id, reason: "enemy ids must not contain duplicates"))
            }

            for enemy in encounter.enemies {
                let actorOwner = "\(owner).enemy:\(enemy.id)"
                if isBlank(enemy.id) {
                    errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "enemy id must not be blank"))
                }
                if isBlank(enemy.displayName) {
                    errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "enemy displayName must not be blank"))
                }
                if ![Faction.hostile, .animal, .monster].contains(enemy.faction) {
                    errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "enemy faction must be hostile, animal, or monster"))
                }
                if ![ActorKind.humanEnemy, .animal, .monster].contains(enemy.kind) {
                    errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "enemy kind must be humanEnemy, animal, or monster"))
                }
                if enemy.level <= 0 {
                    errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "level must be positive"))
                }
                if enemy.experience < 0 || enemy.unspentAttributePoints < 0 {
                    errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "progression values must be non-negative"))
                }
                let stats = enemy.stats
                if stats.maxHealth <= 0 || stats.health <= 0 || stats.health > stats.maxHealth {
                    errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "health must be within 1...maxHealth"))
                }
                if stats.maxActionPoints <= 0 || stats.actionPoints < 0 || stats.actionPoints > stats.maxActionPoints {
                    errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "actionPoints must be within 0...maxActionPoints"))
                }
                if [stats.attack, stats.defense, stats.evasion, stats.magic].contains(where: { $0 < 0 }) {
                    errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "combat stats must be non-negative"))
                }
                if let classID = enemy.classID {
                    if isBlank(classID) {
                        errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "classID must not be blank"))
                    } else if !classIDs.contains(classID) {
                        errors.append(.missingReference(owner: actorOwner, field: "classID", id: classID))
                    }
                }
                if enemy.skillIDs.isEmpty {
                    errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "skillIDs must not be empty"))
                }
                if hasDuplicates(enemy.skillIDs) {
                    errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "skillIDs must not contain duplicates"))
                }
                for skillID in enemy.skillIDs {
                    if isBlank(skillID) {
                        errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "skillIDs must not contain blank ids"))
                    } else if !skillIDs.contains(skillID) {
                        errors.append(.missingReference(owner: actorOwner, field: "skillIDs", id: skillID))
                    }
                }
                let equipmentReferences: [(String, String?, EquipmentSlot)] = [
                    ("weaponID", enemy.equipment.weaponID, .weapon),
                    ("armorID", enemy.equipment.armorID, .armor),
                    ("accessoryID", enemy.equipment.accessoryID, .accessory)
                ]
                for (field, itemID, expectedSlot) in equipmentReferences {
                    guard let itemID else { continue }
                    guard let item = itemsByID[itemID] else {
                        errors.append(.missingReference(owner: actorOwner, field: "equipment.\(field)", id: itemID))
                        continue
                    }
                    guard item.kind == .equipment, let equipment = item.equipment else {
                        errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "equipment.\(field) must reference equipment"))
                        continue
                    }
                    if equipment.slot != expectedSlot {
                        errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "equipment.\(field) expected \(expectedSlot.rawValue), got \(equipment.slot.rawValue)"))
                    }
                }
                if Set(enemy.statuses.map(\.type)).count != enemy.statuses.count {
                    errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "statuses must not contain duplicates"))
                }
                if enemy.statuses.contains(where: { $0.remainingTurns <= 0 }) {
                    errors.append(.invalidEncounter(owner: actorOwner, id: enemy.id, reason: "status durations must be positive"))
                }
            }
        }

        let questIDs = Set(catalog.quests.map(\.id))
        for dialogue in catalog.dialogues {
            let owner = "dialogue:\(dialogue.id)"
            if isBlank(dialogue.id) {
                errors.append(.invalidDialogue(owner: owner, id: dialogue.id, reason: "id must not be blank"))
            }
            if isBlank(dialogue.speakerName) {
                errors.append(.invalidDialogue(owner: owner, id: dialogue.id, reason: "speakerName must not be blank"))
            }
            if dialogue.lines.isEmpty {
                errors.append(.invalidDialogue(owner: owner, id: dialogue.id, reason: "lines must not be empty"))
            }
            for (index, line) in dialogue.lines.enumerated() where isBlank(line) {
                errors.append(.invalidDialogue(owner: owner, id: dialogue.id, reason: "line \(index) must not be blank"))
            }
            if dialogue.options.isEmpty {
                errors.append(.invalidDialogue(owner: owner, id: dialogue.id, reason: "options must not be empty"))
            }
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
                    if !encounterIDs.contains(encounterID) {
                        errors.append(.missingReference(owner: owner, field: "option.encounterID", id: encounterID))
                    }
                case .close:
                    if option.questID != nil || option.encounterID != nil {
                        errors.append(.invalidDialogue(owner: owner, id: optionID, reason: "close forbids questID and encounterID"))
                    }
                }
            }
        }

        for quest in catalog.quests {
            let owner = "quest:\(quest.id)"
            for (field, value) in [
                ("id", quest.id),
                ("chapterID", quest.chapterID),
                ("title", quest.title),
                ("summary", quest.summary),
                ("locationHint", quest.locationHint),
                ("startDialogID", quest.startDialogID),
                ("turnInDialogID", quest.turnInDialogID)
            ] where isBlank(value) {
                errors.append(.invalidQuest(owner: owner, id: quest.id, reason: "\(field) must not be blank"))
            }
            if quest.objectives.isEmpty {
                errors.append(.invalidQuest(owner: owner, id: quest.id, reason: "objectives must not be empty"))
            }
            if quest.objectives.contains(where: isBlank) {
                errors.append(.invalidQuest(owner: owner, id: quest.id, reason: "objectives must not contain blank values"))
            }
            if hasDuplicates(quest.objectives) {
                errors.append(.invalidQuest(owner: owner, id: quest.id, reason: "objectives must not contain duplicates"))
            }
            if hasDuplicates(quest.requiredItemIDs) {
                errors.append(.invalidQuest(
                    owner: owner,
                    id: quest.id,
                    reason: "requiredItemIDs must not contain duplicates"
                ))
            }
            if hasDuplicates(quest.rewardItemIDs) {
                errors.append(.invalidQuest(owner: owner, id: quest.id, reason: "rewardItemIDs must not contain duplicates"))
            }
            if hasDuplicates(quest.rewardSkillIDs) {
                errors.append(.invalidQuest(owner: owner, id: quest.id, reason: "rewardSkillIDs must not contain duplicates"))
            }
            for itemID in quest.requiredItemIDs {
                if isBlank(itemID) {
                    errors.append(.invalidQuest(owner: owner, id: quest.id, reason: "requiredItemIDs must not contain blank ids"))
                } else if !itemIDs.contains(itemID) {
                    errors.append(.missingReference(owner: owner, field: "requiredItemIDs", id: itemID))
                }
            }
            if !dialogueIDs.contains(quest.startDialogID) {
                errors.append(.missingReference(owner: owner, field: "startDialogID", id: quest.startDialogID))
            }
            if !dialogueIDs.contains(quest.turnInDialogID) {
                errors.append(.missingReference(owner: owner, field: "turnInDialogID", id: quest.turnInDialogID))
            }
            for itemID in quest.rewardItemIDs {
                if isBlank(itemID) {
                    errors.append(.invalidQuest(owner: owner, id: quest.id, reason: "rewardItemIDs must not contain blank ids"))
                } else if !itemIDs.contains(itemID) {
                    errors.append(.missingReference(owner: owner, field: "rewardItemIDs", id: itemID))
                }
            }
            for skillID in quest.rewardSkillIDs {
                if isBlank(skillID) {
                    errors.append(.invalidQuest(owner: owner, id: quest.id, reason: "rewardSkillIDs must not contain blank ids"))
                } else if !skillIDs.contains(skillID) {
                    errors.append(.missingReference(owner: owner, field: "rewardSkillIDs", id: skillID))
                }
            }
        }

        return errors
    }

    private static func isBlank(_ value: String) -> Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func hasDuplicates(_ values: [String]) -> Bool {
        Set(values).count != values.count
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
