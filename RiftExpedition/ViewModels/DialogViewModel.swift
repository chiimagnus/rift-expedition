import Foundation
import Observation
import RiftCore

typealias DialogScript = DialogDefinition
typealias DialogOption = DialogOptionDefinition
typealias DialogAction = DialogActionDefinition

enum DialogOutcome: Equatable {
    case none
    case close
    case questCompletionRequested(String)
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
                guard let questID = option.questID else {
                    message = "任务交付配置无效。"
                    return .none
                }
                return .questCompletionRequested(questID)
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

}
