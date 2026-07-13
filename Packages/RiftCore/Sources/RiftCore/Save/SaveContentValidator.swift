public enum SaveContentValidationError: Error, Equatable, CustomStringConvertible, Sendable {
    case duplicateCatalogID(kind: String, id: String)
    case nonPlayerActor(actorID: String)
    case missingClassID(actorID: String)
    case unknownClass(actorID: String, classID: String)
    case unknownSkill(actorID: String, skillID: String)
    case duplicateSkill(actorID: String, skillID: String)
    case unknownInventoryItem(String)
    case unknownEquipmentItem(actorID: String, itemID: String)
    case invalidEquipmentSlot(actorID: String, itemID: String, expected: EquipmentSlot, actual: EquipmentSlot?)
    case equippedItemQuantityExceeded(itemID: String, required: Int, available: Int)
    case unknownQuest(String)

    public var description: String {
        switch self {
        case let .duplicateCatalogID(kind, id):
            return "内容目录中的\(kind) ID 重复：\(id)"
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
        case let .equippedItemQuantityExceeded(itemID, required, available):
            return "共享背包中的装备数量不足：\(itemID)，需要 \(required)，现有 \(available)"
        case let .unknownQuest(questID):
            return "任务状态引用了未知任务：\(questID)"
        }
    }
}

public enum SaveContentValidator {
    public static func validate(_ save: SaveGame, against catalog: ContentCatalog) throws {
        let classesByID = try uniqueIndex(catalog.classes, kind: "职业", id: \.id)
        let skillsByID = try uniqueIndex(catalog.skills, kind: "技能", id: \.id)
        let itemsByID = try uniqueIndex(catalog.items, kind: "物品", id: \.id)
        let questIDs = Set(catalog.quests.map(\.id))

        for itemID in save.inventory.itemCounts.keys where itemsByID[itemID] == nil {
            throw SaveContentValidationError.unknownInventoryItem(itemID)
        }

        for questID in save.questState.statuses.keys where !questIDs.contains(questID) {
            throw SaveContentValidationError.unknownQuest(questID)
        }

        var equippedItemCounts: [String: Int] = [:]
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

            for (itemID, slot) in [
                (actor.equipment.weaponID, EquipmentSlot.weapon),
                (actor.equipment.armorID, EquipmentSlot.armor),
                (actor.equipment.accessoryID, EquipmentSlot.accessory)
            ] {
                if let itemID = try validateEquipment(
                    itemID,
                    expectedSlot: slot,
                    actorID: actor.id,
                    itemsByID: itemsByID
                ) {
                    equippedItemCounts[itemID, default: 0] += 1
                }
            }
        }

        for (itemID, required) in equippedItemCounts {
            let available = save.inventory.count(of: itemID)
            guard available >= required else {
                throw SaveContentValidationError.equippedItemQuantityExceeded(
                    itemID: itemID,
                    required: required,
                    available: available
                )
            }
        }
    }

    private static func uniqueIndex<Value>(
        _ values: [Value],
        kind: String,
        id: KeyPath<Value, String>
    ) throws -> [String: Value] {
        var result: [String: Value] = [:]
        for value in values {
            let valueID = value[keyPath: id]
            guard result.updateValue(value, forKey: valueID) == nil else {
                throw SaveContentValidationError.duplicateCatalogID(kind: kind, id: valueID)
            }
        }
        return result
    }

    private static func validateEquipment(
        _ itemID: String?,
        expectedSlot: EquipmentSlot,
        actorID: String,
        itemsByID: [String: ItemDefinition]
    ) throws -> String? {
        guard let itemID else { return nil }
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
        return itemID
    }
}
