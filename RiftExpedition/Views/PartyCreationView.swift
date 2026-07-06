import RiftCore
import SwiftUI

struct PartyCreationView: View {
    let viewModel: PartyCreationViewModel
    let onConfirm: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
                ForEach(viewModel.availableClasses) { classDefinition in
                    classCard(classDefinition)
                }
            }

            HStack(spacing: 12) {
                Button("返回主菜单", action: onBack)
                    .accessibilityLabel("返回主菜单")

                Button("开始第一章", action: onConfirm)
                    .disabled(!viewModel.canStart)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityLabel("开始第一章")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: 980)
        .padding(36)
        .background(.black.opacity(0.38), in: RoundedRectangle(cornerRadius: 22))
        .padding(32)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选择两名冒险者")
                .font(.system(size: 44, weight: .black, design: .serif))
                .foregroundStyle(.white)

            Text("职业只决定初始属性、初始技能和默认装备；之后装备与技能不受职业限制。")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.72))

            Text("已选择 \(viewModel.selectedClassIDs.count)/2")
                .font(.callout.bold())
                .foregroundStyle(.white.opacity(0.66))
        }
    }

    private func classCard(_ classDefinition: ClassDefinition) -> some View {
        let selected = viewModel.isSelected(classDefinition.id)

        return Button {
            viewModel.toggleSelection(classDefinition.id)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(classDefinition.displayName)
                        .font(.title2.bold())
                    Spacer()
                    Text(selected ? "已选" : "可选")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(selected ? Color.green.opacity(0.28) : Color.white.opacity(0.12), in: Capsule())
                }

                statRow("生命", classDefinition.initialStats.maxHealth)
                statRow("攻击", classDefinition.initialStats.attack)
                statRow("防御", classDefinition.initialStats.defense)
                statRow("闪避", classDefinition.initialStats.evasion)
                statRow("魔法", classDefinition.initialStats.magic)

                Text("初始技能：\(viewModel.skillSummary(for: classDefinition))")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.62))
            }
            .foregroundStyle(.white)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Color(red: 0.31, green: 0.42, blue: 0.26).opacity(0.85) : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(selected ? Color(red: 0.84, green: 0.73, blue: 0.42) : Color.white.opacity(0.16), lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!selected && viewModel.selectedClassIDs.count >= 2)
        .accessibilityLabel("\(classDefinition.displayName)，\(selected ? "已选择" : "未选择")，生命 \(classDefinition.initialStats.maxHealth)，攻击 \(classDefinition.initialStats.attack)，防御 \(classDefinition.initialStats.defense)，闪避 \(classDefinition.initialStats.evasion)，魔法 \(classDefinition.initialStats.magic)")
        .accessibilityHint("点击选择或取消该职业。")
    }

    private func statRow(_ title: String, _ value: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)")
                .monospacedDigit()
        }
        .font(.callout)
        .foregroundStyle(.white.opacity(0.82))
    }
}
