import RiftCore
import SwiftUI

struct CharacterSheetView: View {
    let viewModel: InventoryViewModel
    let actor: Actor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(actor.displayName)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(RiftPalette.textBrown)

                Text("等级 \(actor.level) · 未分配属性点 \(actor.unspentAttributePoints)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RiftPalette.textBrownLight)
            }

            // 人形剪影 + 围绕在周围的武器/饰品装备格，用来代替之前纯文字列表式的装备行。
            HStack(alignment: .center, spacing: 6) {
                RiftEquipSlotView(
                    icon: RiftEquipmentIconography.icon(for: .weapon),
                    label: viewModel.slotName(.weapon),
                    itemName: viewModel.equippedItemName(for: actor, slot: .weapon)
                )

                Spacer(minLength: 4)

                RiftHumanoidSilhouette(tint: RiftClassIconography.tint(for: actor.classID))

                Spacer(minLength: 4)

                RiftEquipSlotView(
                    icon: RiftEquipmentIconography.icon(for: .accessory),
                    label: viewModel.slotName(.accessory),
                    itemName: viewModel.equippedItemName(for: actor, slot: .accessory)
                )
            }
            .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                RiftEquipSlotView(
                    icon: RiftEquipmentIconography.icon(for: .armor),
                    label: viewModel.slotName(.armor),
                    itemName: viewModel.equippedItemName(for: actor, slot: .armor)
                )
                Spacer()
            }

            Divider()
                .overlay(RiftPalette.outline.opacity(0.3))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                statRow("生命", "\(actor.stats.health)/\(actor.stats.maxHealth)", attribute: .maxHealth)
                statRow("攻击", "\(actor.stats.attack)", attribute: .attack)
                statRow("防御", "\(actor.stats.defense)", attribute: .defense)
                statRow("闪避", "\(actor.stats.evasion)", attribute: .evasion)
                statRow("魔法", "\(actor.stats.magic)", attribute: .magic)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(RiftPalette.parchmentShade)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(RiftPalette.outline, lineWidth: 2.5))
        )
    }

    private func statRow(_ title: String, _ value: String, attribute: Attribute) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .foregroundStyle(RiftPalette.textBrownLight)
            Spacer()
            Text(value)
                .monospacedDigit()
                .foregroundStyle(RiftPalette.bannerRed)
            Button {
                viewModel.allocate(attribute)
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(actor.unspentAttributePoints > 0 ? RiftPalette.accentGreenDark : RiftPalette.textBrownLight.opacity(0.35))
            .disabled(actor.unspentAttributePoints <= 0)
            .accessibilityLabel("提升\(title)")
        }
        .font(.callout.weight(.medium))
        .foregroundStyle(RiftPalette.textBrown)
    }
}
