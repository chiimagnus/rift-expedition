public struct ClassDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var displayName: String
    public var initialStats: Stats
    public var initialSkillIDs: [String]
    public var defaultEquipment: EquipmentLoadout

    public init(
        id: String,
        displayName: String,
        initialStats: Stats,
        initialSkillIDs: [String],
        defaultEquipment: EquipmentLoadout
    ) {
        self.id = id
        self.displayName = displayName
        self.initialStats = initialStats
        self.initialSkillIDs = initialSkillIDs
        self.defaultEquipment = defaultEquipment
    }
}
