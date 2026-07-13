public struct EncounterDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var displayName: String
    public var enemies: [Actor]

    public init(id: String, displayName: String, enemies: [Actor]) {
        self.id = id
        self.displayName = displayName
        self.enemies = enemies
    }
}
