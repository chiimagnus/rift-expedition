public enum QuestStatus: String, Codable, Equatable, Sendable {
    case inactive
    case active
    case completed
}

public struct QuestState: Codable, Equatable, Sendable {
    public var statuses: [String: QuestStatus]

    public init(statuses: [String: QuestStatus] = [:]) {
        self.statuses = statuses
    }
}

public struct QuestLogEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var objective: String
    public var status: QuestStatus
    public var isMainQuest: Bool
    public var locationHint: String
    public var objectives: [String]

    public init(
        id: String,
        title: String,
        objective: String,
        status: QuestStatus,
        isMainQuest: Bool,
        locationHint: String,
        objectives: [String]
    ) {
        self.id = id
        self.title = title
        self.objective = objective
        self.status = status
        self.isMainQuest = isMainQuest
        self.locationHint = locationHint
        self.objectives = objectives
    }
}

public enum QuestEngineError: Error, Equatable, Sendable {
    case missingQuest(String)
    case questNotActive(String)
}

public enum QuestEngine {
    public static func status(of questID: String, in state: QuestState) -> QuestStatus {
        state.statuses[questID] ?? .inactive
    }

    public static func accept(questID: String, in state: QuestState, definitions: [QuestDefinition]) throws -> QuestState {
        guard definitions.contains(where: { $0.id == questID }) else {
            throw QuestEngineError.missingQuest(questID)
        }

        var next = state
        if status(of: questID, in: state) != .completed {
            next.statuses[questID] = .active
        }
        return next
    }

    public static func complete(questID: String, in state: QuestState, definitions: [QuestDefinition]) throws -> QuestState {
        guard definitions.contains(where: { $0.id == questID }) else {
            throw QuestEngineError.missingQuest(questID)
        }
        guard status(of: questID, in: state) == .active else {
            throw QuestEngineError.questNotActive(questID)
        }

        var next = state
        next.statuses[questID] = .completed
        return next
    }

    public static func logEntries(in state: QuestState, definitions: [QuestDefinition]) -> [QuestLogEntry] {
        definitions.compactMap { definition in
            let status = status(of: definition.id, in: state)
            guard status != .inactive else { return nil }

            let objective = switch status {
            case .inactive:
                definition.summary
            case .active:
                definition.summary
            case .completed:
                "已完成：\(definition.summary)"
            }

            return QuestLogEntry(
                id: definition.id,
                title: definition.title,
                objective: objective,
                status: status,
                isMainQuest: definition.isMainQuest,
                locationHint: definition.locationHint,
                objectives: definition.objectives
            )
        }
    }
}
