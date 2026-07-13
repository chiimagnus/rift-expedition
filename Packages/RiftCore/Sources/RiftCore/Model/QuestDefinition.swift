public struct QuestDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var chapterID: String
    public var title: String
    public var summary: String
    public var isMainQuest: Bool
    public var locationHint: String
    public var objectives: [String]
    public var startDialogID: String
    public var turnInDialogID: String
    public var requiredItemIDs: [String]
    public var rewardItemIDs: [String]
    public var rewardSkillIDs: [String]

    public init(
        id: String,
        chapterID: String,
        title: String,
        summary: String,
        isMainQuest: Bool,
        locationHint: String,
        objectives: [String],
        startDialogID: String,
        turnInDialogID: String,
        requiredItemIDs: [String],
        rewardItemIDs: [String],
        rewardSkillIDs: [String]
    ) {
        self.id = id
        self.chapterID = chapterID
        self.title = title
        self.summary = summary
        self.isMainQuest = isMainQuest
        self.locationHint = locationHint
        self.objectives = objectives
        self.startDialogID = startDialogID
        self.turnInDialogID = turnInDialogID
        self.requiredItemIDs = requiredItemIDs
        self.rewardItemIDs = rewardItemIDs
        self.rewardSkillIDs = rewardSkillIDs
    }
}
