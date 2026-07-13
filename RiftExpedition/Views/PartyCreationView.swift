import RiftCore
import SwiftUI

struct PartyCreationView: View {
    let viewModel: PartyCreationViewModel
    let onConfirm: () -> Void
    let onBack: () -> Void

    var body: some View {
        RiftPanelScaffold(
            title: "组建远征小队",
            subtitle: "选择两名成员。职业只定义起点，不锁定后续装备与技能路线。",
            maxWidth: 1_080
        ) {
            HStack {
                RiftSectionHeader("选择两名能够互补的冒险者", eyebrow: "远征编成", systemImage: "person.2.fill")
                Spacer()
                RiftStatusPill(
                    text: "已选择 \(viewModel.selectedClassIDs.count) / 2",
                    tint: viewModel.canStart ? RiftPalette.success : RiftPalette.riftBlue,
                    icon: viewModel.canStart ? "checkmark.circle.fill" : "circle.dotted"
                )
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 310), spacing: 16)], spacing: 16) {
                ForEach(viewModel.availableClasses) { classDefinition in
                    classCard(classDefinition)
                }
            }

            HStack(spacing: 12) {
                Button {
                    onBack()
                } label: {
                    Label("返回主菜单", systemImage: "chevron.left")
                }
                .buttonStyle(RiftSecondaryButtonStyle())

                Spacer()

                Text(viewModel.canStart ? "编成已锁定，可以进入第一章" : "还需要选择 \(2 - viewModel.selectedClassIDs.count) 名成员")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RiftPalette.muted)

                Button {
                    onConfirm()
                } label: {
                    Label("踏入裂隙村", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(RiftPrimaryButtonStyle())
                .disabled(!viewModel.canStart)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func classCard(_ classDefinition: ClassDefinition) -> some View {
        let selected = viewModel.isSelected(classDefinition.id)
        let disabled = !selected && viewModel.selectedClassIDs.count >= 2
        let tint = RiftClassIconography.tint(for: classDefinition.id)

        return Button {
            viewModel.toggleSelection(classDefinition.id)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    RiftActorPortrait(classID: classDefinition.id, size: 88, isActive: selected)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(classDefinition.title ?? classDefinition.displayName)
                            .font(.title3.weight(.black))
                            .foregroundStyle(RiftPalette.frost)

                        Text("\(viewModel.adventurerName(for: classDefinition.id)) · \(classDefinition.displayName)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(tint)

                        Text(classDefinition.combatRole ?? "战术成员")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RiftPalette.muted)
                    }

                    Spacer()

                    if let order = viewModel.selectionIndex(for: classDefinition.id) {
                        ZStack {
                            Circle().fill(tint)
                            Text("\(order)")
                                .font(.headline.weight(.black))
                                .foregroundStyle(RiftPalette.void)
                        }
                        .frame(width: 30, height: 30)
                        .shadow(color: tint.opacity(0.45), radius: 8)
                    } else {
                        Image(systemName: "plus")
                            .font(.caption.weight(.black))
                            .foregroundStyle(RiftPalette.muted)
                            .frame(width: 30, height: 30)
                            .background(RiftPalette.raised, in: Circle())
                            .overlay(Circle().stroke(RiftPalette.border.opacity(0.5), lineWidth: 1))
                    }
                }

                Text(classDefinition.description ?? "一名准备进入裂隙村的远征者。")
                    .font(.callout)
                    .foregroundStyle(RiftPalette.muted)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    statMetric("生命", value: classDefinition.initialStats.maxHealth, maximum: 36, tint: RiftPalette.success)
                    statMetric("攻击", value: classDefinition.initialStats.attack, maximum: 10, tint: RiftPalette.ember)
                    statMetric("防御", value: classDefinition.initialStats.defense, maximum: 8, tint: RiftPalette.riftBlue)
                    statMetric("闪避", value: classDefinition.initialStats.evasion, maximum: 8, tint: RiftPalette.riftViolet)
                    statMetric("魔法", value: classDefinition.initialStats.magic, maximum: 10, tint: Color(red: 0.44, green: 0.68, blue: 1.0))
                }

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(tint)
                    Text(viewModel.skillSummary(for: classDefinition))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RiftPalette.frost)
                        .lineLimit(2)
                    Spacer()
                    RiftStatusPill(text: "4 AP", tint: RiftPalette.ember)
                }
            }
            .padding(17)
            .frame(maxWidth: .infinity, minHeight: 286, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(selected ? 0.16 : 0.06), RiftPalette.panelRaised],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selected ? tint : RiftPalette.border.opacity(0.42), lineWidth: selected ? 2 : 1)
                    )
            )
            .shadow(color: selected ? tint.opacity(0.20) : .clear, radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.42 : 1)
        .riftHoverLift()
        .accessibilityLabel("\(classDefinition.displayName)，\(selected ? "已选择" : "未选择")，生命 \(classDefinition.initialStats.maxHealth)，攻击 \(classDefinition.initialStats.attack)，防御 \(classDefinition.initialStats.defense)，闪避 \(classDefinition.initialStats.evasion)，魔法 \(classDefinition.initialStats.magic)")
        .accessibilityHint("点击选择或取消选择该职业。")
    }

    private func statMetric(_ title: String, value: Int, maximum: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 3) {
                Text(title)
                Spacer(minLength: 2)
                Text("\(value)")
                    .monospacedDigit()
                    .foregroundStyle(RiftPalette.frost)
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(RiftPalette.muted)

            RiftMetricBar(value: Double(value) / Double(maximum), tint: tint, height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}
