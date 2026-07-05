import RiftCore
import SwiftUI

struct QuestLogView: View {
    let entries: [QuestLogEntry]
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("任务日志")
                .font(.system(size: 40, weight: .black, design: .serif))
                .foregroundStyle(.white)

            if entries.isEmpty {
                Text("当前没有已接任务。")
                    .foregroundStyle(.white.opacity(0.72))
            } else {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.title)
                            .font(.title3.bold())
                        Text(entry.objective)
                            .foregroundStyle(.white.opacity(0.72))
                        Text(entry.status == .completed ? "已完成" : "进行中")
                            .font(.caption.bold())
                            .foregroundStyle(entry.status == .completed ? .green : Color(red: 0.84, green: 0.73, blue: 0.42))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                }
            }

            Button("返回") {
                onClose()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: 760, alignment: .leading)
        .padding(36)
        .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 22))
        .padding(32)
    }
}
