public struct SaveGame: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 2

    public var schemaVersion: Int
    public var currentAreaID: String
    public var currentSpawnID: String
    public var party: [Actor]
    public var inventory: PartyInventory
    public var questState: QuestState
    public var collectedMapItemKeys: [String]
    public var firedMapTriggerKeys: [String]

    public init(
        schemaVersion: Int = SaveGame.currentSchemaVersion,
        currentAreaID: String,
        currentSpawnID: String,
        party: [Actor],
        inventory: PartyInventory,
        questState: QuestState = QuestState(),
        collectedMapItemKeys: [String] = [],
        firedMapTriggerKeys: [String] = []
    ) {
        self.schemaVersion = schemaVersion
        self.currentAreaID = currentAreaID
        self.currentSpawnID = currentSpawnID
        self.party = party
        self.inventory = inventory
        self.questState = questState
        self.collectedMapItemKeys = collectedMapItemKeys
        self.firedMapTriggerKeys = firedMapTriggerKeys
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, currentAreaID, currentSpawnID, party, inventory
        case questState, collectedMapItemKeys, firedMapTriggerKeys
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        currentAreaID = try container.decode(String.self, forKey: .currentAreaID)
        currentSpawnID = try container.decode(String.self, forKey: .currentSpawnID)
        party = try container.decode([Actor].self, forKey: .party)
        inventory = try container.decode(PartyInventory.self, forKey: .inventory)
        questState = try container.decodeIfPresent(QuestState.self, forKey: .questState) ?? QuestState()
        collectedMapItemKeys = try container.decodeIfPresent([String].self, forKey: .collectedMapItemKeys) ?? []
        firedMapTriggerKeys = try container.decodeIfPresent([String].self, forKey: .firedMapTriggerKeys) ?? []
    }
}
