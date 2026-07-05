import RiftCore
import SwiftUI

struct BattleHUDView: View {
    let viewModel: BattleViewModel
    let onReturnToMenu: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            HStack(alignment: .top, spacing: 18) {
                actorList
                actionPanel
            }

            Text(viewModel.statusText)
                .font(.callout.bold())
                .foregroundStyle(Color(red: 0.84, green: 0.73, blue: 0.42))
        }
        .frame(maxWidth: 980, alignment: .leading)
        .padding(28)
        .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 22))
        .padding(32)
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text("战斗")
                    .font(.system(size: 44, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                Text("第 \(viewModel.state.round) 回合 · \(viewModel.outcomeText)")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Button("返回主菜单", action: onReturnToMenu)
                .buttonStyle(.bordered)
        }
    }

    private var actorList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("行动顺序")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(viewModel.state.actors) { actor in
                actorRow(actor)
            }
        }
        .frame(maxWidth: 360, alignment: .leading)
    }

    private var actionPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let activeActor = viewModel.activeActor {
                Text("当前：\(activeActor.displayName)")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text("AP \(activeActor.stats.actionPoints)/\(activeActor.stats.maxActionPoints)")
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.76))
            } else {
                Text("没有可行动角色")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }

            Text(viewModel.targetPrompt)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.66))

            HStack {
                Button("移动 1 AP") {
                    viewModel.performMove()
                }
                .disabled(!viewModel.canMove())

                Button("普攻") {
                    viewModel.performBasicAttack()
                }
                .disabled(!viewModel.canPerformBasicAttack)

                Button("消耗品") {
                    viewModel.selectConsumable()
                }
            }
            .buttonStyle(.borderedProminent)

            VStack(alignment: .leading, spacing: 8) {
                Text("技能")
                    .font(.headline)
                    .foregroundStyle(.white)

                ForEach(viewModel.activeSkills) { skill in
                    Button("\(skill.displayName) · \(skill.actionPointCost) AP") {
                        viewModel.performSkill(id: skill.id)
                    }
                    .disabled(!viewModel.canUseSkill(skill))
                }
            }
            .buttonStyle(.bordered)

            Button("结束回合") {
                viewModel.endTurn()
            }
            .disabled(!viewModel.canEndTurn)
            .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }

    private func actorRow(_ actor: Actor) -> some View {
        let isActive = actor.id == viewModel.state.activeActorID

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(actor.displayName)
                    .font(.callout.bold())
                Text(factionName(actor.faction))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()

            Text("HP \(actor.stats.health)/\(actor.stats.maxHealth)")
                .font(.caption.monospacedDigit())

            Text("AP \(actor.stats.actionPoints)")
                .font(.caption.monospacedDigit())
        }
        .foregroundStyle(.white)
        .padding(10)
        .background(isActive ? Color(red: 0.31, green: 0.42, blue: 0.26).opacity(0.85) : Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color(red: 0.84, green: 0.73, blue: 0.42) : Color.white.opacity(0.12), lineWidth: isActive ? 2 : 1)
        )
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
}
