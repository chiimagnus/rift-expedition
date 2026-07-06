import SwiftUI

struct DialogView: View {
    let viewModel: DialogViewModel
    let onClose: () -> Void
    let onCompleteQuest: (String) -> Void
    let onStartBattle: (String) -> Void

    var body: some View {
        RiftPanelScaffold(
            title: viewModel.activeDialog?.speakerName ?? "对话",
            onClose: viewModel.activeDialog == nil ? onClose : nil,
            maxWidth: 760
        ) {
            if let dialog = viewModel.activeDialog {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(dialog.lines, id: \.self) { line in
                        Text(line)
                            .font(.title3)
                            .foregroundStyle(RiftPalette.textBrown.opacity(0.88))
                    }

                    if !viewModel.message.isEmpty {
                        Text(viewModel.message)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(RiftPalette.bannerRed)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(dialog.options) { option in
                            Button(option.title) {
                                switch viewModel.choose(option) {
                                case .none:
                                    break
                                case .close:
                                    onClose()
                                case let .completedQuest(questID):
                                    onCompleteQuest(questID)
                                case let .startBattle(encounterID):
                                    onStartBattle(encounterID)
                                }
                            }
                            .buttonStyle(RiftDialogOptionButtonStyle())
                            .accessibilityLabel("对话选项：\(option.title)")
                        }
                    }
                }
            } else {
                Text(viewModel.message)
                    .foregroundStyle(RiftPalette.textBrown)
            }
        }
    }
}
