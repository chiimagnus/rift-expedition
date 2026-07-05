import RiftCore
import SwiftUI

struct BattleHUDView: View {
    let viewModel: BattleViewModel
    let onFinishBattle: () -> Void
    let onReturnToMenu: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            actionPanel
            actorList

            Text(viewModel.statusText)
                .font(.callout.bold())
                .foregroundStyle(Color(red: 0.84, green: 0.73, blue: 0.42))
        }
        .frame(width: 420, alignment: .leading)
        .padding(20)
        .background(.black.opacity(0.68), in: RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
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

            if viewModel.state.outcome == .victory {
                Spacer()
                Button("返回探索", action: onFinishBattle)
                    .buttonStyle(.borderedProminent)
            }
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
        .frame(maxWidth: .infinity, alignment: .leading)
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

            Text("当前意图：\(viewModel.selectedActionText)")
                .font(.caption.bold())
                .foregroundStyle(Color(red: 0.84, green: 0.73, blue: 0.42))

            HStack {
                Button("移动") {
                    viewModel.selectMove()
                }
                .disabled(!viewModel.canMove())

                Button("普攻") {
                    viewModel.selectBasicAttack()
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

            HStack {
                Button("结束回合") {
                    viewModel.endTurn()
                }
                .disabled(!viewModel.canEndTurn)
                .keyboardShortcut(.defaultAction)

                Button("返回主菜单", action: onReturnToMenu)
                    .buttonStyle(.bordered)
            }
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
