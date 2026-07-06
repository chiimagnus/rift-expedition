import SwiftUI

struct DialogView: View {
    let viewModel: DialogViewModel
    let onClose: () -> Void
    let onCompleteQuest: (String) -> Void
    let onStartBattle: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let dialog = viewModel.activeDialog {
                Text(dialog.speakerName)
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                ForEach(dialog.lines, id: \.self) { line in
                    Text(line)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.82))
                }

                if !viewModel.message.isEmpty {
                    Text(viewModel.message)
                        .font(.callout.bold())
                        .foregroundStyle(Color(red: 0.84, green: 0.73, blue: 0.42))
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
                        .accessibilityLabel("对话选项：\(option.title)")
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text(viewModel.message)
                    .foregroundStyle(.white)
                Button("返回") {
                    onClose()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("返回探索")
            }
        }
        .frame(maxWidth: 760, alignment: .leading)
        .padding(36)
        .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 22))
        .padding(32)
    }
}
