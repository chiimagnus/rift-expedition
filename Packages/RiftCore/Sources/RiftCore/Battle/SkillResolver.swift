public enum SkillResolver {
    public static func resolve<R: RandomSource>(
        skill: SkillDefinition,
        casterID: String,
        targetID: String,
        context: TargetingContext,
        in state: inout BattleState,
        random: inout R
    ) throws -> SkillResolution {
        try TargetingRules.validate(skill: skill, context: context)
        guard state.actor(id: casterID) != nil else {
            throw BattleActionError.actorNotFound(casterID)
        }
        guard let target = state.actor(id: targetID) else {
            throw BattleActionError.actorNotFound(targetID)
        }

        if skill.canBeDodged && random.roll(chancePercent: target.stats.evasion) {
            return SkillResolution(didDodge: true)
        }

        var resolution = SkillResolution()
        for effect in skill.effects {
            apply(effect, targetID: targetID, state: &state, resolution: &resolution)
        }
        return resolution
    }

    private static func apply(
        _ effect: SkillEffect,
        targetID: String,
        state: inout BattleState,
        resolution: inout SkillResolution
    ) {
        switch effect {
        case let .damage(amount):
            _ = state.updateActor(id: targetID) { actor in
                let damage = max(0, amount - actor.stats.defense)
                actor.stats.health = max(0, actor.stats.health - damage)
            }
        case let .heal(amount):
            _ = state.updateActor(id: targetID) { actor in
                actor.stats.health = min(actor.stats.maxHealth, actor.stats.health + max(0, amount))
            }
        case let .applyStatus(statusID, _):
            resolution.appliedStatuses.append(statusID)
        case let .createSurface(surfaceID, _):
            resolution.createdSurfaces.append(surfaceID)
        case let .move(distance):
            resolution.movedDistance += distance
        case let .summon(actorID):
            resolution.summonedActorIDs.append(actorID)
        }
    }
}
