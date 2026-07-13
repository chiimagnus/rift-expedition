import CoreGraphics
import Foundation
import RiftCore

enum EncounterDefinitionLoadingError: Error, Equatable, CustomStringConvertible {
    case missingResource
    case emptyEncounterID
    case duplicateEncounterID(String)
    case emptyEnemyRoster(encounterID: String)
    case emptyEnemyID(encounterID: String)
    case duplicateEnemyID(encounterID: String, actorID: String)
    case invalidEnemyFaction(encounterID: String, actorID: String)

    var description: String {
        switch self {
        case .missingResource:
            "缺少遭遇数据资源。"
        case .emptyEncounterID:
            "遭遇 ID 不能为空。"
        case let .duplicateEncounterID(id):
            "重复的遭遇 ID：\(id)"
        case let .emptyEnemyRoster(encounterID):
            "遭遇 \(encounterID) 没有敌人。"
        case let .emptyEnemyID(encounterID):
            "遭遇 \(encounterID) 包含空敌人 ID。"
        case let .duplicateEnemyID(encounterID, actorID):
            "遭遇 \(encounterID) 包含重复敌人 ID：\(actorID)"
        case let .invalidEnemyFaction(encounterID, actorID):
            "遭遇 \(encounterID) 的敌人 \(actorID) 不是敌对阵营。"
        }
    }
}

struct EncounterDefinition: Codable, Equatable, Identifiable {
    var id: String
    var displayName: String
    var enemies: [Actor]
}

struct TriggeredEncounter: Equatable {
    var definition: EncounterDefinition
    var trigger: MapEncounterTrigger
}

struct EncounterTriggerService: Equatable {
    private let triggers: [MapEncounterTrigger]
    private let encountersByID: [String: EncounterDefinition]
    private(set) var triggeredTiledIDs: Set<Int>

    init(
        triggers: [MapEncounterTrigger],
        encounters: [EncounterDefinition],
        triggeredTiledIDs: Set<Int> = []
    ) throws {
        try Self.validateDefinitions(encounters)
        self.triggers = triggers
        encountersByID = Dictionary(uniqueKeysWithValues: encounters.map { ($0.id, $0) })
        self.triggeredTiledIDs = triggeredTiledIDs
    }

    func pendingEncounter(at position: CGPoint) -> TriggeredEncounter? {
        guard let trigger = triggers.first(where: { trigger in
            !triggeredTiledIDs.contains(trigger.tiledID)
                && trigger.contains(position)
                && encountersByID[trigger.encounterID] != nil
        }), let encounter = encountersByID[trigger.encounterID] else {
            return nil
        }
        return TriggeredEncounter(definition: encounter, trigger: trigger)
    }

    mutating func markTriggered(tiledID: Int) {
        triggeredTiledIDs.insert(tiledID)
    }

    static func loadDefinitions(from bundle: Bundle = .main) throws -> [EncounterDefinition] {
        guard let url = bundle.url(forResource: "encounters", withExtension: "json", subdirectory: "Data") else {
            throw EncounterDefinitionLoadingError.missingResource
        }
        let definitions = try JSONDecoder().decode([EncounterDefinition].self, from: Data(contentsOf: url))
        try validateDefinitions(definitions)
        return definitions
    }

    static func validateDefinitions(_ definitions: [EncounterDefinition]) throws {
        var encounterIDs: Set<String> = []
        for encounter in definitions {
            guard !encounter.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw EncounterDefinitionLoadingError.emptyEncounterID
            }
            guard encounterIDs.insert(encounter.id).inserted else {
                throw EncounterDefinitionLoadingError.duplicateEncounterID(encounter.id)
            }
            guard !encounter.enemies.isEmpty else {
                throw EncounterDefinitionLoadingError.emptyEnemyRoster(encounterID: encounter.id)
            }

            var enemyIDs: Set<String> = []
            for enemy in encounter.enemies {
                guard !enemy.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw EncounterDefinitionLoadingError.emptyEnemyID(encounterID: encounter.id)
                }
                guard enemyIDs.insert(enemy.id).inserted else {
                    throw EncounterDefinitionLoadingError.duplicateEnemyID(
                        encounterID: encounter.id,
                        actorID: enemy.id
                    )
                }
                guard enemy.faction == .hostile || enemy.faction == .animal || enemy.faction == .monster else {
                    throw EncounterDefinitionLoadingError.invalidEnemyFaction(
                        encounterID: encounter.id,
                        actorID: enemy.id
                    )
                }
            }
        }
    }
}
