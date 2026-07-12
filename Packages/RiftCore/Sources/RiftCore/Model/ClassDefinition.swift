public struct ClassDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var displayName: String
    public var title: String?
    public var combatRole: String?
    public var description: String?
    public var initialStats: Stats
    public var initialSkillIDs: [String]
    public var defaultEquipment: EquipmentLoadout

    public init(
        id: String,
        displayName: String,
        title: String? = nil,
        combatRole: String? = nil,
        description: String? = nil,
        initialStats: Stats,
        initialSkillIDs: [String],
        defaultEquipment: EquipmentLoadout
    ) {
        self.id = id
        self.displayName = displayName
        self.title = title
        self.combatRole = combatRole
        self.description = description
        self.initialStats = initialStats
        self.initialSkillIDs = initialSkillIDs
        self.defaultEquipment = defaultEquipment
    }
}
