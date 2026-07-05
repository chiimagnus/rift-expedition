enum AppState: Equatable {
    case mainMenu
    case partyCreation
    case exploration
    case dialogue
    case questLog
    case battle
    case inventory
    case saveLoad
    case settings
    case chapterComplete

    var title: String {
        switch self {
        case .mainMenu:
            "主菜单"
        case .partyCreation:
            "创建队伍"
        case .exploration:
            "探索"
        case .dialogue:
            "对话"
        case .questLog:
            "任务日志"
        case .battle:
            "战斗"
        case .inventory:
            "背包"
        case .saveLoad:
            "存档"
        case .settings:
            "设置"
        case .chapterComplete:
            "章节完成"
        }
    }
}
