import Observation
import RiftCore

enum PartyCreationError: Error, Equatable {
    case unknownClass(String)
}

@MainActor
@Observable
final class PartyCreationViewModel {
    let availableClasses: [ClassDefinition]
    private let skillNamesByID: [String: String]
    private let itemDefinitions: [ItemDefinition]
    var selectedClassIDs: [String] = []

    init(
        classes: [ClassDefinition],
        skillNamesByID: [String: String] = [:],
        itemDefinitions: [ItemDefinition]
    ) {
        availableClasses = classes
        self.skillNamesByID = skillNamesByID
        self.itemDefinitions = itemDefinitions
    }

    var canStart: Bool {
        selectedClassIDs.count == 2
    }

    func isSelected(_ classID: String) -> Bool {
        selectedClassIDs.contains(classID)
    }

    func toggleSelection(_ classID: String) {
        if let index = selectedClassIDs.firstIndex(of: classID) {
            selectedClassIDs.remove(at: index)
            return
        }

        guard selectedClassIDs.count < 2 else { return }
        selectedClassIDs.append(classID)
    }

    func clearSelection() {
        selectedClassIDs.removeAll(keepingCapacity: true)
    }

    func createParty() throws -> [Actor] {
        guard canStart else { return [] }

        return try selectedClassIDs.enumerated().map { index, classID in
            guard let classDefinition = availableClasses.first(where: { $0.id == classID }) else {
                throw PartyCreationError.unknownClass(classID)
            }
            var actor = Actor(
                id: "player_\(index + 1)",
                displayName: adventurerName(for: classDefinition.id, fallbackIndex: index),
                kind: .player,
                faction: .player,
                level: 1,
                stats: classDefinition.initialStats,
                classID: classDefinition.id,
                skillIDs: classDefinition.initialSkillIDs,
                equipment: classDefinition.defaultEquipment
            )
            try EquipmentRules.applyEquippedModifiers(to: &actor, items: itemDefinitions)
            return actor
        }
    }

    func selectionIndex(for classID: String) -> Int? {
        selectedClassIDs.firstIndex(of: classID).map { $0 + 1 }
    }

    func adventurerName(for classID: String, fallbackIndex: Int = 0) -> String {
        switch classID {
        case "warrior":
            "赫岚"
        case "archer":
            "烬羽"
        case "mage":
            "瑟芙"
        case "rogue":
            "鸦刃"
        default:
            "远征者\(fallbackIndex + 1)"
        }
    }

    func skillSummary(for classDefinition: ClassDefinition) -> String {
        classDefinition.initialSkillIDs
            .map { skillNamesByID[$0] ?? "未知技能" }
            .joined(separator: "、")
    }
}
