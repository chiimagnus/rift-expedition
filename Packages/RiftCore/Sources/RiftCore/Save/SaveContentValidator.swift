public enum SaveContentValidationError: Error, Equatable, CustomStringConvertible, Sendable {
    case nonPlayerActor(actorID: String)
    case missingClassID(actorID: String)
    case unknownClass(actorID: String, classID: String)
    case unknownSkill(actorID: String, skillID: String)
    case duplicateSkill(actorID: String, skillID: String)
    case unknownInventoryItem(String)
    case unknownEquipmentItem(actorID: String, itemID: String)
    case invalidEquipmentSlot(actorID: String, itemID: String, expected: EquipmentSlot, actual: EquipmentSlot?)
    case equippedItemMissingFromInventory(actorID: String, itemID: String)
    case unknownQuest(String)

    public var description: String {
        switch self {
        case let .nonPlayerActor(actorID):
            return "队伍角色不是玩家阵营：\(actorID)"
        case let .missingClassID(actorID):
            return "队伍角色缺少职业：\(actorID)"
        case let .unknownClass(actorID, classID):
            return "队伍角色 \(actorID) 引用了未知职业：\(classID)"
        case let .unknownSkill(actorID, skillID):
            return "队伍角色 \(actorID) 引用了未知技能：\(skillID)"
        case let .duplicateSkill(actorID, skillID):
            return "队伍角色 \(actorID) 重复持有技能：\(skillID)"
        case let .unknownInventoryItem(itemID):
            return "背包引用了未知物品：\(itemID)"
        case let .unknownEquipmentItem(actorID, itemID):
            return "队伍角色 \(actorID) 装备了未知物品：\(itemID)"
        case let .invalidEquipmentSlot(actorID, itemID, expected, actual):
            let actualDescription = actual?.rawValue ?? "非装备"
            return "队伍角色 \(actorID) 的装备 \(itemID) 槽位错误：期望 \(expected.rawValue)，实际 \(actualDescription)"
        case let .equippedItemMissingFromInventory(actorID, itemID):
            return "队伍角色 \(actorID) 的装备未保存在共享背包：\(itemID)"
        case let .unknownQuest(questID):
            return "任务状态引用了未知任务：\(questID)"
        }
    }
}

public enum SaveContentValidator {
    public static func validate(_ save: SaveGame, against catalog: ContentCatalog) throws {
        let classesByID = Dictionary(uniqueKeysWithValues: catalog.classes.map { ($0.id, $0) })
        let skillsByID = Dictionary(uniqueKeysWithValues: catalog.skills.map { ($0.id, $0) })
        let itemsByID = Dictionary(uniqueKeysWithValues: catalog.items.map { ($0.id, $0) })
        let questIDs = Set(catalog.quests.map(\.id))

        for itemID in save.inventory.itemCounts.keys where itemsByID[itemID] == nil {
            throw SaveContentValidationError.unknownInventoryItem(itemID)
        }

        for questID in save.questState.statuses.keys where !questIDs.contains(questID) {
            throw SaveContentValidationError.unknownQuest(questID)
        }

        for actor in save.party {
            guard actor.kind == .player, actor.faction == .player else {
                throw SaveContentValidationError.nonPlayerActor(actorID: actor.id)
            }
            guard let classID = actor.classID else {
                throw SaveContentValidationError.missingClassID(actorID: actor.id)
            }
            guard classesByID[classID] != nil else {
                throw SaveContentValidationError.unknownClass(actorID: actor.id, classID: classID)
            }

            var seenSkills: Set<String> = []
            for skillID in actor.skillIDs {
                guard skillsByID[skillID] != nil else {
                    throw SaveContentValidationError.unknownSkill(actorID: actor.id, skillID: skillID)
                }
                guard seenSkills.insert(skillID).inserted else {
                    throw SaveContentValidationError.duplicateSkill(actorID: actor.id, skillID: skillID)
                }
            }

            try validateEquipment(
                actor.equipment.weaponID,
                expectedSlot: .weapon,
                actorID: actor.id,
                inventory: save.inventory,
                itemsByID: itemsByID
            )
            try validateEquipment(
                actor.equipment.armorID,
                expectedSlot: .armor,
                actorID: actor.id,
                inventory: save.inventory,
                itemsByID: itemsByID
            )
            try validateEquipment(
                actor.equipment.accessoryID,
                expectedSlot: .accessory,
                actorID: actor.id,
                inventory: save.inventory,
                itemsByID: itemsByID
            )
        }
    }

    private static func validateEquipment(
        _ itemID: String?,
        expectedSlot: EquipmentSlot,
        actorID: String,
        inventory: PartyInventory,
        itemsByID: [String: ItemDefinition]
    ) throws {
        guard let itemID else { return }
        guard let item = itemsByID[itemID] else {
            throw SaveContentValidationError.unknownEquipmentItem(actorID: actorID, itemID: itemID)
        }
        guard item.kind == .equipment, item.equipment?.slot == expectedSlot else {
            throw SaveContentValidationError.invalidEquipmentSlot(
                actorID: actorID,
                itemID: itemID,
                expected: expectedSlot,
                actual: item.equipment?.slot
            )
        }
        guard inventory.count(of: itemID) > 0 else {
            throw SaveContentValidationError.equippedItemMissingFromInventory(actorID: actorID, itemID: itemID)
        }
    }
}
