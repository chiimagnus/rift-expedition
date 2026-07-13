public struct QuestDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var summary: String
    public var isMainQuest: Bool?
    public var locationHint: String?
    public var objectives: [String]?
    public var startDialogID: String
    public var turnInDialogID: String?
    public var requiredItemIDs: [String]
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
        requiredItemIDs: [String] = [],
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
        self.requiredItemIDs = requiredItemIDs
        self.rewardItemIDs = rewardItemIDs
        self.rewardSkillIDs = rewardSkillIDs
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case summary
        case isMainQuest
        case locationHint
        case objectives
        case startDialogID
        case turnInDialogID
        case requiredItemIDs
        case rewardItemIDs
        case rewardSkillIDs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        summary = try container.decode(String.self, forKey: .summary)
        isMainQuest = try container.decodeIfPresent(Bool.self, forKey: .isMainQuest)
        locationHint = try container.decodeIfPresent(String.self, forKey: .locationHint)
        objectives = try container.decodeIfPresent([String].self, forKey: .objectives)
        startDialogID = try container.decode(String.self, forKey: .startDialogID)
        turnInDialogID = try container.decodeIfPresent(String.self, forKey: .turnInDialogID)
        requiredItemIDs = try container.decodeIfPresent([String].self, forKey: .requiredItemIDs) ?? []
        rewardItemIDs = try container.decodeIfPresent([String].self, forKey: .rewardItemIDs) ?? []
        rewardSkillIDs = try container.decodeIfPresent([String].self, forKey: .rewardSkillIDs) ?? []
    }
}
