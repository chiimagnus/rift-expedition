import SwiftUI

struct DebugOverlayView: View {
    let viewModel: GameSessionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DEBUG")
                .font(.caption.bold())
                .foregroundStyle(Color(red: 0.84, green: 0.73, blue: 0.42))

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
        .foregroundStyle(.white)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    private var lastClickText: String {
        guard let point = viewModel.lastWorldClick else { return "无" }
        return "\(Int(point.x)), \(Int(point.y))"
    }

    private func debugRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.white.opacity(0.62))
            Spacer()
            Text(value)
        }
        .frame(width: 220, alignment: .leading)
    }
}
