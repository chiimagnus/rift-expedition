public enum SaveGameDecodingError: Error, Equatable, Sendable {
    case unsupportedSchemaVersion(found: Int, expected: Int)
    case emptyAreaID
    case emptySpawnID
    case emptyParty
    case emptyActorID
    case duplicateActorID(String)
    case invalidActorProgression(actorID: String, field: String, value: Int)
    case invalidActorStat(actorID: String, field: String, value: Int)
    case healthOutOfRange(actorID: String, health: Int, maxHealth: Int)
    case actionPointsOutOfRange(actorID: String, actionPoints: Int, maxActionPoints: Int)
    case invalidStatusDuration(actorID: String, status: StatusType, remainingTurns: Int)
    case duplicateStatus(actorID: String, status: StatusType)
    case invalidMapStateKey(field: String, key: String)
    case duplicateMapStateKey(field: String, key: String)
}

public struct SaveGame: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 3

    public var schemaVersion: Int
    public var currentAreaID: String
    public var currentSpawnID: String
    public var party: [Actor]
    public var inventory: PartyInventory
    public var questState: QuestState
    public var collectedMapItemKeys: [String]
    public var firedMapTriggerKeys: [String]
    public var resolvedEncounterKeys: [String]

    public init(
        currentAreaID: String,
        currentSpawnID: String,
        party: [Actor],
        inventory: PartyInventory,
        questState: QuestState = QuestState(),
        collectedMapItemKeys: [String] = [],
        firedMapTriggerKeys: [String] = [],
        resolvedEncounterKeys: [String] = []
    ) {
        schemaVersion = SaveGame.currentSchemaVersion
        self.currentAreaID = currentAreaID
        self.currentSpawnID = currentSpawnID
        self.party = party
        self.inventory = inventory
        self.questState = questState
        self.collectedMapItemKeys = collectedMapItemKeys
        self.firedMapTriggerKeys = firedMapTriggerKeys
        self.resolvedEncounterKeys = resolvedEncounterKeys
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, currentAreaID, currentSpawnID, party, inventory
        case questState, collectedMapItemKeys, firedMapTriggerKeys, resolvedEncounterKeys
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        currentAreaID = try container.decode(String.self, forKey: .currentAreaID)
        currentSpawnID = try container.decode(String.self, forKey: .currentSpawnID)
        party = try container.decode([Actor].self, forKey: .party)
        inventory = try container.decode(PartyInventory.self, forKey: .inventory)
        questState = try container.decode(QuestState.self, forKey: .questState)
        collectedMapItemKeys = try container.decode([String].self, forKey: .collectedMapItemKeys)
        firedMapTriggerKeys = try container.decode([String].self, forKey: .firedMapTriggerKeys)
        resolvedEncounterKeys = try container.decode([String].self, forKey: .resolvedEncounterKeys)
        try validate()
    }

    public func validate() throws {
        guard schemaVersion == SaveGame.currentSchemaVersion else {
            throw SaveGameDecodingError.unsupportedSchemaVersion(
                found: schemaVersion,
                expected: SaveGame.currentSchemaVersion
            )
        }
        guard !currentAreaID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SaveGameDecodingError.emptyAreaID
        }
        guard !currentSpawnID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SaveGameDecodingError.emptySpawnID
        }
        guard !party.isEmpty else {
            throw SaveGameDecodingError.emptyParty
        }

        var actorIDs: Set<String> = []
        for actor in party {
            guard !actor.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw SaveGameDecodingError.emptyActorID
            }
            guard actorIDs.insert(actor.id).inserted else {
                throw SaveGameDecodingError.duplicateActorID(actor.id)
            }
            try Self.validateActor(actor)
        }

        try inventory.validate()
        try Self.validateMapStateKeys(collectedMapItemKeys, field: "collectedMapItemKeys")
        try Self.validateMapStateKeys(firedMapTriggerKeys, field: "firedMapTriggerKeys")
        try Self.validateMapStateKeys(resolvedEncounterKeys, field: "resolvedEncounterKeys")
    }

    private static func validateActor(_ actor: Actor) throws {
        let progressionValues = [
            (field: "level", value: actor.level, isValid: actor.level >= 1),
            (field: "experience", value: actor.experience, isValid: actor.experience >= 0),
            (field: "unspentAttributePoints", value: actor.unspentAttributePoints, isValid: actor.unspentAttributePoints >= 0)
        ]
        for entry in progressionValues where !entry.isValid {
            throw SaveGameDecodingError.invalidActorProgression(
                actorID: actor.id,
                field: entry.field,
                value: entry.value
            )
        }

        let statValues = [
            (field: "maxHealth", value: actor.stats.maxHealth, isValid: actor.stats.maxHealth > 0),
            (field: "attack", value: actor.stats.attack, isValid: actor.stats.attack >= 0),
            (field: "defense", value: actor.stats.defense, isValid: actor.stats.defense >= 0),
            (field: "evasion", value: actor.stats.evasion, isValid: actor.stats.evasion >= 0),
            (field: "magic", value: actor.stats.magic, isValid: actor.stats.magic >= 0),
            (field: "maxActionPoints", value: actor.stats.maxActionPoints, isValid: actor.stats.maxActionPoints > 0)
        ]
        for entry in statValues where !entry.isValid {
            throw SaveGameDecodingError.invalidActorStat(
                actorID: actor.id,
                field: entry.field,
                value: entry.value
            )
        }

        guard (0...actor.stats.maxHealth).contains(actor.stats.health) else {
            throw SaveGameDecodingError.healthOutOfRange(
                actorID: actor.id,
                health: actor.stats.health,
                maxHealth: actor.stats.maxHealth
            )
        }
        guard (0...actor.stats.maxActionPoints).contains(actor.stats.actionPoints) else {
            throw SaveGameDecodingError.actionPointsOutOfRange(
                actorID: actor.id,
                actionPoints: actor.stats.actionPoints,
                maxActionPoints: actor.stats.maxActionPoints
            )
        }

        var statusTypes: Set<StatusType> = []
        for status in actor.statuses {
            guard status.remainingTurns > 0 else {
                throw SaveGameDecodingError.invalidStatusDuration(
                    actorID: actor.id,
                    status: status.type,
                    remainingTurns: status.remainingTurns
                )
            }
            guard statusTypes.insert(status.type).inserted else {
                throw SaveGameDecodingError.duplicateStatus(actorID: actor.id, status: status.type)
            }
        }
    }

    private static func validateMapStateKeys(_ keys: [String], field: String) throws {
        var uniqueKeys: Set<String> = []
        for key in keys {
            let parts = key.split(separator: ":", omittingEmptySubsequences: false)
            guard parts.count == 2,
                  !parts[0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let tiledID = Int(parts[1]),
                  tiledID > 0
            else {
                throw SaveGameDecodingError.invalidMapStateKey(field: field, key: key)
            }
            guard uniqueKeys.insert(key).inserted else {
                throw SaveGameDecodingError.duplicateMapStateKey(field: field, key: key)
            }
        }
    }
}
