import Observation
import RiftCore

struct InventoryItemRow: Equatable, Identifiable {
    var id: String
    var displayName: String
    var count: Int
    var slotName: String?
}

struct CharacterSkillRow: Equatable, Identifiable {
    var id: String
    var displayName: String
    var description: String
    var actionPointCost: Int
    var range: Double
    var targetName: String
}

@MainActor
@Observable
final class InventoryViewModel {
    private let session: GameSessionState
    let itemDefinitions: [ItemDefinition]
    let skillDefinitions: [SkillDefinition]
    var selectedActorID: String?
    var statusText = "队伍背包已打开。"

    init(
        session: GameSessionState,
        itemDefinitions: [ItemDefinition],
        skillDefinitions: [SkillDefinition] = []
    ) {
        self.session = session
        self.itemDefinitions = itemDefinitions
        self.skillDefinitions = skillDefinitions
        selectedActorID = session.party.first?.id
    }

    convenience init(
        party: [Actor],
        inventory: PartyInventory,
        itemDefinitions: [ItemDefinition],
        skillDefinitions: [SkillDefinition] = []
    ) {
        self.init(
            session: GameSessionState(party: party, inventory: inventory),
            itemDefinitions: itemDefinitions,
            skillDefinitions: skillDefinitions
        )
    }

    var party: [Actor] {
        session.party
    }

    var inventory: PartyInventory {
        session.inventory
    }

    var selectedActor: Actor? {
        guard let selectedActorID else { return nil }
        return party.first { $0.id == selectedActorID }
    }

    var inventoryRows: [InventoryItemRow] {
        inventory.itemCounts.keys.sorted().compactMap { itemID in
            guard let item = itemDefinitions.first(where: { $0.id == itemID }) else { return nil }
            return InventoryItemRow(
                id: itemID,
                displayName: item.displayName,
                count: inventory.count(of: itemID),
                slotName: item.equipment.map { slotName($0.slot) }
            )
        }
    }

    func skills(for actor: Actor) -> [CharacterSkillRow] {
        actor.skillIDs.compactMap { skillID in
            guard let skill = skillDefinitions.first(where: { $0.id == skillID }) else { return nil }
            return CharacterSkillRow(
                id: skill.id,
                displayName: skill.displayName,
                description: skill.description ?? "尚未记录该技能的战术说明。",
                actionPointCost: skill.actionPointCost,
                range: skill.range,
                targetName: targetName(skill.target)
            )
        }
    }

    func selectActor(id: String) {
        guard party.contains(where: { $0.id == id }) else { return }
        selectedActorID = id
    }

    func equippedItemName(for actor: Actor, slot: EquipmentSlot) -> String {
        guard let itemID = actor.equipment.itemID(in: slot),
              let item = itemDefinitions.first(where: { $0.id == itemID })
        else {
            return "未装备"
        }
        return item.displayName
    }

    func equip(itemID: String) {
        guard let selectedActorID,
              let actorIndex = party.firstIndex(where: { $0.id == selectedActorID })
        else {
            statusText = "请选择角色。"
            return
        }

        var actor = session.party[actorIndex]
        do {
            try EquipmentRules.equip(
                itemID: itemID,
                on: &actor,
                inventory: session.inventory,
                items: itemDefinitions
            )
            session.party[actorIndex] = actor
            statusText = "\(actor.displayName) 已装备 \(itemName(itemID))。"
        } catch {
            statusText = readableError(error)
        }
    }

    func allocate(_ attribute: Attribute) {
        guard let selectedActorID,
              let actorIndex = party.firstIndex(where: { $0.id == selectedActorID })
        else {
            statusText = "请选择角色。"
            return
        }

        var actor = session.party[actorIndex]
        do {
            try AttributePoints.allocate(1, to: attribute, actor: &actor)
            session.party[actorIndex] = actor
            statusText = "\(actor.displayName) 提升了\(attributeName(attribute))。"
        } catch {
            statusText = readableError(error)
        }
    }

    func attributeName(_ attribute: Attribute) -> String {
        switch attribute {
        case .maxHealth:
            "生命值"
        case .attack:
            "攻击值"
        case .defense:
            "防御值"
        case .evasion:
            "闪避值"
        case .magic:
            "魔法值"
        }
    }

    func slotName(_ slot: EquipmentSlot) -> String {
        switch slot {
        case .weapon:
            "武器"
        case .armor:
            "护甲"
        case .accessory:
            "饰品"
        }
    }

    private func targetName(_ target: SkillTarget) -> String {
        switch target {
        case .selfOnly:
            "自身"
        case .ally:
            "友军"
        case .enemy:
            "敌人"
        }
    }

    private func itemName(_ itemID: String) -> String {
        itemDefinitions.first(where: { $0.id == itemID })?.displayName ?? itemID
    }

    private func readableError(_ error: Error) -> String {
        switch error {
        case let error as EquipmentError:
            return readableEquipmentError(error)
        case let error as AttributePointError:
            return readableAttributeError(error)
        default:
            return "操作失败。"
        }
    }

    private func readableEquipmentError(_ error: EquipmentError) -> String {
        switch error {
        case .itemNotInInventory(_):
            return "背包中没有该物品。"
        case .unknownItem(_):
            return "没有找到该物品配置。"
        case .notEquipment(_):
            return "该物品不是装备。"
        }
    }

    private func readableAttributeError(_ error: AttributePointError) -> String {
        switch error {
        case .nonPositiveAmount(_):
            return "属性点数量无效。"
        case let .insufficientPoints(_, available):
            return "属性点不足：当前 \(available)。"
        }
    }
}
