import CoreGraphics
import Observation
import RiftCore

enum BattleActionChoice: Equatable {
    case move
    case basicAttack
    case skill(String)
    case consumable(String)
}

enum BattleEffectStyle: String, Equatable {
    case strike
    case projectile
    case arcane
    case fire
    case poison
    case heal
}

enum BattleFeedback: Equatable {
    case damage(amount: Int, defeated: Bool)
    case healing(amount: Int)
    case dodge
}

struct BattleConsumableRow: Equatable, Identifiable {
    var id: String
    var displayName: String
    var count: Int
    var actionPointCost: Int
}

struct BattleSurfaceMarker: Equatable, Identifiable {
    var id: String
    var frame: CGRect
    var surfaceType: SurfaceType
    var remainingRounds: Int? = nil
}

struct BattleActorMarker: Equatable, Identifiable {
    var id: String
    var displayName: String
    var factionName: String
    var visualID: String
    var facing: ActorAnimationDirection
    var baseAction: ActorAnimationKind
    var position: CGPoint
    var health: Int
    var maxHealth: Int
    var actionPoints: Int
    var maxActionPoints: Int
    var isActive: Bool
    var isTargetable: Bool
    var isDefeated: Bool
}

struct BattlePresentationEvent: Equatable, Identifiable {
    var id: Int
    var actorID: String
    var action: ActorAnimationKind
    var direction: ActorAnimationDirection
    var targetActorID: String?
    var sourcePoint: CGPoint?
    var effectPoint: CGPoint?
    var effectStyle: BattleEffectStyle?
    var feedback: BattleFeedback?
}

struct BattleSceneSnapshot: Equatable {
    var actors: [BattleActorMarker]
    var surfaces: [BattleSurfaceMarker]
    var activeActorID: String?
    var selectedAction: BattleActionChoice
    var moveRadius: CGFloat
    var presentationEvents: [BattlePresentationEvent]
}

@MainActor
@Observable
final class BattleViewModel {
    private static let pixelsPerBattleUnit: CGFloat = 28
    private static let actorHitRadius: CGFloat = 34

    private var engine: BattleEngine
    private let skillDefinitions: [SkillDefinition]
    private let skillsByID: [String: SkillDefinition]
    private let itemDefinitions: [ItemDefinition]
    private let hasLineOfSight: (CGPoint, CGPoint) -> Bool
    private let isMovementAllowed: (CGPoint, CGPoint) -> Bool
    private let onAudioCue: (AudioCue) -> Void
    private var random = SeededRandomSource(seed: 20260706)

    var selectedAction: BattleActionChoice = .move
    var statusText = "战斗开始。"
    var targetPrompt = "选择移动位置，或先选择技能再点敌人。"
    var actorPositions: [String: CGPoint]
    var actorFacings: [String: ActorAnimationDirection]
    var surfaces: [BattleSurfaceMarker]
    var inventory: PartyInventory
    private var nextPresentationEventID = 1
    private var nextDynamicSurfaceSequence = 1
    private var presentationEvents: [BattlePresentationEvent] = []

    init(
        state: BattleState,
        skills: [SkillDefinition],
        inventory: PartyInventory = PartyInventory(),
        itemDefinitions: [ItemDefinition] = [],
        initialPositions: [String: CGPoint] = [:],
        surfaces: [BattleSurfaceMarker] = [],
        hasLineOfSight: @escaping (CGPoint, CGPoint) -> Bool = { _, _ in true },
        isMovementAllowed: @escaping (CGPoint, CGPoint) -> Bool = { _, _ in true },
        onAudioCue: @escaping (AudioCue) -> Void = { _ in }
    ) {
        engine = BattleEngine(state: state)
        skillDefinitions = skills
        var indexedSkills: [String: SkillDefinition] = [:]
        for skill in skills where indexedSkills[skill.id] == nil {
            indexedSkills[skill.id] = skill
        }
        skillsByID = indexedSkills
        self.itemDefinitions = itemDefinitions
        actorPositions = Self.makeInitialPositions(for: state.actors, overrides: initialPositions)
        actorFacings = state.actors.reduce(into: [:]) { facings, actor in
            if facings[actor.id] == nil {
                facings[actor.id] = .down
            }
        }
        self.inventory = inventory
        self.surfaces = surfaces
        self.hasLineOfSight = hasLineOfSight
        self.isMovementAllowed = isMovementAllowed
        self.onAudioCue = onAudioCue
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

    var selectedActionText: String {
        switch selectedAction {
        case .move:
            "移动"
        case .basicAttack:
            "普攻"
        case let .skill(id):
            skillsByID[id]?.displayName ?? "技能"
        case let .consumable(id):
            consumableItem(id: id)?.displayName ?? "消耗品"
        }
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

    var sceneSnapshot: BattleSceneSnapshot {
        BattleSceneSnapshot(
            actors: state.actors.map { actor in
                let visualID = ActorVisualIDResolver.visualID(for: actor)
                return BattleActorMarker(
                    id: actor.id,
                    displayName: actor.displayName,
                    factionName: factionName(actor.faction),
                    visualID: visualID,
                    facing: actorFacings[actor.id] ?? .down,
                    baseAction: .idle,
                    position: actorPositions[actor.id] ?? .zero,
                    health: actor.stats.health,
                    maxHealth: actor.stats.maxHealth,
                    actionPoints: actor.stats.actionPoints,
                    maxActionPoints: actor.stats.maxActionPoints,
                    isActive: actor.id == state.activeActorID,
                    isTargetable: canTarget(actor),
                    isDefeated: actor.stats.health <= 0
                )
            },
            surfaces: surfaces,
            activeActorID: state.activeActorID,
            selectedAction: selectedAction,
            moveRadius: moveRadius,
            presentationEvents: presentationEvents
        )
    }

    func acknowledgePresentationEvents(through eventID: Int) {
        presentationEvents.removeAll { $0.id <= eventID }
    }

    var consumableRows: [BattleConsumableRow] {
        itemDefinitions
            .filter { $0.kind == .consumable && inventory.count(of: $0.id) > 0 }
            .compactMap { item in
                guard let skillID = item.skillID, let skill = skillsByID[skillID] else { return nil }
                return BattleConsumableRow(
                    id: item.id,
                    displayName: item.displayName,
                    count: inventory.count(of: item.id),
                    actionPointCost: skill.actionPointCost
                )
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
        targetPrompt = "点击场景内的可达位置移动。"
    }

    func performMove(distance: Double = APRules.movementDistancePerAPStartingValue) {
        guard let actor = activeActor, let start = actorPositions[actor.id] else {
            statusText = "没有可行动角色。"
            return
        }
        performMove(to: CGPoint(x: start.x + CGFloat(distance) * Self.pixelsPerBattleUnit, y: start.y))
    }

    func performMove(to destination: CGPoint) {
        selectedAction = .move
        guard let actor = activeActor else {
            statusText = "没有可行动角色。"
            return
        }
        guard actor.faction == .player else {
            statusText = "当前不是玩家回合。"
            return
        }
        guard let start = actorPositions[actor.id] else {
            statusText = "没有找到角色位置。"
            return
        }

        guard isMovementAllowed(start, destination) else {
            statusText = "目标位置不可达。"
            return
        }

        let distance = battleDistance(from: start, to: destination)
        do {
            try engine.move(actorID: actor.id, distance: distance)
            actorPositions[actor.id] = destination
            emitMovementEvent(actorID: actor.id, from: start, to: destination)
            let enteredSurface = applySurfaceAtDestination(actorID: actor.id, point: destination)
            statusText = "\(actor.displayName) 移动，消耗 \(APRules.movementCost(forDistance: distance)) AP。\(surfaceEntryText(enteredSurface))"
            targetPrompt = "可继续移动、选择技能或结束回合。"
        } catch {
            statusText = readableError(error)
        }
    }

    func selectBasicAttack() {
        selectedAction = .basicAttack
        targetPrompt = "点击红色描边的敌人进行普攻。"
    }

    func performBasicAttack() {
        selectBasicAttack()
    }

    func performSkill(id: String) {
        guard let skill = skillsByID[id] else {
            statusText = "没有找到技能。"
            return
        }
        guard let actor = activeActor else {
            statusText = "没有可行动角色。"
            return
        }
        guard actor.faction == .player else {
            statusText = "当前不是玩家回合。"
            return
        }
        guard actor.skillIDs.contains(id) else {
            statusText = "当前角色尚未掌握该技能。"
            return
        }
        guard actor.stats.actionPoints >= skill.actionPointCost else {
            statusText = readableError(BattleActionError.insufficientActionPoints(
                required: skill.actionPointCost,
                available: actor.stats.actionPoints
            ))
            return
        }

        selectedAction = .skill(id)
        targetPrompt = "点击目标释放「\(skill.displayName)」。"
    }

    func selectConsumable(id: String) {
        guard let item = consumableItem(id: id), let skillID = item.skillID, let skill = skillsByID[skillID] else {
            statusText = "没有找到消耗品配置。"
            return
        }
        guard inventory.count(of: id) > 0 else {
            statusText = "背包中没有该消耗品。"
            return
        }
        guard let actor = activeActor, actor.faction == .player else {
            statusText = "当前不是玩家回合。"
            return
        }
        guard actor.stats.actionPoints >= skill.actionPointCost else {
            statusText = readableError(BattleActionError.insufficientActionPoints(
                required: skill.actionPointCost,
                available: actor.stats.actionPoints
            ))
            return
        }

        selectedAction = .consumable(id)
        targetPrompt = consumableTargetPrompt(itemName: item.displayName, skill: skill)
    }

    func handleWorldClick(_ point: CGPoint) {
        guard state.outcome == .ongoing else { return }

        if selectedAction == .move {
            performMove(to: point)
            return
        }

        guard let targetID = actorID(at: point) else {
            statusText = "没有选中目标。"
            return
        }
        performSelectedAction(targetID: targetID)
    }

    func performSelectedAction(targetID: String) {
        guard let skill = selectedSkill else {
            statusText = "请先选择技能。"
            return
        }
        perform(skill: skill, targetID: targetID, label: skill.displayName, action: selectedAction)
    }

    func endTurn() {
        do {
            try advanceTurn()
            if let enemyStatus = performEnemyTurnsIfNeeded() {
                statusText = enemyStatus
            } else if let activeActor {
                statusText = "轮到 \(activeActor.displayName)。"
            } else {
                statusText = "回合结束。"
            }
            selectedAction = .move
            targetPrompt = "选择行动。"
        } catch {
            statusText = readableError(error)
        }
    }

    private var selectedSkill: SkillDefinition? {
        switch selectedAction {
        case .move:
            return nil
        case .basicAttack:
            return activeSkills.first
        case let .skill(id):
            guard let activeActor, activeActor.skillIDs.contains(id) else { return nil }
            return skillsByID[id]
        case let .consumable(id):
            return consumableItem(id: id)?.skillID.flatMap { skillsByID[$0] }
        }
    }

    private var moveRadius: CGFloat {
        guard let actor = activeActor, actor.faction == .player else { return 0 }
        return CGFloat(actor.stats.actionPoints) * CGFloat(APRules.movementDistancePerAPStartingValue) * Self.pixelsPerBattleUnit
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
                context: EnemyAIContext(
                    skills: skillDefinitions,
                    distancesByTargetID: distances(from: actor),
                    lineOfSightByTargetID: lineOfSight(from: actor),
                    movementDistance: APRules.movementDistancePerAPStartingValue
                )
            )
            lastStatus = performEnemyAction(action, actor: actor)
            guard state.outcome == .ongoing else { break }

            do {
                try advanceTurn()
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
                let result = try performEnemyMove(actorID: actor.id, targetID: targetID, distance: distance, movingAway: false)
                guard result.moved else {
                    return "\(actor.displayName) 的前路被阻挡。"
                }
                return "\(actor.displayName) 逼近 \(actorName(targetID))。\(surfaceEntryText(result.surface))"
            case let .moveAway(targetID, distance):
                let result = try performEnemyMove(actorID: actor.id, targetID: targetID, distance: distance, movingAway: true)
                guard result.moved else {
                    return "\(actor.displayName) 无法继续后撤。"
                }
                return "\(actor.displayName) 与 \(actorName(targetID)) 拉开距离。\(surfaceEntryText(result.surface))"
            case let .useSkill(skillID, targetID):
                guard let skill = skillsByID[skillID] else {
                    return "\(actor.displayName) 没有找到可用技能。"
                }
                return perform(
                    skill: skill,
                    targetID: targetID,
                    label: skill.displayName,
                    action: .skill(skill.id)
                )
            case .endTurn:
                return "\(actor.displayName) 结束回合。"
            }
        } catch {
            return readableError(error)
        }
    }

    @discardableResult
    private func perform(
        skill: SkillDefinition,
        targetID: String,
        label: String,
        action: BattleActionChoice
    ) -> String {
        guard let actor = activeActor else {
            statusText = "没有可行动角色。"
            return statusText
        }
        guard actor.faction != .player || actor.id == state.activeActorID else {
            statusText = "当前不是该角色的回合。"
            return statusText
        }
        guard let target = state.actor(id: targetID) else {
            statusText = "没有找到目标。"
            return statusText
        }
        if case let .consumable(itemID) = action, inventory.count(of: itemID) <= 0 {
            statusText = "背包中没有该消耗品。"
            return statusText
        }
        guard target.stats.health > 0 else {
            statusText = "该目标已经无法行动。"
            return statusText
        }
        guard let casterPosition = actorPositions[actor.id], let targetPosition = actorPositions[targetID] else {
            statusText = "没有找到目标位置。"
            return statusText
        }

        let context = TargetingContext(
            distance: battleDistance(from: casterPosition, to: targetPosition),
            hasLineOfSight: hasLineOfSight(casterPosition, targetPosition)
        )
        let beforeHealth = target.stats.health
        do {
            let resolution = try engine.useSkill(
                actorID: actor.id,
                targetID: targetID,
                skill: skill,
                context: context,
                random: &random
            )
            let afterHealth = state.actor(id: targetID)?.stats.health ?? beforeHealth
            let damage = max(0, beforeHealth - afterHealth)
            let healing = max(0, afterHealth - beforeHealth)
            let targetWasDefeated = afterHealth <= 0
            let surfaceText = applyCreatedSurfaces(resolution.createdSurfaces, at: targetPosition, targetID: targetID)
            consumeItemIfNeeded(for: action)
            emitSkillEvents(
                actorID: actor.id,
                targetID: targetID,
                action: action,
                skill: skill,
                actorClassID: actor.classID,
                casterPosition: casterPosition,
                targetPosition: targetPosition,
                didDodge: resolution.didDodge,
                damage: damage,
                healing: healing,
                targetWasDefeated: targetWasDefeated
            )
            emitAudioCues(action: action, damage: damage, healing: healing)

            if resolution.didDodge {
                statusText = "\(target.displayName) 闪避了 \(label)。"
            } else if damage > 0 {
                statusText = "\(actor.displayName) 对 \(target.displayName) 使用\(label)，造成 \(damage) 点伤害。\(surfaceText)"
            } else if healing > 0 {
                statusText = "\(actor.displayName) 对 \(target.displayName) 使用\(label)，恢复 \(healing) 点生命。\(surfaceText)"
            } else {
                statusText = "\(actor.displayName) 使用\(label)。\(surfaceText)"
            }
            targetPrompt = state.outcome == .ongoing ? "继续选择行动或结束回合。" : outcomeText
            return statusText
        } catch {
            statusText = readableError(error)
            return statusText
        }
    }

    private func applyCreatedSurfaces(
        _ createdSurfaces: [ResolvedSurfaceEffect],
        at point: CGPoint,
        targetID: String
    ) -> String {
        var messages: [String] = []
        for createdSurface in createdSurfaces {
            guard let incoming = SurfaceType(rawValue: createdSurface.surfaceID) else { continue }
            if let index = surfaces.firstIndex(where: { $0.frame.contains(point) }) {
                let existing = surfaces[index].surfaceType
                if let result = ElementResolver.surfaceAfterApplying(incoming, to: existing) {
                    surfaces[index].surfaceType = result
                    surfaces[index].remainingRounds = createdSurface.durationTurns
                    applySurface(result, to: targetID)
                    if existing == .oil && result == .fire {
                        messages.append("油污被点燃。")
                    }
                }
            } else {
                let frame = CGRect(x: point.x - 28, y: point.y - 28, width: 56, height: 56)
                surfaces.append(BattleSurfaceMarker(
                    id: makeDynamicSurfaceID(),
                    frame: frame,
                    surfaceType: incoming,
                    remainingRounds: createdSurface.durationTurns
                ))
                applySurface(incoming, to: targetID)
            }
        }
        return messages.joined(separator: "")
    }

    private func makeDynamicSurfaceID() -> String {
        while true {
            let candidate = "dynamic_surface_\(nextDynamicSurfaceSequence)"
            nextDynamicSurfaceSequence += 1
            if !surfaces.contains(where: { $0.id == candidate }) {
                return candidate
            }
        }
    }

    private func consumeItemIfNeeded(for action: BattleActionChoice) {
        guard case let .consumable(itemID) = action else { return }
        do {
            try inventory.removeItem(id: itemID)
            if inventory.count(of: itemID) == 0 {
                selectedAction = .move
                targetPrompt = "消耗品已用完，选择下一步行动。"
            }
        } catch {
            statusText = readableError(error)
        }
    }

    private func applySurface(_ surface: SurfaceType, to actorID: String) {
        var currentState = engine.state
        _ = currentState.updateActor(id: actorID) { actor in
            ElementResolver.applySurface(surface, to: &actor)
        }
        engine = BattleEngine(state: currentState)
    }

    private func applySurfaceAtDestination(actorID: String, point: CGPoint) -> SurfaceType? {
        guard let surface = surfaces.first(where: { $0.frame.contains(point) }) else { return nil }
        applySurface(surface.surfaceType, to: actorID)
        return surface.surfaceType
    }

    private func surfaceEntryText(_ surface: SurfaceType?) -> String {
        switch surface {
        case .water:
            "进入水地表。"
        case .oil:
            "进入油地表。"
        case .poison:
            "进入毒性地表。"
        case .fire:
            "进入火焰地表。"
        case nil:
            ""
        }
    }

    private func advanceTurn() throws {
        let previousRound = state.round
        try engine.endTurn()
        if state.round > previousRound {
            surfaces = surfaces.compactMap { surface in
                guard let remainingRounds = surface.remainingRounds else { return surface }
                guard remainingRounds > 1 else { return nil }
                var updated = surface
                updated.remainingRounds = remainingRounds - 1
                return updated
            }
        }
    }

    private func actorID(at point: CGPoint) -> String? {
        state.actors
            .filter { $0.stats.health > 0 }
            .compactMap { actor -> (String, CGFloat)? in
                guard let position = actorPositions[actor.id] else { return nil }
                let distance = hypot(position.x - point.x, position.y - point.y)
                return distance <= Self.actorHitRadius ? (actor.id, distance) : nil
            }
            .min { $0.1 < $1.1 }?
            .0
    }

    private func canTarget(_ actor: Actor) -> Bool {
        guard actor.stats.health > 0,
              let activeActor,
              let skill = selectedSkill,
              let casterPosition = actorPositions[activeActor.id],
              let targetPosition = actorPositions[actor.id]
        else {
            return false
        }
        let context = TargetingContext(
            distance: battleDistance(from: casterPosition, to: targetPosition),
            hasLineOfSight: hasLineOfSight(casterPosition, targetPosition)
        )
        return (try? TargetingRules.validate(
            skill: skill,
            caster: activeActor,
            target: actor,
            context: context
        )) != nil
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

    private func consumableItem(id: String) -> ItemDefinition? {
        itemDefinitions.first { $0.id == id && $0.kind == .consumable }
    }

    private func distances(from actor: Actor) -> [String: Double] {
        guard let origin = actorPositions[actor.id] else { return [:] }
        return state.actors.reduce(into: [:]) { distances, target in
            guard target.id != actor.id,
                  distances[target.id] == nil,
                  let position = actorPositions[target.id]
            else { return }
            distances[target.id] = battleDistance(from: origin, to: position)
        }
    }

    private func lineOfSight(from actor: Actor) -> [String: Bool] {
        guard let origin = actorPositions[actor.id] else { return [:] }
        return state.actors.reduce(into: [:]) { visibility, target in
            guard target.id != actor.id,
                  visibility[target.id] == nil,
                  let position = actorPositions[target.id]
            else { return }
            visibility[target.id] = hasLineOfSight(origin, position)
        }
    }

    private func performEnemyMove(
        actorID: String,
        targetID: String,
        distance: Double,
        movingAway: Bool
    ) throws -> (moved: Bool, surface: SurfaceType?) {
        guard let start = actorPositions[actorID], let target = actorPositions[targetID] else {
            return (false, nil)
        }
        let directionTarget = movingAway
            ? CGPoint(x: start.x + (start.x - target.x), y: start.y + (start.y - target.y))
            : target
        let destination = movedPoint(
            from: start,
            toward: directionTarget,
            distance: CGFloat(distance) * Self.pixelsPerBattleUnit
        )
        guard isMovementAllowed(start, destination) else { return (false, nil) }

        try engine.move(actorID: actorID, distance: distance)
        actorPositions[actorID] = destination
        emitMovementEvent(actorID: actorID, from: start, to: destination)
        let enteredSurface = applySurfaceAtDestination(actorID: actorID, point: destination)
        return (true, enteredSurface)
    }

    private func emitMovementEvent(actorID: String, from start: CGPoint, to end: CGPoint) {
        guard let direction = animationDirection(from: start, to: end) else { return }
        actorFacings[actorID] = direction
        appendPresentationEvent(
            actorID: actorID,
            action: .walk,
            direction: direction,
            targetActorID: nil,
            sourcePoint: nil,
            effectPoint: nil,
            effectStyle: nil,
            feedback: nil
        )
    }

    private func appendPresentationEvent(
        actorID: String,
        action: ActorAnimationKind,
        direction: ActorAnimationDirection,
        targetActorID: String?,
        sourcePoint: CGPoint?,
        effectPoint: CGPoint?,
        effectStyle: BattleEffectStyle?,
        feedback: BattleFeedback?
    ) {
        presentationEvents.append(BattlePresentationEvent(
            id: nextPresentationEventID,
            actorID: actorID,
            action: action,
            direction: direction,
            targetActorID: targetActorID,
            sourcePoint: sourcePoint,
            effectPoint: effectPoint,
            effectStyle: effectStyle,
            feedback: feedback
        ))
        nextPresentationEventID += 1
    }

    private func emitSkillEvents(
        actorID: String,
        targetID: String,
        action: BattleActionChoice,
        skill: SkillDefinition,
        actorClassID: String?,
        casterPosition: CGPoint,
        targetPosition: CGPoint,
        didDodge: Bool,
        damage: Int,
        healing: Int,
        targetWasDefeated: Bool
    ) {
        let attackDirection = animationDirection(from: casterPosition, to: targetPosition)
            ?? actorFacings[actorID]
            ?? .down
        let effectStyle = presentationStyle(for: action, skill: skill, actorClassID: actorClassID)
        let feedback: BattleFeedback? = if didDodge {
            .dodge
        } else if damage > 0 {
            .damage(amount: damage, defeated: targetWasDefeated)
        } else if healing > 0 {
            .healing(amount: healing)
        } else {
            nil
        }

        actorFacings[actorID] = attackDirection
        appendPresentationEvent(
            actorID: actorID,
            action: .attack,
            direction: attackDirection,
            targetActorID: targetID,
            sourcePoint: casterPosition,
            effectPoint: targetPosition,
            effectStyle: effectStyle,
            feedback: feedback
        )

        guard !didDodge, damage > 0 else { return }
        let hurtDirection = animationDirection(from: targetPosition, to: casterPosition)
            ?? actorFacings[targetID]
            ?? .down
        actorFacings[targetID] = hurtDirection
        appendPresentationEvent(
            actorID: targetID,
            action: .hurt,
            direction: hurtDirection,
            targetActorID: actorID,
            sourcePoint: nil,
            effectPoint: nil,
            effectStyle: nil,
            feedback: nil
        )
    }

    private func presentationStyle(
        for action: BattleActionChoice,
        skill: SkillDefinition,
        actorClassID: String?
    ) -> BattleEffectStyle {
        if skill.effects.contains(where: { effect in
            if case .heal = effect { return true }
            return false
        }) {
            return .heal
        }
        if skill.effects.contains(where: { effect in
            switch effect {
            case let .createSurface(surfaceID, _):
                return surfaceID == "poison"
            case let .applyStatus(statusID, _):
                return statusID == "poisoned"
            default:
                return false
            }
        }) {
            return .poison
        }
        if skill.effects.contains(where: { effect in
            switch effect {
            case let .createSurface(surfaceID, _):
                return surfaceID == "fire"
            case let .applyStatus(statusID, _):
                return statusID == "burning"
            default:
                return false
            }
        }) {
            return .fire
        }

        switch action {
        case .move:
            return .strike
        case .basicAttack:
            return skill.range > 3 ? .projectile : .strike
        case .consumable:
            return skill.target == .enemy || skill.range > 3 ? .projectile : .arcane
        case .skill:
            if skill.range > 3.5 || actorClassID == "archer" {
                return .projectile
            }
            if actorClassID == "mage" || skill.id.contains("spark") || skill.id.contains("orb") || skill.id.contains("light") {
                return .arcane
            }
            return .strike
        }
    }

    private func emitAudioCues(action: BattleActionChoice, damage: Int, healing: Int) {
        if case .consumable = action, healing > 0 {
            onAudioCue(.healDrink)
        } else {
            onAudioCue(.skillCast)
        }
        if damage > 0 {
            onAudioCue(.attackHit)
        }
    }

    private func consumableTargetPrompt(itemName: String, skill: SkillDefinition) -> String {
        let targetName = switch skill.target {
        case .selfOnly:
            "当前角色"
        case .ally:
            "队友"
        case .enemy:
            "敌人"
        }
        return "点击\(targetName)使用「\(itemName)」。"
    }

    private func animationDirection(from start: CGPoint, to end: CGPoint) -> ActorAnimationDirection? {
        let dx = end.x - start.x
        let dy = end.y - start.y
        guard abs(dx) > 0.01 || abs(dy) > 0.01 else { return nil }
        if abs(dx) > abs(dy) {
            return dx >= 0 ? .right : .left
        }
        return dy >= 0 ? .up : .down
    }

    private func movedPoint(from start: CGPoint, toward end: CGPoint, distance: CGFloat) -> CGPoint {
        let total = hypot(end.x - start.x, end.y - start.y)
        guard total > distance, total > 0 else { return end }

        return CGPoint(
            x: start.x + (end.x - start.x) / total * distance,
            y: start.y + (end.y - start.y) / total * distance
        )
    }

    private func battleDistance(from start: CGPoint, to end: CGPoint) -> Double {
        Double(hypot(end.x - start.x, end.y - start.y) / Self.pixelsPerBattleUnit)
    }

    private func actorName(_ actorID: String) -> String {
        state.actor(id: actorID)?.displayName ?? actorID
    }

    private func factionName(_ faction: Faction) -> String {
        switch faction {
        case .player:
            "队友"
        case .civilian:
            "村民"
        case .hostile:
            "敌人"
        case .animal:
            "动物"
        case .monster:
            "怪物"
        }
    }

    private func readableError(_ error: Error) -> String {
        switch error {
        case let battleError as BattleActionError:
            return readableBattleError(battleError)
        case let targetingError as TargetingError:
            return readableTargetingError(targetingError)
        case let inventoryError as InventoryError:
            return readableInventoryError(inventoryError)
        default:
            return "行动失败。"
        }
    }

    private func readableBattleError(_ error: BattleActionError) -> String {
        switch error {
        case .battleAlreadyEnded(_):
            return "战斗已经结束。"
        case .noActiveActor:
            return "没有可行动角色。"
        case .actorNotFound(_):
            return "没有找到角色。"
        case .notActorsTurn(_, _):
            return "当前不是该角色的回合。"
        case .skillNotKnown:
            return "当前角色尚未掌握该技能。"
        case .invalidActionPointCost:
            return "行动点消耗配置无效。"
        case .invalidMovementDistance:
            return "移动距离必须大于零。"
        case let .insufficientActionPoints(required, available):
            return "AP 不足：需要 \(required)，当前 \(available)。"
        }
    }

    private func readableTargetingError(_ error: TargetingError) -> String {
        switch error {
        case let .outOfRange(maxRange, actual):
            return "距离太远：最大 \(maxRange.formatted(.number.precision(.fractionLength(1))))，当前 \(actual.formatted(.number.precision(.fractionLength(1))))。"
        case .blockedLineOfSight:
            return "视线被障碍挡住。"
        case .invalidSkillTargetConfiguration:
            return "技能目标配置无效。"
        case let .invalidTarget(expected, _):
            switch expected {
            case .selfOnly:
                return "该技能只能以施法者自身为目标。"
            case .ally:
                return "该技能只能以队友为目标。"
            case .enemy:
                return "该技能只能以敌人为目标。"
            }
        }
    }

    private func readableInventoryError(_ error: InventoryError) -> String {
        switch error {
        case let .insufficientQuantity(_, _, available):
            return "消耗品不足：当前 \(available)。"
        }
    }

    private static func makeInitialPositions(for actors: [Actor], overrides: [String: CGPoint]) -> [String: CGPoint] {
        var positions = overrides
        var playerIndex = 0
        var enemyIndex = 0

        for actor in actors where positions[actor.id] == nil {
            if actor.faction == .player {
                positions[actor.id] = CGPoint(x: 360, y: 290 + CGFloat(playerIndex) * 72)
                playerIndex += 1
            } else {
                positions[actor.id] = CGPoint(x: 600 + CGFloat(enemyIndex % 2) * 68, y: 280 + CGFloat(enemyIndex) * 64)
                enemyIndex += 1
            }
        }
        return positions
    }

}
