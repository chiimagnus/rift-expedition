import RiftCore
import SwiftUI

struct SaveLoadView: View {
    let viewModel: SaveLoadViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            HStack(alignment: .top, spacing: 18) {
                slotColumn("手动存档", rows: viewModel.rows.filter { $0.slot.kind == .manual })
                slotColumn("自动存档", rows: viewModel.rows.filter { $0.slot.kind == .auto })
            }

            Text(viewModel.message)
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
                Text("存档")
                    .font(.system(size: 44, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                Text("5 个手动槽，5 个自动槽；自动存档只允许安全点写入。")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Button("返回", action: onClose)
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("返回探索")
        }
    }

    private func slotColumn(_ title: String, rows: [SaveSlotRow]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(rows) { row in
                slotRow(row)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }

    private func slotRow(_ row: SaveSlotRow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.title)
                        .font(.callout.bold())
                    Text(row.detail)
                        .font(.caption)
                        .foregroundStyle(row.isCorrupt ? Color.red.opacity(0.82) : Color.white.opacity(0.62))
                }

                Spacer()

                    if row.slot.kind == .manual {
                        Button("保存") {
                            viewModel.saveManual(slot: row.slot)
                        }
                        .accessibilityLabel("保存到\(row.title)")
                    }

                    Button("读取") {
                        viewModel.load(slot: row.slot)
                    }
                    .disabled(!row.canLoad)
                    .accessibilityLabel("读取\(row.title)")
                }
            }
            .foregroundStyle(.white)
            .padding(10)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }
}
