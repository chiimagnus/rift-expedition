import XCTest
@testable import RiftCore

final class SkillResolverTests: XCTestCase {
    func testBasicAttackDealsDamage() throws {
        var state = BattleState(actors: [
            makeActor(id: "hero", faction: .player),
            makeActor(id: "wolf", faction: .animal, defense: 2)
        ])
        var random = SeededRandomSource(seed: 7)

        _ = try SkillResolver.resolve(
            skill: damageSkill(canBeDodged: false),
            casterID: "hero",
            targetID: "wolf",
            context: TargetingContext(distance: 1, hasLineOfSight: true, isAlly: false),
            in: &state,
            random: &random
        )

        XCTAssertEqual(state.actor(id: "wolf")?.stats.health, 14)
    }

    func testHealRestoresHealthWithoutOverhealing() throws {
        var state = BattleState(actors: [
            makeActor(id: "hero", faction: .player, health: 10)
        ])
        var random = SeededRandomSource(seed: 7)
        let heal = SkillDefinition(
            id: "mend",
            displayName: "包扎",
            actionPointCost: 1,
            range: 4,
            target: .ally,
            affectsAllies: true,
            canBeDodged: false,
            effects: [.heal(20)]
        )

        _ = try SkillResolver.resolve(
            skill: heal,
            casterID: "hero",
            targetID: "hero",
            context: TargetingContext(distance: 0, hasLineOfSight: true, isAlly: true),
            in: &state,
            random: &random
        )

        XCTAssertEqual(state.actor(id: "hero")?.stats.health, 20)
    }

    func testFriendlyFireIsBlockedWhenAffectsAlliesIsFalse() throws {
        var state = BattleState(actors: [
            makeActor(id: "hero", faction: .player),
            makeActor(id: "ally", faction: .player)
        ])
        var random = SeededRandomSource(seed: 7)

        XCTAssertThrowsError(try SkillResolver.resolve(
            skill: damageSkill(canBeDodged: false),
            casterID: "hero",
            targetID: "ally",
            context: TargetingContext(distance: 1, hasLineOfSight: true, isAlly: true),
            in: &state,
            random: &random
        )) { error in
            XCTAssertEqual(error as? TargetingError, .allyNotAllowed)
        }
    }

    func testDodgedSkillAppliesNoDamageWithFixedSeed() throws {
        var state = BattleState(actors: [
            makeActor(id: "hero", faction: .player),
            makeActor(id: "rogue", faction: .hostile, evasion: 100)
        ])
        var random = SeededRandomSource(seed: 7)

        let resolution = try SkillResolver.resolve(
            skill: damageSkill(canBeDodged: true),
            casterID: "hero",
            targetID: "rogue",
            context: TargetingContext(distance: 1, hasLineOfSight: true, isAlly: false),
            in: &state,
            random: &random
        )

        XCTAssertTrue(resolution.didDodge)
        XCTAssertEqual(state.actor(id: "rogue")?.stats.health, 20)
    }

    private func damageSkill(canBeDodged: Bool) -> SkillDefinition {
        SkillDefinition(
            id: "slash",
            displayName: "劈砍",
            actionPointCost: 2,
            range: 1.5,
            target: .enemy,
            affectsAllies: false,
            canBeDodged: canBeDodged,
            effects: [.damage(8)]
        )
    }

    private func makeActor(
        id: String,
        faction: Faction,
        health: Int = 20,
        defense: Int = 0,
        evasion: Int = 0
    ) -> Actor {
        Actor(
            id: id,
            displayName: id,
            kind: faction == .player ? .player : .humanEnemy,
            faction: faction,
            level: 1,
            stats: Stats(
                maxHealth: 20,
                health: health,
                attack: 5,
                defense: defense,
                evasion: evasion,
                magic: 1,
                maxActionPoints: 4,
                actionPoints: 4
            ),
            skillIDs: ["slash"]
        )
    }
}
