import SwiftUI

struct DebugOverlayView: View {
    let viewModel: GameSessionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("调试")
                .font(.caption.weight(.bold))
                .foregroundStyle(RiftPalette.bannerRed)

            debugRow("状态", viewModel.appState.title)
            debugRow("最后坐标", lastClickText)
            debugRow("队伍人数", "\(viewModel.party.count)")
            debugRow("队长", viewModel.explorationController.leaderID ?? "无")
            debugRow("障碍", "\(viewModel.debugObstacleCount)")
            debugRow("遭遇触发器", "\(viewModel.debugEncounterTriggerCount)")
            debugRow("视线", "连续坐标检查")
        }
        .font(.caption.monospaced())
        .padding(12)
        .foregroundStyle(RiftPalette.textBrown)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RiftPalette.parchment.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(RiftPalette.outline.opacity(0.5), lineWidth: 1.5)
                )
        )
    }

    private var lastClickText: String {
        guard let point = viewModel.lastWorldClick else { return "无" }
        return "\(Int(point.x)), \(Int(point.y))"
    }

    private func debugRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(RiftPalette.textBrownLight)
            Spacer()
            Text(value)
        }
        .frame(width: 220, alignment: .leading)
    }
}
