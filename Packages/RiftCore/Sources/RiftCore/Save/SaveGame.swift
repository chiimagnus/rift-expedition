public struct SaveGame: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var currentAreaID: String
    public var currentSpawnID: String
    public var party: [Actor]
    public var inventory: PartyInventory

    public init(
        schemaVersion: Int = SaveGame.currentSchemaVersion,
        currentAreaID: String,
        currentSpawnID: String,
        party: [Actor],
        inventory: PartyInventory
    ) {
        self.schemaVersion = schemaVersion
        self.currentAreaID = currentAreaID
        self.currentSpawnID = currentSpawnID
        self.party = party
        self.inventory = inventory
    }
}
