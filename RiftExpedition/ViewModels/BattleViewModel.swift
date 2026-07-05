import Observation
import RiftCore

enum BattleActionChoice: Equatable {
    case move
    case basicAttack
    case skill(String)
    case consumable
}

@MainActor
@Observable
final class BattleViewModel {
    private var engine: BattleEngine
    private let skillDefinitions: [SkillDefinition]
    private let skillsByID: [String: SkillDefinition]
    var selectedAction: BattleActionChoice = .move
    var statusText = "战斗开始。"
    var targetPrompt = "选择行动。"

    init(state: BattleState, skills: [SkillDefinition]) {
        engine = BattleEngine(state: state)
        skillDefinitions = skills
        var indexedSkills: [String: SkillDefinition] = [:]
        for skill in skills where indexedSkills[skill.id] == nil {
            indexedSkills[skill.id] = skill
        }
        skillsByID = indexedSkills
    }

    var state: BattleState {
        engine.state
    }

    var activeActor: Actor? {
        guard let activeActorID = state.activeActorID else { return nil }
        return state.actor(id: activeActorID)
    }

    var activeSkills: [SkillDefinition] {
        guard let activeActor else { return [] }
        return activeActor.skillIDs.compactMap { skillsByID[$0] }
    }

    var canPerformBasicAttack: Bool {
        guard let firstSkill = activeSkills.first else { return false }
        return canUseSkill(firstSkill)
    }

    var canEndTurn: Bool {
        state.outcome == .ongoing && state.activeActorID != nil
    }

    var outcomeText: String {
        switch state.outcome {
        case .ongoing:
            "战斗进行中"
        case .victory:
            "胜利"
        case .defeat:
            "失败"
        }
    }

    func canMove(distance: Double = APRules.movementDistancePerAPStartingValue) -> Bool {
        canSpend(actionPointCost: APRules.movementCost(forDistance: distance))
    }

    func canUseSkill(_ skill: SkillDefinition) -> Bool {
        canSpend(actionPointCost: skill.actionPointCost)
    }

    func canUseSkill(id: String) -> Bool {
        guard let skill = skillsByID[id] else { return false }
        return canUseSkill(skill)
    }

    func selectMove() {
        selectedAction = .move
        targetPrompt = "选择移动位置。"
    }

    func performMove(distance: Double = APRules.movementDistancePerAPStartingValue) {
        selectedAction = .move
        targetPrompt = "移动会消耗 AP；地图点选移动将在后续接入。"
        guard let actor = activeActor else {
            statusText = "没有可行动角色。"
            return
        }
        guard actor.faction == .player else {
            statusText = "当前不是玩家回合。"
            return
        }

        do {
            try engine.move(actorID: actor.id, distance: distance)
            statusText = "\(actor.displayName) 移动，消耗 \(APRules.movementCost(forDistance: distance)) AP。"
        } catch {
            statusText = readableError(error)
        }
    }

    func performBasicAttack() {
        selectedAction = .basicAttack
        targetPrompt = "选择普攻目标。"
        guard let firstSkill = activeSkills.first else {
            statusText = "没有可用普攻。"
            return
        }

        perform(skill: firstSkill, label: "普攻")
    }

    func performSkill(id: String) {
        guard let skill = skillsByID[id] else {
            statusText = "没有找到技能。"
            return
        }

        selectedAction = .skill(id)
        targetPrompt = "选择「\(skill.displayName)」的目标。"
        perform(skill: skill, label: skill.displayName)
    }

    func selectConsumable() {
        selectedAction = .consumable
        targetPrompt = "选择消耗品目标。"
        statusText = "首版尚未配置战斗消耗品。"
    }

    func endTurn() {
        do {
            try engine.endTurn()
            if let enemyStatus = performEnemyTurnsIfNeeded() {
                statusText = enemyStatus
            } else if let activeActor {
                statusText = "轮到 \(activeActor.displayName)。"
            } else {
                statusText = "回合结束。"
            }
            targetPrompt = "选择行动。"
        } catch {
            statusText = readableError(error)
        }
    }

    private func performEnemyTurnsIfNeeded() -> String? {
        var lastStatus: String?
        for _ in 0..<max(state.actors.count, 1) {
            guard state.outcome == .ongoing,
                  let actor = activeActor,
                  actor.faction != .player
            else {
                break
            }

            let action = EnemyAI.chooseAction(
                for: actor,
                in: state,
                context: EnemyAIContext(skills: skillDefinitions)
            )
            lastStatus = performEnemyAction(action, actor: actor)

            do {
                try engine.endTurn()
            } catch {
                return readableError(error)
            }
        }
        return lastStatus
    }

    private func performEnemyAction(_ action: EnemyAIAction, actor: Actor) -> String {
        do {
            switch action {
            case let .moveToward(targetID, distance):
                try engine.move(actorID: actor.id, distance: distance)
                return "\(actor.displayName) 逼近 \(actorName(targetID))。"
            case let .moveAway(targetID, distance):
                try engine.move(actorID: actor.id, distance: distance)
                return "\(actor.displayName) 与 \(actorName(targetID)) 拉开距离。"
            case let .useSkill(skillID, targetID):
                guard let skill = skillsByID[skillID] else {
                    return "\(actor.displayName) 没有找到可用技能。"
                }
                try engine.useSkill(actorID: actor.id, skill: skill)
                return "\(actor.displayName) 对 \(actorName(targetID)) 使用\(skill.displayName)。"
            case .endTurn:
                return "\(actor.displayName) 结束回合。"
            }
        } catch {
            return readableError(error)
        }
    }

    private func perform(skill: SkillDefinition, label: String) {
        guard let actor = activeActor else {
            statusText = "没有可行动角色。"
            return
        }
        guard actor.faction == .player else {
            statusText = "当前不是玩家回合。"
            return
        }

        do {
            try engine.useSkill(actorID: actor.id, skill: skill)
            statusText = "\(actor.displayName) 使用\(label)，消耗 \(skill.actionPointCost) AP。"
        } catch {
            statusText = readableError(error)
        }
    }

    private func actorName(_ actorID: String) -> String {
        state.actor(id: actorID)?.displayName ?? actorID
    }

    private func canSpend(actionPointCost: Int) -> Bool {
        guard state.outcome == .ongoing,
              let activeActor,
              activeActor.faction == .player
        else {
            return false
        }
        return activeActor.stats.actionPoints >= actionPointCost
    }

    private func readableError(_ error: Error) -> String {
        guard let battleError = error as? BattleActionError else {
            return "行动失败。"
        }

        switch battleError {
        case .battleAlreadyEnded(_):
            return "战斗已经结束。"
        case .noActiveActor:
            return "没有可行动角色。"
        case .actorNotFound(_):
            return "没有找到角色。"
        case .notActorsTurn(_, _):
            return "当前不是该角色的回合。"
        case let .insufficientActionPoints(required, available):
            return "AP 不足：需要 \(required)，当前 \(available)。"
        }
    }
}
