import RiftCore
import SwiftUI

struct CharacterSheetView: View {
    let viewModel: InventoryViewModel
    let actor: Actor

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                RiftActorPortrait(classID: actor.classID, size: 88, isActive: true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(actor.displayName)
                        .font(.title2.weight(.black))
                        .foregroundStyle(RiftPalette.frost)
                    Text(classRole)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RiftClassIconography.tint(for: actor.classID))
                    HStack(spacing: 6) {
                        RiftStatusPill(text: "Lv.\(actor.level)", tint: RiftPalette.riftBlue)
                        RiftStatusPill(text: "\(actor.unspentAttributePoints) 属性点", tint: actor.unspentAttributePoints > 0 ? RiftPalette.ember : RiftPalette.steel)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("生命状态")
                    Spacer()
                    Text("\(actor.stats.health) / \(actor.stats.maxHealth)")
                        .monospacedDigit()
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(RiftPalette.textBrownLight)
                RiftMetricBar(
                    value: actor.stats.maxHealth == 0 ? 0 : Double(actor.stats.health) / Double(actor.stats.maxHealth),
                    tint: healthTint,
                    height: 7
                )
            }

            RiftSectionHeader("当前装备", eyebrow: "LOADOUT", systemImage: "shield.lefthalf.filled")

            HStack(alignment: .top, spacing: 10) {
                RiftEquipSlotView(
                    icon: RiftEquipmentIconography.icon(for: .weapon),
                    label: viewModel.slotName(.weapon),
                    itemName: viewModel.equippedItemName(for: actor, slot: .weapon)
                )
                Spacer(minLength: 2)
                RiftEquipSlotView(
                    icon: RiftEquipmentIconography.icon(for: .armor),
                    label: viewModel.slotName(.armor),
                    itemName: viewModel.equippedItemName(for: actor, slot: .armor)
                )
                Spacer(minLength: 2)
                RiftEquipSlotView(
                    icon: RiftEquipmentIconography.icon(for: .accessory),
                    label: viewModel.slotName(.accessory),
                    itemName: viewModel.equippedItemName(for: actor, slot: .accessory)
                )
            }
            .frame(maxWidth: .infinity)

            RiftSectionHeader("战斗属性", eyebrow: "COMBAT STATS", systemImage: "chart.bar.fill")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                statCard("生命", value: actor.stats.maxHealth, icon: "heart.fill", tint: RiftPalette.success, attribute: .maxHealth)
                statCard("攻击", value: actor.stats.attack, icon: "burst.fill", tint: RiftPalette.ember, attribute: .attack)
                statCard("防御", value: actor.stats.defense, icon: "shield.fill", tint: RiftPalette.riftBlue, attribute: .defense)
                statCard("闪避", value: actor.stats.evasion, icon: "wind", tint: RiftPalette.riftViolet, attribute: .evasion)
                statCard("魔法", value: actor.stats.magic, icon: "sparkles", tint: Color(red: 0.42, green: 0.67, blue: 1.0), attribute: .magic)
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(RiftPalette.ember)
                        Text("行动点")
                            .foregroundStyle(RiftPalette.textBrownLight)
                        Spacer()
                    }
                    Text("\(actor.stats.maxActionPoints) AP")
                        .font(.headline.monospacedDigit().weight(.black))
                        .foregroundStyle(RiftPalette.textBrown)
                }
                .padding(10)
                .background(RiftPalette.void.opacity(0.38), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [RiftClassIconography.tint(for: actor.classID).opacity(0.09), RiftPalette.parchmentShade],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(RiftClassIconography.tint(for: actor.classID).opacity(0.38), lineWidth: 1.2)
                )
        )
    }

    private func statCard(_ title: String, value: Int, icon: String, tint: Color, attribute: Attribute) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(RiftPalette.textBrownLight)
                Text("\(value)")
                    .font(.headline.monospacedDigit().weight(.black))
                    .foregroundStyle(RiftPalette.textBrown)
            }
            Spacer()
            Button {
                viewModel.allocate(attribute)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16, weight: .bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(actor.unspentAttributePoints > 0 ? tint : RiftPalette.textBrownLight.opacity(0.25))
            .disabled(actor.unspentAttributePoints <= 0)
            .accessibilityLabel("提升\(title)")
        }
        .padding(10)
        .background(RiftPalette.void.opacity(0.38), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(tint.opacity(0.18), lineWidth: 1))
    }

    private var classRole: String {
        switch actor.classID {
        case "warrior": "边境守誓者 · 前排控制"
        case "archer": "灰羽游猎者 · 远程压制"
        case "mage": "裂光研习者 · 元素支援"
        case "rogue": "夜痕追猎者 · 高机动爆发"
        default: "远征者"
        }
    }

    private var healthTint: Color {
        guard actor.stats.maxHealth > 0 else { return RiftPalette.danger }
        let ratio = Double(actor.stats.health) / Double(actor.stats.maxHealth)
        if ratio < 0.3 { return RiftPalette.danger }
        if ratio < 0.6 { return RiftPalette.ember }
        return RiftPalette.success
    }
}
