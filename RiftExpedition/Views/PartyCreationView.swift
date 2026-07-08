import RiftCore
import SwiftUI

struct PartyCreationView: View {
    let viewModel: PartyCreationViewModel
    let onConfirm: () -> Void
    let onBack: () -> Void

    var body: some View {
        RiftPanelScaffold(
            title: "选择两名冒险者",
            subtitle: "职业只决定初始属性、初始技能和默认装备；之后装备与技能不受职业限制。\n已选择 \(viewModel.selectedClassIDs.count)/2",
            maxWidth: 940
        ) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 16)], spacing: 16) {
                ForEach(viewModel.availableClasses) { classDefinition in
                    classCard(classDefinition)
                }
            }

            HStack(spacing: 12) {
                Button("返回主菜单", action: onBack)
                    .buttonStyle(RiftPrimaryButtonStyle())
                    .accessibilityLabel("返回主菜单")

                Button("开始第一章", action: onConfirm)
                    .buttonStyle(RiftPrimaryButtonStyle())
                    .disabled(!viewModel.canStart)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityLabel("开始第一章")
            }
        }
    }

    private func classCard(_ classDefinition: ClassDefinition) -> some View {
        let selected = viewModel.isSelected(classDefinition.id)

        return Button {
            viewModel.toggleSelection(classDefinition.id)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    RiftActorPortrait(classID: classDefinition.id, size: 60)

                    Spacer()

                    Text(selected ? "已选" : "可选")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(selected ? RiftPalette.accentGreenDark : RiftPalette.textBrownLight, in: Capsule())
                }

                Text(classDefinition.displayName)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(RiftPalette.textBrown)

                VStack(alignment: .leading, spacing: 4) {
                    statRow("生命", classDefinition.initialStats.maxHealth)
                    statRow("攻击", classDefinition.initialStats.attack)
                    statRow("防御", classDefinition.initialStats.defense)
                    statRow("闪避", classDefinition.initialStats.evasion)
                    statRow("魔法", classDefinition.initialStats.magic)
                }

                Divider()
                    .overlay(RiftPalette.outline.opacity(0.3))

                Text("初始技能：\(viewModel.skillSummary(for: classDefinition))")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(RiftPalette.textBrownLight)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(RiftPalette.parchmentShade)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selected ? RiftPalette.bannerRed : RiftPalette.outline, lineWidth: selected ? 3 : 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!selected && viewModel.selectedClassIDs.count >= 2)
        .accessibilityLabel("\(classDefinition.displayName)，\(selected ? "已选择" : "未选择")，生命 \(classDefinition.initialStats.maxHealth)，攻击 \(classDefinition.initialStats.attack)，防御 \(classDefinition.initialStats.defense)，闪避 \(classDefinition.initialStats.evasion)，魔法 \(classDefinition.initialStats.magic)")
        .accessibilityHint("点击选择或取消选择该职业。")
    }

    private func statRow(_ title: String, _ value: Int) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(RiftPalette.textBrownLight)
            Spacer()
            Text("\(value)")
                .monospacedDigit()
                .foregroundStyle(RiftPalette.bannerRed)
        }
        .font(.callout.weight(.medium))
    }
}
