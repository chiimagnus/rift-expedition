import SwiftUI

struct SettingsView: View {
    let viewModel: GameSessionViewModel
    let onClose: () -> Void

    var body: some View {
        RiftPanelScaffold(
            title: "设置",
            subtitle: "音频、键位说明与调试显示。",
            closeLabel: "返回",
            onClose: onClose
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Toggle("静音", isOn: Binding(
                    get: { viewModel.audioService.isMuted },
                    set: { viewModel.audioService.isMuted = $0 }
                ))
                .tint(RiftPalette.accentGreen)
                .accessibilityLabel("静音开关")

                HStack {
                    Text("主音量")
                    Slider(value: Binding(
                        get: { viewModel.audioService.masterVolume },
                        set: { viewModel.audioService.masterVolume = $0 }
                    ), in: 0...1)
                    .tint(RiftPalette.bannerRed)
                    .accessibilityLabel("主音量")
                    Text(viewModel.audioService.masterVolume, format: .number.precision(.fractionLength(2)))
                        .monospacedDigit()
                }

                HStack {
                    Text("界面缩放")
                    Slider(value: Binding(
                        get: { viewModel.uiScale },
                        set: { viewModel.uiScale = $0 }
                    ), in: 0.85...1.15)
                    .tint(RiftPalette.bannerRed)
                    .accessibilityLabel("界面缩放")
                    Text(viewModel.uiScale, format: .number.precision(.fractionLength(2)))
                        .monospacedDigit()
                }
            }
            .foregroundStyle(RiftPalette.textBrown)

            keyBindingList

            Toggle("显示调试叠层", isOn: Binding(
                get: { viewModel.isDebugOverlayVisible },
                set: { viewModel.isDebugOverlayVisible = $0 }
            ))
            .tint(RiftPalette.accentGreen)
            .foregroundStyle(RiftPalette.textBrown)
            .accessibilityLabel("显示调试叠层")
        }
    }

    private var keyBindingList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("键位")
                .font(.headline)
                .foregroundStyle(RiftPalette.textBrown)

            keyRow("鼠标左键", "移动队长 / 选择地图点")
            keyRow("Tab", "切换队长")
            keyRow("D", "显示或隐藏调试叠层")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RiftPalette.parchmentShade)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(RiftPalette.outline.opacity(0.6), lineWidth: 1.5))
        )
    }

    private func keyRow(_ key: String, _ description: String) -> some View {
        HStack {
            Text(key)
                .font(.callout.bold())
                .frame(width: 96, alignment: .leading)
            Text(description)
                .foregroundStyle(RiftPalette.textBrownLight)
        }
        .foregroundStyle(RiftPalette.textBrown)
    }
}
