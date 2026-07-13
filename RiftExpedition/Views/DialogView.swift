import SwiftUI

struct DialogView: View {
    let viewModel: DialogViewModel
    let onClose: () -> Void
    let onQuestCompletionRequested: (String) -> Void
    let onStartBattle: (String) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.48)
                .ignoresSafeArea()
                .onTapGesture { }

            if let dialog = viewModel.activeDialog {
                CinematicDialogContent(
                    dialog: dialog,
                    message: viewModel.message,
                    onChoose: handleOption
                )
                .id(dialog.id)
                .padding(.horizontal, 44)
                .padding(.bottom, 32)
            } else {
                VStack(spacing: 14) {
                    RiftLogoMark(size: 58)
                    Text(viewModel.message)
                        .foregroundStyle(RiftPalette.frost)
                    Button("返回探索", action: onClose)
                        .buttonStyle(RiftPrimaryButtonStyle())
                }
                .padding(30)
                .riftParchmentPanel(cornerRadius: 20)
                .padding(.bottom, 32)
            }
        }
    }

    private func handleOption(_ option: DialogOptionDefinition) {
        switch viewModel.choose(option) {
        case .none:
            break
        case .close:
            onClose()
        case let .questCompletionRequested(questID):
            onQuestCompletionRequested(questID)
        case let .startBattle(encounterID):
            onStartBattle(encounterID)
        }
    }
}

private struct CinematicDialogContent: View {
    let dialog: DialogDefinition
    let message: String
    let onChoose: (DialogOptionDefinition) -> Void

    @State private var lineIndex = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 18) {
            speakerPortrait

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(speakerCategory.uppercased())
                            .font(.caption2.weight(.black))
                            .tracking(1.5)
                            .foregroundStyle(speakerTint)
                        Text(dialog.speakerName)
                            .font(.title2.weight(.black))
                            .foregroundStyle(RiftPalette.frost)
                    }

                    Spacer()

                    Text("\(min(lineIndex + 1, max(dialog.lines.count, 1))) / \(max(dialog.lines.count, 1))")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(RiftPalette.muted)
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 12)

                Rectangle()
                    .fill(LinearGradient(colors: [speakerTint.opacity(0.7), RiftPalette.border.opacity(0.25), .clear], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: 16) {
                    Text(currentLine)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(RiftPalette.frost)
                        .lineSpacing(7)
                        .fixedSize(horizontal: false, vertical: true)
                        .id(lineIndex)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))

                    if !message.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                            Text(message)
                        }
                        .font(.callout.weight(.bold))
                        .foregroundStyle(RiftPalette.success)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(RiftPalette.success.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    if hasMoreLines {
                        HStack {
                            Spacer()
                            Button {
                                withAnimation(.easeOut(duration: 0.22)) {
                                    lineIndex += 1
                                }
                            } label: {
                                HStack(spacing: 9) {
                                    Text("继续")
                                    RiftKeycap(text: "ENTER")
                                }
                            }
                            .buttonStyle(RiftSecondaryButtonStyle())
                            .keyboardShortcut(.defaultAction)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(dialog.options) { option in
                                Button(option.title) {
                                    onChoose(option)
                                }
                                .buttonStyle(RiftDialogOptionButtonStyle())
                                .accessibilityLabel("对话选项：\(option.title)")
                            }
                        }
                    }
                }
                .padding(22)
            }
            .frame(maxWidth: 840, alignment: .leading)
            .riftParchmentPanel(cornerRadius: 18)
        }
        .frame(maxWidth: 1_060, alignment: .center)
    }

    private var currentLine: String {
        guard dialog.lines.indices.contains(lineIndex) else { return "……" }
        return dialog.lines[lineIndex]
    }

    private var hasMoreLines: Bool {
        lineIndex < dialog.lines.count - 1
    }

    @ViewBuilder
    private var speakerPortrait: some View {
        if let visualID = speakerVisualID {
            VStack(spacing: 8) {
                RiftVisualPortrait(visualID: visualID, size: 118, tint: speakerTint)
                RiftStatusPill(text: speakerCategory, tint: speakerTint)
            }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: [speakerTint.opacity(0.24), RiftPalette.obsidian], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(speakerTint.opacity(0.7), lineWidth: 1.4))
                Image(systemName: environmentIcon)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(speakerTint)
            }
            .frame(width: 118, height: 118)
            .shadow(color: speakerTint.opacity(0.25), radius: 12)
        }
    }

    private var speakerVisualID: String? {
        if dialog.speakerName.contains("顾怀恩") { return "npc_mayor" }
        if dialog.speakerName.contains("梁铮") { return "npc_fiance" }
        if dialog.speakerName.contains("阿砾") { return "npc_gate_guard" }
        if dialog.speakerName.contains("林婆") { return "npc_healer" }
        if dialog.speakerName.contains("沈砚") { return "actor_mage" }
        return nil
    }

    private var speakerCategory: String {
        if speakerVisualID != nil { return "角色对话" }
        if dialog.speakerName.contains("账册") { return "关键证据" }
        if dialog.speakerName.contains("洞心") { return "环境回响" }
        return "调查线索"
    }

    private var speakerTint: Color {
        if dialog.speakerName.contains("沈砚") { return RiftPalette.riftBlue }
        if dialog.speakerName.contains("顾怀恩") { return RiftPalette.ember }
        if dialog.speakerName.contains("账册") { return RiftPalette.danger }
        if speakerVisualID == nil { return RiftPalette.riftViolet }
        return RiftPalette.success
    }

    private var environmentIcon: String {
        if dialog.speakerName.contains("账册") { return "book.closed.fill" }
        if dialog.speakerName.contains("木牌") || dialog.speakerName.contains("公告板") { return "signpost.right.fill" }
        if dialog.speakerName.contains("洞") { return "mountain.2.fill" }
        return "magnifyingglass"
    }
}
