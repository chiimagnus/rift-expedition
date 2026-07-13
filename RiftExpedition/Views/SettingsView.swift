import SwiftUI

struct SettingsView: View {
    let viewModel: GameSessionViewModel
    let onClose: () -> Void

    var body: some View {
        RiftPanelScaffold(
            title: "系统与无障碍",
            subtitle: "调整音频、界面尺寸和辅助显示。设置会立即生效。",
            closeLabel: "返回",
            onClose: onClose,
            maxWidth: 900
        ) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    RiftSectionHeader("声音与沉浸", eyebrow: "AUDIO", systemImage: "speaker.wave.3.fill")

                    settingCard(
                        icon: viewModel.audioService.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                        title: "全局音频",
                        detail: viewModel.audioService.isMuted ? "当前已静音" : "环境、战斗与界面提示音已启用",
                        tint: viewModel.audioService.isMuted ? RiftPalette.danger : RiftPalette.success
                    ) {
                        Toggle("静音", isOn: Binding(
                            get: { viewModel.audioService.isMuted },
                            set: { viewModel.audioService.isMuted = $0 }
                        ))
                        .labelsHidden()
                        .tint(RiftPalette.success)
                        .accessibilityLabel("静音开关")
                    }

                    sliderCard(
                        icon: "dial.high.fill",
                        title: "主音量",
                        detail: "控制所有声音通道的最终输出强度",
                        value: Binding(
                            get: { viewModel.audioService.masterVolume },
                            set: { viewModel.audioService.masterVolume = $0 }
                        ),
                        range: 0...1,
                        displayValue: "\(Int(viewModel.audioService.masterVolume * 100))%",
                        tint: RiftPalette.riftBlue
                    )

                    sliderCard(
                        icon: "music.note.list",
                        title: "音乐层",
                        detail: "控制探索 / 战斗的基础音乐与动态叠层",
                        value: Binding(
                            get: { viewModel.audioService.musicVolume },
                            set: { viewModel.audioService.musicVolume = $0 }
                        ),
                        range: 0...1,
                        displayValue: "\(Int(viewModel.audioService.musicVolume * 100))%",
                        tint: RiftPalette.riftViolet
                    )

                    sliderCard(
                        icon: "wind",
                        title: "环境层",
                        detail: "控制河流、风声、洞窟滴水等氛围循环",
                        value: Binding(
                            get: { viewModel.audioService.ambienceVolume },
                            set: { viewModel.audioService.ambienceVolume = $0 }
                        ),
                        range: 0...1,
                        displayValue: "\(Int(viewModel.audioService.ambienceVolume * 100))%",
                        tint: RiftPalette.success
                    )

                    sliderCard(
                        icon: "sparkles",
                        title: "战斗 / 反馈音效",
                        detail: "控制命中、施法、任务完成与章节提示音",
                        value: Binding(
                            get: { viewModel.audioService.sfxVolume },
                            set: { viewModel.audioService.sfxVolume = $0 }
                        ),
                        range: 0...1,
                        displayValue: "\(Int(viewModel.audioService.sfxVolume * 100))%",
                        tint: RiftPalette.ember
                    )

                    RiftSectionHeader("界面与辅助", eyebrow: "ACCESSIBILITY", systemImage: "accessibility.fill")

                    sliderCard(
                        icon: "rectangle.expand.vertical",
                        title: "界面缩放",
                        detail: "放大战术 HUD、文字和交互控件",
                        value: Binding(
                            get: { viewModel.uiScale },
                            set: { viewModel.uiScale = $0 }
                        ),
                        range: 0.85...1.15,
                        displayValue: "\(Int(viewModel.uiScale * 100))%",
                        tint: RiftPalette.riftViolet
                    )

                    settingCard(
                        icon: "waveform.path.ecg.rectangle.fill",
                        title: "调试叠层",
                        detail: "显示坐标、区域触发器和运行时状态；仅用于开发验收",
                        tint: RiftPalette.ember
                    ) {
                        Toggle("显示", isOn: Binding(
                            get: { viewModel.isDebugOverlayVisible },
                            set: { viewModel.isDebugOverlayVisible = $0 }
                        ))
                        .labelsHidden()
                        .tint(RiftPalette.ember)
                        .accessibilityLabel("显示调试叠层")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                keyBindingList
                    .frame(width: 310)
            }
        }
    }

    private func settingCard<Accessory: View>(
        icon: String,
        title: String,
        detail: String,
        tint: Color,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack(spacing: 13) {
            settingIcon(icon, tint: tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(RiftPalette.frost)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(RiftPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            accessory()
        }
        .padding(14)
        .background(RiftPalette.void.opacity(0.38), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(tint.opacity(0.24), lineWidth: 1))
    }

    private func sliderCard(
        icon: String,
        title: String,
        detail: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        displayValue: String,
        tint: Color
    ) -> some View {
        VStack(spacing: 11) {
            HStack(spacing: 13) {
                settingIcon(icon, tint: tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(RiftPalette.frost)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(RiftPalette.muted)
                }
                Spacer()
                RiftStatusPill(text: displayValue, tint: tint)
            }
            Slider(value: value, in: range)
                .tint(tint)
                .accessibilityLabel(title)
        }
        .padding(14)
        .background(RiftPalette.void.opacity(0.38), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(tint.opacity(0.24), lineWidth: 1))
    }

    private func settingIcon(_ name: String, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(tint.opacity(0.13))
            Image(systemName: name)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
        }
        .frame(width: 42, height: 42)
    }

    private var keyBindingList: some View {
        VStack(alignment: .leading, spacing: 13) {
            RiftSectionHeader("操作速查", eyebrow: "CONTROLS", systemImage: "keyboard.fill")

            keyRow("LMB", "移动队长 / 选择目标", icon: "cursorarrow.click.2")
            keyRow("TAB", "切换探索队长", icon: "person.2.gobackward")
            keyRow("ENTER", "推进对话 / 确认", icon: "arrow.turn.down.left")
            keyRow("ESC", "关闭当前面板", icon: "xmark")
            keyRow("D", "显示调试叠层", icon: "ladybug.fill")

            Rectangle()
                .fill(RiftPalette.border.opacity(0.28))
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 7) {
                Label("可读性原则", systemImage: "eye.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(RiftPalette.riftBlue)
                Text("关键状态同时使用文字、图标和颜色表达；无需依赖单一颜色判断战斗信息。")
                    .font(.caption)
                    .foregroundStyle(RiftPalette.muted)
                    .lineSpacing(3)
            }
        }
        .padding(17)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(LinearGradient(colors: [RiftPalette.riftBlue.opacity(0.07), RiftPalette.panelRaised], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(RiftPalette.riftBlue.opacity(0.28), lineWidth: 1))
        )
    }

    private func keyRow(_ key: String, _ description: String, icon: String) -> some View {
        HStack(spacing: 9) {
            RiftKeycap(text: key)
                .frame(width: 54)
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(RiftPalette.riftViolet)
                .frame(width: 19)
            Text(description)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RiftPalette.frost)
            Spacer()
        }
    }
}
