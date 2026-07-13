public struct ContentCatalog: Sendable {
    public var classes: [ClassDefinition]
    public var skills: [SkillDefinition]
    public var items: [ItemDefinition]
    public var encounters: [EncounterDefinition]
    public var quests: [QuestDefinition]
    public var dialogues: [DialogDefinition]

    public init(
        classes: [ClassDefinition],
        skills: [SkillDefinition],
        items: [ItemDefinition],
        encounters: [EncounterDefinition],
        quests: [QuestDefinition],
        dialogues: [DialogDefinition]
    ) {
        self.classes = classes
        self.skills = skills
        self.items = items
        self.encounters = encounters
        self.quests = quests
        self.dialogues = dialogues
    }

    public static let empty = ContentCatalog(
        classes: [],
        skills: [],
        items: [],
        encounters: [],
        quests: [],
        dialogues: []
    )
}

public enum DialogActionDefinition: String, Codable, Equatable, Sendable {
    case acceptQuest
    case completeQuest
    case startBattle
    case close
}

public struct DialogOptionDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var action: DialogActionDefinition
    public var questID: String?
    public var encounterID: String?

    public init(
        id: String,
        title: String,
        action: DialogActionDefinition,
        questID: String? = nil,
        encounterID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.action = action
        self.questID = questID
        self.encounterID = encounterID
    }
}

public struct DialogDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var speakerName: String
    public var lines: [String]
    public var options: [DialogOptionDefinition]

    public init(
        id: String,
        speakerName: String,
        lines: [String],
        options: [DialogOptionDefinition]
    ) {
        self.id = id
        self.speakerName = speakerName
        self.lines = lines
        self.options = options
    }
}
