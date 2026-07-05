public struct ContentCatalog: Sendable {
    public var classes: [ClassDefinition]
    public var skills: [SkillDefinition]
    public var items: [ItemDefinition]
    public var quests: [QuestDefinition]
    public var dialogues: [DialogDefinition]

    public init(
        classes: [ClassDefinition],
        skills: [SkillDefinition],
        items: [ItemDefinition],
        quests: [QuestDefinition],
        dialogues: [DialogDefinition]
    ) {
        self.classes = classes
        self.skills = skills
        self.items = items
        self.quests = quests
        self.dialogues = dialogues
    }
}

public struct DialogDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var speakerName: String
    public var lines: [String]

    public init(id: String, speakerName: String, lines: [String]) {
        self.id = id
        self.speakerName = speakerName
        self.lines = lines
    }
}
