import SwiftUI

struct InventoryView: View {
    let viewModel: InventoryViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            HStack(alignment: .top, spacing: 18) {
                partyPanel
                itemPanel
            }

            Text(viewModel.statusText)
                .font(.callout.bold())
                .foregroundStyle(Color(red: 0.84, green: 0.73, blue: 0.42))
        }
        .frame(maxWidth: 1040, alignment: .leading)
        .padding(28)
        .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 22))
        .padding(32)
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text("背包与角色")
                    .font(.system(size: 44, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                Text("队伍共享背包；职业不限制装备与后续成长。")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Button("返回探索", action: onClose)
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("返回探索")
        }
    }

    private var partyPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("队伍")
                .font(.headline)
                .foregroundStyle(.white)

            HStack {
                ForEach(viewModel.party) { actor in
                    Button(actor.displayName) {
                        viewModel.selectActor(id: actor.id)
                    }
                    .buttonStyle(.bordered)
                    .tint(viewModel.selectedActorID == actor.id ? Color.green : Color.gray)
                    .accessibilityLabel("查看角色 \(actor.displayName)")
                }
            }

            if let actor = viewModel.selectedActor {
                CharacterSheetView(viewModel: viewModel, actor: actor)
            } else {
                Text("没有可查看的角色。")
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: 460, alignment: .leading)
    }

    private var itemPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("共享背包")
                .font(.headline)
                .foregroundStyle(.white)

            if viewModel.inventoryRows.isEmpty {
                Text("背包为空。")
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                ForEach(viewModel.inventoryRows) { row in
                    itemRow(row)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }

    private func itemRow(_ row: InventoryItemRow) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.displayName)
                    .font(.callout.bold())
                    .foregroundStyle(.white)
                Text(row.slotName ?? "非装备")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()

            Text("数量 \(row.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.72))

            Button("装备") {
                viewModel.equip(itemID: row.id)
            }
            .disabled(row.slotName == nil)
            .accessibilityLabel("装备 \(row.displayName)")
        }
        .padding(10)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }
}
