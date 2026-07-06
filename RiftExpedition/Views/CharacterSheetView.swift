import RiftCore
import SwiftUI

struct CharacterSheetView: View {
    let viewModel: InventoryViewModel
    let actor: Actor

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(actor.displayName)
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("等级 \(actor.level) · 未分配属性点 \(actor.unspentAttributePoints)")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.68))

            VStack(alignment: .leading, spacing: 8) {
                statRow("生命值", "\(actor.stats.health)/\(actor.stats.maxHealth)", attribute: .maxHealth)
                statRow("攻击值", "\(actor.stats.attack)", attribute: .attack)
                statRow("防御值", "\(actor.stats.defense)", attribute: .defense)
                statRow("闪避值", "\(actor.stats.evasion)", attribute: .evasion)
                statRow("魔法值", "\(actor.stats.magic)", attribute: .magic)
            }

            Divider()
                .overlay(.white.opacity(0.18))

            VStack(alignment: .leading, spacing: 8) {
                equipmentRow(.weapon)
                equipmentRow(.armor)
                equipmentRow(.accessory)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }

    private func statRow(_ title: String, _ value: String, attribute: Attribute) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .monospacedDigit()
            Button("+") {
                viewModel.allocate(attribute)
            }
            .disabled(actor.unspentAttributePoints <= 0)
            .accessibilityLabel("提升\(title)")
        }
        .font(.callout)
        .foregroundStyle(.white.opacity(0.82))
    }

    private func equipmentRow(_ slot: EquipmentSlot) -> some View {
        HStack {
            Text(viewModel.slotName(slot))
            Spacer()
            Text(viewModel.equippedItemName(for: actor, slot: slot))
                .foregroundStyle(.white.opacity(0.72))
        }
        .font(.callout)
        .foregroundStyle(.white)
    }
}
