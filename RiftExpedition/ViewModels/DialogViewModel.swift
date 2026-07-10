import Foundation
import Observation
import RiftCore

struct DialogScript: Codable, Equatable, Identifiable {
    var id: String
    var speakerName: String
    var lines: [String]
    var options: [DialogOption]
}

struct DialogOption: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var action: DialogAction
    var questID: String?
    var encounterID: String?
}

enum DialogAction: String, Codable, Equatable {
    case acceptQuest
    case completeQuest
    case startBattle
    case close
}

enum DialogOutcome: Equatable {
    case none
    case close
    case completedQuest(String)
    case startBattle(String)
}

@MainActor
@Observable
final class DialogViewModel {
    private let scriptsByID: [String: DialogScript]
    private let questDefinitions: [QuestDefinition]
    private let session: GameSessionState
    var activeDialog: DialogScript?
    var message = "还没有对话。"

    init(
        scripts: [DialogScript],
        questDefinitions: [QuestDefinition],
        session: GameSessionState = GameSessionState()
    ) {
        var indexedScripts: [String: DialogScript] = [:]
        for script in scripts where indexedScripts[script.id] == nil {
            indexedScripts[script.id] = script
        }
        scriptsByID = indexedScripts
        self.questDefinitions = questDefinitions
        self.session = session
    }

    var questState: QuestState { session.questState }

    var questLogEntries: [QuestLogEntry] {
        QuestEngine.logEntries(in: questState, definitions: questDefinitions)
    }

    func start(dialogID: String) -> Bool {
        guard let script = scriptsByID[dialogID] else {
            message = "没有找到对话。"
            return false
        }

        activeDialog = script
        message = ""
        return true
    }

    func choose(_ option: DialogOption) -> DialogOutcome {
        do {
            switch option.action {
            case .acceptQuest:
                if let questID = option.questID {
                    session.questState = try QuestEngine.accept(
                        questID: questID,
                        in: session.questState,
                        definitions: questDefinitions
                    )
                    message = "任务已接受。"
                }
                return .none
            case .completeQuest:
                if let questID = option.questID {
                    session.questState = try QuestEngine.complete(
                        questID: questID,
                        in: session.questState,
                        definitions: questDefinitions
                    )
                    message = "任务已完成。"
                    return .completedQuest(questID)
                }
                return .none
            case .startBattle:
                guard let encounterID = option.encounterID else { return .none }
                return .startBattle(encounterID)
            case .close:
                return .close
            }
        } catch {
            message = "任务状态不满足。"
            return .none
        }
    }

    static func loadScripts(from bundle: Bundle = .main) -> [DialogScript] {
        guard let url = bundle.url(forResource: "dialogs", withExtension: "json", subdirectory: "Data"),
              let data = try? Data(contentsOf: url),
              let scripts = try? JSONDecoder().decode([DialogScript].self, from: data)
        else {
            return []
        }
        return scripts
    }
}
