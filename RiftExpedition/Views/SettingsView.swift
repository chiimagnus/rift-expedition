import SwiftUI

struct SettingsView: View {
    let viewModel: GameSessionViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            VStack(alignment: .leading, spacing: 14) {
                Toggle("静音", isOn: Binding(
                    get: { viewModel.audioService.isMuted },
                    set: { viewModel.audioService.isMuted = $0 }
                ))

                HStack {
                    Text("主音量")
                    Slider(value: Binding(
                        get: { viewModel.audioService.masterVolume },
                        set: { viewModel.audioService.masterVolume = $0 }
                    ), in: 0...1)
                    Text(viewModel.audioService.masterVolume, format: .number.precision(.fractionLength(2)))
                        .monospacedDigit()
                }

                HStack {
                    Text("UI 缩放")
                    Slider(value: Binding(
                        get: { viewModel.uiScale },
                        set: { viewModel.uiScale = $0 }
                    ), in: 0.85...1.15)
                    Text(viewModel.uiScale, format: .number.precision(.fractionLength(2)))
                        .monospacedDigit()
                }
            }
            .foregroundStyle(.white)

            keyBindingList

            Toggle("显示调试叠层", isOn: Binding(
                get: { viewModel.isDebugOverlayVisible },
                set: { viewModel.isDebugOverlayVisible = $0 }
            ))
            .foregroundStyle(.white)
        }
        .frame(maxWidth: 760, alignment: .leading)
        .padding(36)
        .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 22))
        .padding(32)
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text("设置")
                    .font(.system(size: 44, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                Text("音频、键位说明与调试显示。")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Button("返回", action: onClose)
                .buttonStyle(.borderedProminent)
        }
    }

    private var keyBindingList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("键位")
                .font(.headline)
                .foregroundStyle(.white)

            keyRow("鼠标左键", "移动队长 / 选择地图点")
            keyRow("Tab", "切换队长")
            keyRow("D", "显示或隐藏调试叠层")
        }
        .padding(16)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private func keyRow(_ key: String, _ description: String) -> some View {
        HStack {
            Text(key)
                .font(.callout.bold())
                .frame(width: 96, alignment: .leading)
            Text(description)
                .foregroundStyle(.white.opacity(0.72))
        }
        .foregroundStyle(.white)
    }
}
