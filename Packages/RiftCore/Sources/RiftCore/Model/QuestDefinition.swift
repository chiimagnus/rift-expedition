public struct QuestDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var summary: String
    public var isMainQuest: Bool?
    public var locationHint: String?
    public var objectives: [String]?
    public var startDialogID: String
    public var turnInDialogID: String?
    public var rewardItemIDs: [String]
    public var rewardSkillIDs: [String]

    public init(
        id: String,
        title: String,
        summary: String,
        isMainQuest: Bool? = nil,
        locationHint: String? = nil,
        objectives: [String]? = nil,
        startDialogID: String,
        turnInDialogID: String? = nil,
        rewardItemIDs: [String] = [],
        rewardSkillIDs: [String] = []
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.isMainQuest = isMainQuest
        self.locationHint = locationHint
        self.objectives = objectives
        self.startDialogID = startDialogID
        self.turnInDialogID = turnInDialogID
        self.rewardItemIDs = rewardItemIDs
        self.rewardSkillIDs = rewardSkillIDs
    }
}
