import RiftCore
import SwiftUI

struct BattleHUDView: View {
    let viewModel: BattleViewModel
    let onFinishBattle: () -> Void
    let onReturnToMenu: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            battleHeader
            Spacer(minLength: 12)
            HStack(alignment: .bottom, spacing: 14) {
                activeActorPanel
                commandDeck
                combatIntelPanel
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var battleHeader: some View {
        HStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(RiftPalette.danger.opacity(0.14))
                        .overlay(Circle().stroke(RiftPalette.danger.opacity(0.65), lineWidth: 1.2))
                    Image(systemName: "burst.fill")
                        .foregroundStyle(RiftPalette.danger)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("战术接触")
                        .font(.caption2.weight(.black))
                        .tracking(1.5)
                        .foregroundStyle(RiftPalette.danger)
                    Text("第 \(viewModel.state.round) 回合 · \(viewModel.outcomeText)")
                        .font(.headline.weight(.black))
                        .foregroundStyle(RiftPalette.frost)
                }
            }

            Rectangle()
                .fill(RiftPalette.outline.opacity(0.42))
                .frame(width: 1, height: 38)

            initiativeStrip

            Spacer()

            if viewModel.state.outcome == .victory {
                Button {
                    onFinishBattle()
                } label: {
                    Label("收束战场，返回探索", systemImage: "flag.checkered")
                }
                .buttonStyle(RiftPrimaryButtonStyle())
            } else if viewModel.state.outcome == .defeat {
                Button {
                    onReturnToMenu()
                } label: {
                    Label("返回主菜单", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(RiftSecondaryButtonStyle())
            } else {
                RiftStatusPill(text: viewModel.selectedActionText, tint: RiftPalette.riftBlue, icon: "scope")
            }
        }
        .padding(13)
        .riftParchmentPanel(cornerRadius: 16)
    }

    private var initiativeStrip: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.state.actors) { actor in
                let isActive = actor.id == viewModel.state.activeActorID
                let tint = factionTint(actor.faction)

                HStack(spacing: 6) {
                    Circle()
                        .fill(actor.stats.health > 0 ? tint : RiftPalette.steel.opacity(0.38))
                        .frame(width: 7, height: 7)
                        .shadow(color: isActive ? tint.opacity(0.65) : .clear, radius: 6)
                    Text(actor.displayName)
                        .font(.caption2.weight(isActive ? .black : .semibold))
                        .foregroundStyle(isActive ? RiftPalette.frost : RiftPalette.textBrownLight)
                        .lineLimit(1)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isActive ? tint.opacity(0.18) : RiftPalette.void.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(isActive ? tint.opacity(0.85) : RiftPalette.outline.opacity(0.24), lineWidth: isActive ? 1.3 : 1)
                        )
                )
                .opacity(actor.stats.health > 0 ? 1 : 0.42)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("行动顺序")
    }

    private var activeActorPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            RiftSectionHeader("行动角色", eyebrow: "ACTIVE UNIT", systemImage: "person.fill.viewfinder")

            if let actor = viewModel.activeActor {
                HStack(spacing: 12) {
                    RiftActorPortrait(classID: actor.classID, size: 72, isActive: true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(actor.displayName)
                            .font(.title3.weight(.black))
                            .foregroundStyle(RiftPalette.frost)
                        Text(factionName(actor.faction))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(factionTint(actor.faction))
                        Text("等级 \(actor.level)")
                            .font(.caption2.monospaced().weight(.semibold))
                            .foregroundStyle(RiftPalette.textBrownLight)
                    }
                }

                statGauge(
                    title: "生命",
                    valueText: "\(actor.stats.health) / \(actor.stats.maxHealth)",
                    ratio: actor.stats.maxHealth == 0 ? 0 : Double(actor.stats.health) / Double(actor.stats.maxHealth),
                    tint: healthTint(actor)
                )

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("行动点")
                        Spacer()
                        Text("\(actor.stats.actionPoints) / \(actor.stats.maxActionPoints) AP")
                            .monospacedDigit()
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RiftPalette.textBrownLight)

                    HStack(spacing: 5) {
                        ForEach(0..<max(actor.stats.maxActionPoints, 1), id: \.self) { index in
                            Capsule()
                                .fill(index < actor.stats.actionPoints ? RiftPalette.ember : RiftPalette.void.opacity(0.72))
                                .overlay(Capsule().stroke(RiftPalette.ember.opacity(index < actor.stats.actionPoints ? 0.7 : 0.18), lineWidth: 1))
                                .frame(height: 8)
                        }
                    }
                }

                HStack(spacing: 8) {
                    RiftStatusPill(text: "攻 \(actor.stats.attack)", tint: RiftPalette.ember)
                    RiftStatusPill(text: "防 \(actor.stats.defense)", tint: RiftPalette.riftBlue)
                    RiftStatusPill(text: "闪 \(actor.stats.evasion)", tint: RiftPalette.riftViolet)
                }
            } else {
                Text("等待行动序列结算。")
                    .foregroundStyle(RiftPalette.textBrownLight)
            }
        }
        .padding(16)
        .frame(width: 250, alignment: .leading)
        .riftParchmentPanel(cornerRadius: 17)
    }

    private var commandDeck: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("战术指令")
                        .font(.caption2.weight(.black))
                        .tracking(1.4)
                        .foregroundStyle(RiftPalette.riftBlue)
                    Text(viewModel.targetPrompt)
                        .font(.callout.weight(.bold))
                        .foregroundStyle(RiftPalette.frost)
                        .lineLimit(2)
                }
                Spacer()
                RiftStatusPill(text: "当前：\(viewModel.selectedActionText)", tint: RiftPalette.riftViolet)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    actionButton(
                        title: "移动",
                        subtitle: "按距离耗 AP",
                        icon: "figure.walk",
                        tint: RiftPalette.riftBlue,
                        selected: viewModel.selectedAction == .move,
                        enabled: viewModel.canMove(),
                        action: viewModel.selectMove
                    )

                    actionButton(
                        title: "普攻",
                        subtitle: "基础技能",
                        icon: "burst.fill",
                        tint: RiftPalette.ember,
                        selected: viewModel.selectedAction == .basicAttack,
                        enabled: viewModel.canPerformBasicAttack,
                        action: viewModel.selectBasicAttack
                    )

                    ForEach(viewModel.activeSkills) { skill in
                        skillActionButton(skill)
                    }

                    consumableMenu
                }
                .padding(.vertical, 2)
            }

            HStack(spacing: 10) {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusTint)
                Text(viewModel.statusText)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(RiftPalette.textBrown)
                    .lineLimit(2)
                Spacer()
                Button {
                    viewModel.endTurn()
                } label: {
                    Label("结束回合", systemImage: "forward.end.fill")
                }
                .buttonStyle(RiftPrimaryButtonStyle())
                .disabled(!viewModel.canEndTurn)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .riftParchmentPanel(cornerRadius: 17)
    }

    private var combatIntelPanel: some View {
        VStack(alignment: .leading, spacing: 11) {
            RiftSectionHeader("战场态势", eyebrow: "COMBAT INTEL", systemImage: "dot.scope")

            ForEach(viewModel.state.actors) { actor in
                actorIntelRow(actor)
            }

            Rectangle()
                .fill(RiftPalette.outline.opacity(0.28))
                .frame(height: 1)

            Button {
                onReturnToMenu()
            } label: {
                Label("放弃本次远征", systemImage: "rectangle.portrait.and.arrow.right")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(RiftGhostButtonStyle())
        }
        .padding(16)
        .frame(width: 274, alignment: .leading)
        .riftParchmentPanel(cornerRadius: 17)
    }

    private var consumableMenu: some View {
        Menu {
            if viewModel.consumableRows.isEmpty {
                Text("背包中没有可用消耗品")
            } else {
                ForEach(viewModel.consumableRows) { item in
                    Button("\(item.displayName) ×\(item.count) · \(item.actionPointCost) AP") {
                        viewModel.selectConsumable(id: item.id)
                    }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "cross.case.fill")
                        .foregroundStyle(RiftPalette.success)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(RiftPalette.textBrownLight)
                }
                Text("消耗品")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(RiftPalette.textBrown)
                Text(viewModel.consumableRows.isEmpty ? "背包为空" : "战斗补给")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RiftPalette.textBrownLight)
            }
            .padding(11)
            .frame(width: 126, height: 86, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(RiftPalette.parchmentShade)
                    .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(RiftPalette.outline.opacity(0.45), lineWidth: 1))
            )
        }
        .menuStyle(.borderlessButton)
        .disabled(viewModel.consumableRows.isEmpty)
    }

    private func skillActionButton(_ skill: SkillDefinition) -> some View {
        let subtitle = skillSubtitle(for: skill)
        let icon = RiftSkillIconography.icon(for: skill.id)
        let tint = RiftSkillIconography.tint(for: skill.id)
        let isSelected = viewModel.selectedAction == .skill(skill.id)
        let isEnabled = viewModel.canUseSkill(skill)

        return actionButton(
            title: skill.displayName,
            subtitle: subtitle,
            icon: icon,
            tint: tint,
            selected: isSelected,
            enabled: isEnabled
        ) {
            viewModel.performSkill(id: skill.id)
        }
    }

    private func skillSubtitle(for skill: SkillDefinition) -> String {
        let rangeText = skill.range.formatted(.number.precision(.fractionLength(0)))
        return "\(skill.actionPointCost) AP · \(rangeText) 距离"
    }

    private func actionButton(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        selected: Bool,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(tint)
                    Spacer()
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(tint)
                    }
                }
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(RiftPalette.textBrown)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RiftPalette.textBrownLight)
                    .lineLimit(1)
            }
            .padding(11)
            .frame(width: 126, height: 86, alignment: .leading)
        }
        .buttonStyle(RiftActionButtonStyle(isSelected: selected, tint: tint))
        .disabled(!enabled)
        .accessibilityLabel("\(title)，\(subtitle)")
    }

    private func actorIntelRow(_ actor: Actor) -> some View {
        let active = actor.id == viewModel.state.activeActorID
        let tint = factionTint(actor.faction)

        return HStack(spacing: 9) {
            ZStack {
                Circle().fill(tint.opacity(0.16))
                Image(systemName: actor.faction == .player ? "person.fill" : "exclamationmark.triangle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(actor.displayName)
                        .font(.caption.weight(active ? .black : .bold))
                        .foregroundStyle(active ? RiftPalette.frost : RiftPalette.textBrown)
                        .lineLimit(1)
                    Spacer()
                    Text("\(actor.stats.health)")
                        .font(.caption2.monospacedDigit().weight(.bold))
                        .foregroundStyle(RiftPalette.textBrownLight)
                }
                RiftMetricBar(
                    value: actor.stats.maxHealth == 0 ? 0 : Double(actor.stats.health) / Double(actor.stats.maxHealth),
                    tint: healthTint(actor),
                    height: 4
                )
            }
        }
        .padding(7)
        .background(active ? tint.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(active ? tint.opacity(0.48) : .clear, lineWidth: 1)
        )
        .opacity(actor.stats.health > 0 ? 1 : 0.38)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(actor.displayName)，\(factionName(actor.faction))，生命 \(actor.stats.health)/\(actor.stats.maxHealth)，AP \(actor.stats.actionPoints)")
    }

    private func statGauge(title: String, valueText: String, ratio: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                Spacer()
                Text(valueText).monospacedDigit()
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(RiftPalette.textBrownLight)
            RiftMetricBar(value: ratio, tint: tint, height: 7)
        }
    }

    private var statusIcon: String {
        if viewModel.state.outcome == .victory { return "checkmark.seal.fill" }
        if viewModel.state.outcome == .defeat { return "xmark.octagon.fill" }
        return "waveform.path.ecg"
    }

    private var statusTint: Color {
        if viewModel.state.outcome == .victory { return RiftPalette.success }
        if viewModel.state.outcome == .defeat { return RiftPalette.danger }
        return RiftPalette.riftBlue
    }

    private func healthTint(_ actor: Actor) -> Color {
        guard actor.stats.maxHealth > 0 else { return RiftPalette.danger }
        let ratio = Double(actor.stats.health) / Double(actor.stats.maxHealth)
        if ratio < 0.3 { return RiftPalette.danger }
        if ratio < 0.6 { return RiftPalette.ember }
        return RiftPalette.success
    }

    private func factionTint(_ faction: Faction) -> Color {
        switch faction {
        case .player:
            RiftPalette.riftBlue
        case .civilian:
            RiftPalette.success
        case .hostile:
            RiftPalette.danger
        case .animal:
            RiftPalette.ember
        case .monster:
            RiftPalette.riftViolet
        }
    }

    private func factionName(_ faction: Faction) -> String {
        switch faction {
        case .player:
            "远征队"
        case .civilian:
            "平民"
        case .hostile:
            "敌对者"
        case .animal:
            "野兽"
        case .monster:
            "裂隙生物"
        }
    }
}
