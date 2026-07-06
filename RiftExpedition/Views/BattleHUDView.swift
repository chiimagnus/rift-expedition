import RiftCore
import SwiftUI

struct BattleHUDView: View {
    let viewModel: BattleViewModel
    let onFinishBattle: () -> Void
    let onReturnToMenu: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            actionPanel
            actorList

            Text(viewModel.statusText)
                .font(.callout.weight(.semibold))
                .foregroundStyle(RiftPalette.bannerRed)
        }
        .padding(18)
        .frame(width: 420, alignment: .leading)
        .riftParchmentPanel(cornerRadius: 20)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("战斗")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(RiftPalette.textBrown)

                Text("第 \(viewModel.state.round) 回合 · \(viewModel.outcomeText)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RiftPalette.textBrownLight)
            }

            if viewModel.state.outcome == .victory {
                Spacer()
                Button("返回探索", action: onFinishBattle)
                    .buttonStyle(RiftPrimaryButtonStyle())
                    .accessibilityLabel("返回探索")
            }
        }
    }

    private var actorList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("行动顺序")
                .font(.headline)
                .foregroundStyle(RiftPalette.textBrown)

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
                    .font(.title3.weight(.bold))
                    .foregroundStyle(RiftPalette.textBrown)

                Text("AP \(activeActor.stats.actionPoints)/\(activeActor.stats.maxActionPoints)")
                    .monospacedDigit()
                    .foregroundStyle(RiftPalette.textBrownLight)
            } else {
                Text("没有可行动角色")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(RiftPalette.textBrown)
            }

            Text(viewModel.targetPrompt)
                .font(.callout)
                .foregroundStyle(RiftPalette.textBrownLight)

            Text("当前意图：\(viewModel.selectedActionText)")
                .font(.caption.weight(.bold))
                .foregroundStyle(RiftPalette.bannerRed)

            HStack {
                Button("移动") {
                    viewModel.selectMove()
                }
                .disabled(!viewModel.canMove())
                .accessibilityLabel("选择移动行动")

                Button("普攻") {
                    viewModel.selectBasicAttack()
                }
                .disabled(!viewModel.canPerformBasicAttack)
                .accessibilityLabel("选择普通攻击")

                Menu("消耗品") {
                    if viewModel.consumableRows.isEmpty {
                        Text("背包中没有可用消耗品")
                    } else {
                        ForEach(viewModel.consumableRows) { item in
                            Button("\(item.displayName) 数量 \(item.count) · \(item.actionPointCost) AP") {
                                viewModel.selectConsumable(id: item.id)
                            }
                            .accessibilityLabel("选择消耗品 \(item.displayName)，需要 \(item.actionPointCost) AP")
                        }
                    }
                }
                .accessibilityLabel("选择战斗消耗品")
            }
            .buttonStyle(RiftSecondaryButtonStyle())

            VStack(alignment: .leading, spacing: 8) {
                Text("技能")
                    .font(.headline)
                    .foregroundStyle(RiftPalette.textBrown)

                ForEach(viewModel.activeSkills) { skill in
                    Button("\(skill.displayName) · \(skill.actionPointCost) AP") {
                        viewModel.performSkill(id: skill.id)
                    }
                    .disabled(!viewModel.canUseSkill(skill))
                    .accessibilityLabel("使用技能 \(skill.displayName)，需要 \(skill.actionPointCost) AP")
                }
            }
            .buttonStyle(RiftSecondaryButtonStyle())

            HStack {
                Button("结束回合") {
                    viewModel.endTurn()
                }
                .buttonStyle(RiftPrimaryButtonStyle())
                .disabled(!viewModel.canEndTurn)
                .keyboardShortcut(.defaultAction)
                .accessibilityLabel("结束当前角色回合")

                Button("返回主菜单", action: onReturnToMenu)
                    .buttonStyle(RiftSecondaryButtonStyle())
                    .accessibilityLabel("返回主菜单")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RiftPalette.parchmentShade.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(RiftPalette.outline.opacity(0.4), lineWidth: 1.5)
                )
        )
    }

    private func actorRow(_ actor: Actor) -> some View {
        let isActive = actor.id == viewModel.state.activeActorID

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(actor.displayName)
                    .font(.callout.weight(.bold))
                Text(factionName(actor.faction))
                    .font(.caption)
                    .foregroundStyle(RiftPalette.textBrownLight)
            }

            Spacer()

            Text("生命 \(actor.stats.health)/\(actor.stats.maxHealth)")
                .font(.caption.monospacedDigit())

            Text("AP \(actor.stats.actionPoints)")
                .font(.caption.monospacedDigit())
        }
        .foregroundStyle(RiftPalette.textBrown)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isActive ? RiftPalette.accentGreen.opacity(0.35) : RiftPalette.parchment)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isActive ? RiftPalette.accentGreenDark : RiftPalette.outline.opacity(0.35), lineWidth: isActive ? 2 : 1.5)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(actor.displayName)，\(factionName(actor.faction))，生命 \(actor.stats.health)/\(actor.stats.maxHealth)，AP \(actor.stats.actionPoints)")
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
